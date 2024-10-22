#include(libgame)
#include(libtic80)
0 { T }
0 { SCORE }
: sway { p m -- s } T p div math.sin(*\*) m * ;
: cell-mid ( x y -- x' y' ) [ 8 * 4 + ] 8 * 4 + ;
: pt! (***\) pix(***) ;

: sc-to-m (**\**) 8 div-xy ;
: center-to-tl ( x y -- t l ) 120 68 2 *xy -xy ;

: sxy-mid ( x y -- id ) [ 8 div ] 8 div mget(**\*) ;
: sxy-solid? ( x y -- ? ) sxy-mid 0 fget(**\*) ;
: solid-around? { x y -- ? } 
: s? (**\*) sxy-solid? ;
x y -1 +y s? 
x y 1 +y s? and
x y 1 +x s? and
x y -1 +x s? and ;

0 1 2 3 { no-f f-h f-v f-hv }
0 1 2 3 { no-r r-90 r-180 r-270 }
: *frame* ( id f r d -- fr ) t[ >>d >>r >>f >>id ] ;
: flipped { id f -- * } id f-h no-r f *frame* ;
: frame { id f -- * } id no-f no-r f *frame* ;

t[ ::anim
:: new ( t -- anim ) t[ >>frames 0 >>t 1 >>f ] ;
:: frame ( # -- fr ) f>> frames>> get ;
:: draw { # x y flip -- } anim.frame [ id>> x y 0 1 flip r>> spr(*******) ]. ;
:: next-frame ( # -- ) f>> 1 + >>f f>> frames>> len > if 1 >>f then ;
:: tic ( # -- ) anim.frame .d t>> < if 0 >>t anim.next-frame then ++t ; ].

: filter { # pred -- } it { coll } coll len 1 -1 +do [ it coll get pred(*\*) not if coll it table.remove(**) then ]. loop ;


\ A sprite is 32 bytes, or 64 nibbles
\ Sprite IDs start 0x4000 bytes or 0x8000 nibbles
: splat { x y id -- s }  t[ ::it x y to-pos 1 >>t
    0x8000 id 64 * + { addr } 63 0 do addr + peek4(*\*) , loop 
:: alive ( # -- ? ) it len pos? ;
:: tic ( # -- )  
    it len pos? if
        7 0 do { y } 7 0 do { x }
            x 1 + y 8 * + { idx } 
            idx it get { c }
            c if pos x y -4 -4 +xy t>> *xy +xy c pt! then
        loop loop
        it 32 dX @nil put
        it 32 dX 32 + @nil put
        t>> 0.08 + >>t
    then
; ] ;
    
t[ ::mobs t[ ] >>enemies t[ ] >>spawns 

:: balloon ( x y -- b ) t[ ::me to-pos  
 t[ t[ 267 24 frame , 283 24 frame , ] anim.new >>move ] >>anims
 true >>live
 @mobs.spawns tpick >>target
 :: tic ( # -- ) it { me }
  target pos dist 2 < if @mobs.spawns tpick >>target then
  target pos -xy /flip-xy norm 0.5 *xy mov
  anims>> .move [ anim.tic me [ pos 3 4 -xy flipspr ]. anim.draw ]. ;
 :: alive ( # -- ? ) live>> ;
 :: hurt ( # -- ) false >>live ; ] ;

:: add ( # m -- ) enemies>> [ , ]. ;
:: spawner ( x y -- ) @mobs.spawns [ <xy> , ].  ;
:: tic ( -- ) @mobs [
    T 60 mod? 4 dX 3 <= and if 
        3 dX 1 - 1 do drop spawns>> tpick [ pos ]. mobs.balloon mobs.add loop
    then
    enemies>> each :tic() for
    enemies>> [ : (*\*) :alive(\*) ; filter ].
]. ;
]

t[ ::bullets 
:: spawn ( x y dx dy -- ) bullets [ t[ >>dy >>dx to-pos 1 >>t ] , ]. ;
:: hurt ( # -- ) 121 >>t ;
:: alive ( # -- ? ) t>> 120 < ;
:: tic (\)
    bullets each [ dx>> 3 * dy>> mov ++t ]. for 
    @mobs.enemies each { m } bullets each { b }
        m .hurt m b o-dist 4 < b [ bullets.alive ]. and and if 
            m :hurt() b [ bullets.hurt ]. 
            m [ pos ]. 283 splat @mobs [ mobs.add ]. 1 += SCORE
            0 "C#2" 15 0 sfx(****) 
        then
    for for
    bullets [ : (*\*) [ bullets.alive ]. ; filter ]. ;
:: draw (\) bullets each [ pos dx>> +x 2 pt! dx>> 3 * dy>> pos +xy 4 pt! ]. for ;
].

: p-sprites ( # -- ) t[ 491 6 frame , 507 6 frame , ] anim.new >>move t[ 491 60 frame , ] anim.new >>stand ;
t[ t[ ] >>starts ] [ ::player
:: new ( -- p ) 
t[ ::pl 40 >>x 35 >>y 1 >>facing true >>live t[ p-sprites ] >>anims 0 >>gt 0 >>t 1 >>last-facing
:: alive ( # -- ? ) live>> ;
:: hurt ( # -- ) false >>live ;
] ;
:: anim { # name -- } pos -4 -7 +xy flipspr name anims>> get [ anim.draw ]. ;
:: draw ( # -- ) moved? if "move" else "stand" then player.anim ;

:: move { # dx dy -- } stopped
pos dx 0 +xy solid-around? if dx 0 mov dx zero? not >>moved then
pos 0 dy +xy solid-around? if 0 dy mov dy zero? not moved>> or >>moved then ;

:: tic ( # -- ) 
t>> 3 mod? not if 1 B_R 1 B_L -  1 B_D 1 B_U - /flip-xy player.move then
t>> 12 mod? moved? and if 2 "D-4" 5 2 3 sfx(*****) then
player.draw 
1 B_A? gt>> 0 <= and if 
    pos 3 - flipdir 0 bullets.spawn 12 >>gt  2 "F-3" 5 1 sfx(****) 
then 
gt>> 1 - 0 max >>gt ++t
moved? if anims>> .move [ anim.tic ]. then ;
]. 

: remap (*\*) { t } t 2 eq? if 0 else t then ; 
: map-tic (\) 0 0 30 17 0 0 -1 1 @remap map(*********) ;
\ : map-tic (\) @remap cmap ;

player.new { p_1 } @nil { mode }
: reset ( -- ) 
    p_1 [ @player.starts tpick [ pos ]. to-pos true >>live ].
    @mobs [ t[ ] >>enemies ].
    0 { SCORE } @game { mode } ;

: game ( -- ) 
8 cls(*) map-tic 
p_1 :alive(\*) if p_1 [ player.tic ]. else
    T 360 > if 
        "[A] to restart" 80 100 4 false 1 print(******) 
        1 B_A? if @reset { mode } then
    then
then
mobs.tic bullets.tic bullets.draw 
@mobs.enemies each { m } 
    m p_1 o-dist 2 < p_1 :alive(\*) and m .hurt and if 
        p_1 [ it :hurt() pos 0 { T } ]. 493 splat @mobs [ mobs.add ].
    then 
for
"SCORE: " SCORE ..  10 10 4 print(****) ;

: menu ( -- )
8 cls(*) 
map-tic 
"Pop or be popped" 20 30 2 sway 2 + 4 false 2 print(******)
T 180 > if "[Z (or A btn)] to start" 50 100 4 false 1 print(******) then
1 B_A? T 180 > and if @game { mode } then
;

: mscan { x y -- } x y mget(**\*) { id }
id 2 eq? if x y cell-mid mobs.spawner then 
id 1 eq? if x y cell-mid @player.starts [ <xy> , ]. then ;

: BOOT (\) 
    tstamp(\*) math.randomseed(*)
    0x3FF8 10 poke(**)
    30 0 do { mx } 17 0 do { my } mx my mscan loop loop 
    p_1 [ @player.starts tpick [ pos ]. to-pos ].
    @menu { mode } ;

: TIC (\) mode() 1 += T ;   

