0 { T }
0 { SCORE }
: sway { p m -- s } T p div math.sin(*\*) m * ;
: m (\*) t[ ] ;
: zero? (*\*) 0 eq? ;
: mod? (**\*) mod 0 eq? ;
: pos? (*\*) 0 > ;
: neg? (*\*) 0 < ;
: max (**\*) math.max(**\*) ;
: min (**\*) math.min(**\*) ;
: range-clamp { l h -- f } : (*\*) l max h min ; ;
-2 2 range-clamp { clamper }
: clamp1 (*\*) clamper(*\*) ;
: str (*\*) tostring(*\*) ;
: sq (*\*) dup * ;
: , ( # v -- ) table.insert(#*) ;
: +x { x y dx -- x' y } x dx + y ;
: +y { x y dy -- x y' } x y dy + ;
: ++t ( # -- ) t>> 1 + >>t ;
: target ( # -- x y ) target>> [ pos ]. ;
: o-dist { a b -- d } a [ pos ]. b [ pos ]. dist ;
: dist { x1 y1 x2 y2 -- d } x1 x2 - sq y1 y2 - sq + math.sqrt(*\*) ;
: vmag { x y -- m } 0 x 0 y dist ;
: norm { x y -- x' y' } x y vmag { l } x l div clamp1 y l div clamp1 ;
: pos ( # -- x y ) x>> y>> ;
: to-pos ( # x y -- ) >>y >>x ;
: +xy { x y dx dy  -- x' y' } x dx + y dy + ;
: -xy { x y dx dy  -- x' y' } x dx - y dy - ;
: *xy { x y m -- x' y' } x m * y m * ;
: cell-mid ( x y -- x' y' ) [ 8 * 4 + ] 8 * 4 + ;
: tpick { t -- c }  1 t len math.random(**\*) t get ;
: t-nil-rand { t -- } t len pos? if t 1 t len math.random(**\*) @nil put then ;
: dX ( x -- d ) 1 swap math.random(**\*) ;
0 0 { CX CY }
: cam-xy ( x y -- x' y' ) CX CY -xy 120 68 +xy ;
: pt! (***\) [ cam-xy ] pix(***) ;

: mov ( # x y -- ) y>> + >>y x>> + >>x ;
: <xy> ( x y -- xy ) t[ to-pos ] ;

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

0 1 2 3 4 5 6 7 { B_U B_D B_L B_R B_A B_B B_X B_Y }
\ # is the player ID, v is the button id
: bt? ( # v -- ? ) it 1 - 8 * + btn(*\*) ;

: facing { x -- f } x 0 eq? if 0 else x 0 > if 1 else -1 then then ;
: p-xyf (*\***) [
    \ Takes the player number, gives the X/Y and facing of the controller
0 0 { x y }
B_U bt? if 1 -= y then
B_D bt? if 1 += y then
B_L bt? if 1 -= x then
B_R bt? if 1 += x then ].
x y x facing ;

m { anim } 
: anim.new ( t -- anim ) t[ >>frames 0 >>t 1 >>f ] ;
: anim.frame ( # -- fr ) f>> frames>> get ;
: anim.draw { # x y -- } anim.frame [ id>> x y cam-xy 0 1 f>> r>> spr(*******) ]. ;
: anim.next-frame ( # -- ) f>> 1 + >>f f>> frames>> len > if 1 >>f then ;
: anim.tic ( # -- ) anim.frame .d t>> < if 0 >>t anim.next-frame then ++t ;

: filter { # pred -- } it { coll } 
coll len 1 -1 +do [ it coll get pred(*\*) not if coll it table.remove(**) then ]. loop ;

: p-sprites ( # -- ) 
  t[ 491 6 frame , 507 6 frame , ] anim.new >>right
  t[ 491 6 flipped , 507 6 flipped , ] anim.new >>left 
  t[ 491 60 frame , ] anim.new >>stand_right
  t[ 491 60 flipped , ] anim.new >>stand_left ;

\ A sprite is 32 bytes, or 64 nibbles
\ Sprite IDs start 0x4000 bytes or 0x8000 nibbles
: splat { x y id -- s }  t[ x y to-pos 1 >>t
    0x8000 id 64 * + { addr } 63 0 do addr + peek4(*\*) , loop
] { spl }
: spl.alive ( # -- ? ) it len pos? ;
: spl.tic ( # -- )  
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
; spl ;
    
t[ t[ ] >>enemies t[ ] >>spawns ] { mobs }

: mob-balloon ( x y -- b ) t[ to-pos  
t[ 
 t[ 267 24 flipped , 283 24 flipped , ] anim.new >>left 
 t[ 267 24 frame , 283 24 frame , ] anim.new >>right 
] >>anims
true >>live
@mobs.spawns tpick >>target
] { ball }
: ball.tic ( # -- ) it { me }
    target pos dist 2 < if @mobs.spawns tpick >>target then
    target pos -xy { dx dy } dx dy norm 0.5 *xy mov
    \ TODO: Figure out why "fast" movement happens
    anims>> dx pos? if .right else .left then [ anim.tic me [ pos 3 4 -xy ]. anim.draw ]. ;
    \ pos 2 7 circ(****) ; \ Debug stuff
: ball.alive ( # -- ? ) live>> ;
: ball.hurt ( # -- ) false >>live ;
 ball ;

: mobs.add ( # m -- ) enemies>> [ , ]. ;
: mobs.spawner ( x y -- ) @mobs.spawns [ <xy> , ].  ;
: mobs.tic ( -- ) @mobs [
    T 60 mod? 4 dX 3 <= and if spawns>> tpick [ pos ]. { sx sy } 
        3 dX 1 - 1 do drop sx sy mob-balloon mobs.add loop 
    then
    enemies>> each :tic() for
    enemies>> [ : (*\*) :alive(\*) ; filter ].
]. ;

m { bullets }
: bullets.spawn ( x y dx dy -- ) bullets [ t[ >>dy >>dx to-pos 1 >>t ] , ]. ;
: bullets.hurt ( # -- ) 121 >>t ;
: bullets.alive ( # -- ? ) t>> 120 < ;
: bullets.tic (\)
    bullets each [ dx>> 3 * dy>> mov ++t ]. for 
    @mobs.enemies each { m } bullets each { b }
        m .hurt m b o-dist 4 < b [ bullets.alive ]. and and if 
            m :hurt() b [ bullets.hurt ]. 
            m [ pos ]. 283 splat @mobs [ mobs.add ]. 1 += SCORE
            0 "C#2" 15 0 sfx(****) 
        then
    for for
    bullets [ : (*\*) [ bullets.alive ]. ; filter ]. ;
: bullets.draw (\) bullets each [ pos dx>> +x 2 pt! dx>> 3 * dy>> pos +xy 4 pt! ]. for ;

t[ t[ ] >>starts ] { player }
: player.new ( -- p ) 
t[ 40 >>x 35 >>y 1 >>facing true >>live t[ p-sprites ] >>anims 0 >>gt 0 >>t 1 >>last-facing ] { pl }
: pl.alive ( # -- ? ) live>> ;
: pl.hurt ( # -- ) false >>live ;
pl ;

: player.anim { # name -- } 
pos -4 -7 +xy name anims>> get [ anim.draw ]. ;

: player.draw ( # -- ) cond 
 facing>> 0 eq? last-facing>> 0 < and -> "stand_left" of
 facing>> 0 eq? last-facing>> 0 > and -> "stand_right" of
 facing>> 0 > -> "right" of
 true -> "left" of 
end player.anim ;

: player.move { # dx dy -- } 
pos dx 0 +xy solid-around? if dx 0 mov then
pos 0 dy +xy solid-around? if 0 dy mov then ;

: player.tic ( # -- ) 
1 p-xyf { dx dy f } f >>facing 
dy zero? not if last-facing>> >>facing then
f zero? not if f >>last-facing then
t>> 3 mod? not if dx dy player.move then
pos { CX CY }
t>> 12 mod? dx dy vmag pos? and if 2 "D-4" 5 2 3 sfx(*****) then
player.draw 
1 [ B_A bt? ]. gt>> 0 <= and if 
     pos 3 - last-facing>> 0 bullets.spawn 12 >>gt 
    2 "F-3" 5 1 sfx(****) 
then 
gt>> 1 - 0 math.max(**\*) >>gt
++t
cond
facing>> 1 eq? -> anims>> .right [ anim.tic ]. of
facing>> -1 eq?  -> anims>> .left [ anim.tic ]. of 
end ;


: remap (*\*) { t } t 2 eq? if 0 else t then ; 
: map-tic (\) 0 0 30 17 0 0 -1 1 @remap map(*********) ;

player.new { p_1 }
@nil { mode }

: reset ( -- ) 
    p_1 [ @player.starts tpick [ pos ]. to-pos true >>live ].
    @mobs [ t[ ] >>enemies ].
    0 { SCORE }
    @game { mode }
;

: game ( -- ) 
8 cls(*) 
map-tic 
p_1 :alive(\*) if p_1 [ player.tic ]. else
    T 360 > if 
        "[A] to restart" 80 100 4 false 1 print(******) 
        1 [ B_A bt? ]. if @reset { mode } then
    then
then
mobs.tic
bullets.tic bullets.draw 
@mobs.enemies each { m } 
    m p_1 o-dist 2 < p_1 :alive(\*) and m .hurt and if 
        p_1 [ it :hurt() pos 0 { T } ]. 493 splat @mobs [ mobs.add ].
    then 
for
"SCORE: " SCORE ..  10 10 4 print(****) 
;

: menu ( -- )
8 cls(*) 
map-tic 
"Pop or be popped" 20 30 2 sway 2 + 4 false 2 print(******)
T 360 > if "[A] to start" 80 100 4 false 1 print(******) then
1 [ B_A bt? ]. T 180 > and if @game { mode } then
;

: mscan { x y -- } x y mget(**\*) { id }
id 2 eq? if x y cell-mid mobs.spawner then 
id 1 eq? if x y cell-mid @player.starts [ <xy> , ]. then ;

: BOOT (\) 
    0x3FF8 10 poke(**)
    30 0 do { mx } 17 0 do { my } mx my mscan loop loop 
    p_1 [ @player.starts tpick [ pos ]. to-pos ].
    @menu { mode } ;

: TIC (\) mode() 1 += T ;   

