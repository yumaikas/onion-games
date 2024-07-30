#include(libgame)
#include(libtic80)

0 { T }
\ Camera functions
0 0 { CX CY }
: to-cam ( x y -- ) { CX CY } ;
: cam-xy ( x y -- x' y' ) CX CY -xy 120 68 +xy ;
: pt! (***\) [ cam-xy ] pix(***) ;
: cpos ( # --  x y ) x>> y>> cam-xy ;

2 4 1 1 -xy [ "," .. ] .. trace(*)

: cmap (\) 
CX CY 8 div-xy 15 8 -xy
32 18 
8 CX 8 mod - 8 -
8 CY 8 mod - 8 -
00 1 map(********) ;

\ Support for "systems" that manage a list of entities
: cull ( # -- ) alive>> filter ;

\ A sprite is 32 bytes, or 64 nibbles
\ Sprite IDs start 0x4000 bytes or 0x8000 nibbles
t[ ::splat 
:: new { x y id -- s } t[ x y to-pos 1 >>t 0x8000 id 64 * + { addr } 63 0 do addr + peek4(*\*) , loop ] ;
:: alive (#\*) it len pos?  ;
:: tic (#\)
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
]. ;


: pick-swim-loc ( -- x y ) 0 8 239 * dLH  8 69 * 8 101 * dLH ;

t[ ::anim
:: new ( t -- anim ) t[ >>frames 0 >>t 1 >>f ] ;
:: frame ( # -- fr ) f>> frames>> get ;
:: draw { # x y -- } anim.frame [ id>> x y cam-xy 0 1 f>> r>> spr(*******) ]. ;
:: next-frame ( # -- ) f>> 1 + >>f f>> frames>> len > if 1 >>f then ;
:: tic ( # -- ) anim.frame .d t>> < if 0 >>t anim.next-frame then ++t ; \ TODO: Resume here
].

t[ ::bubbles
:: spawn (**\) bubbles [ t[ to-pos 0 >>t ] , ]. ;
:: alive (*\*) .t 60 < ; 
:: tic (\) bubbles each [ t>> 2 mod? if 0 -1 mov then ++t ]. for bubbles [ cull ]. ;
:: draw (\) bubbles each [ cpos t>> 20 div 1 max 11 circb(****) ]. for ;
].

t[ ::bombs
:: spawn ( x y dx -- ) bombs [ t[ >>dx to-pos 0 >>t ] , ]. ;
:: alive (*\*) .t 120 < ;
:: tic (\) bombs each [ ++t t>> 2 mod? dx>> 0 ? -1 mov ]. for bombs [ cull ].  ;
:: draw (\) bombs each [ cpos 1 3 -xy 2 t>> 15 div max 6 min 9 circ(****) ]. for ;
].


t[ ::bullets 
:: spawn ( x y dx dy -- ) bullets [ t[ >>dy >>dx to-pos 1 >>t ] , ]. ;
:: hurt ( # -- ) 121 >>t ;
:: alive ( * -- ? ) .t 120 < ;
:: tic (\)
    bullets each [ dx>> 3 * dy>> mov ++t ]. for bullets [ cull ].
    \ @mobs.enemies each { m } bullets each { b }
        \ m .hurt m b o-dist 4 < b [ bullets.alive ]. and and if 
            \ m :hurt() b [ bullets.hurt ]. 
            \ m [ pos ]. 283 splat @mobs [ mobs.add ]. 1 += SCORE
            \ 0 "C#2" 15 0 sfx(****) 
        \ then
    \ for for
    ;
:: draw (\) bullets each [ cpos dx>> dy>> 6 *xy cpos +xy 4 line(*****) ]. for ;
].
: spot (#**\*) cell-mid <xy> ;
t[ 141 100 spot , 84 100 spot , 153 100 spot , 198 100 spot , ] { safe_spots }
: wander ( # x y -- ) <xy> >>target "wander" >>state ; : wander? ( # -- ? ) state>> "wander" eq? ;
: hide ( # t -- ) >>target "hide" >>state ; : hide?  ( # -- ? ) state>> "hide" eq? ;
t[ ::kidfish
    :: new ( x y id -- ) kidfish [ 
        t[ >>presentation to-pos 0 >>t false >>flip pick-swim-loc wander ] , ]. ;
    :: mov? ( # -- m ) t>> hide? 1 4 ? mod? ;
    :: alive ( * -- ? ) drop true ;
    :: wave_start ( -- ) kidfish each [ it safe_spots closest hide ]. for ;
    :: wave_end ( -- ) kidfish each [ pick-swim-loc wander ]. for ;
    :: tic ( -- ) kidfish each [ 
        ++t 
        hide? wander? target-dist  { h? w? tdist }
        kidfish.mov? { mov? }
        cond
            h? tdist 5 < and -> @nil drop of
            w? tdist 5 < and -> pick-swim-loc wander of
            mov? -> towards-target /flip-xy mov of
        end
    ]. for ;
    :: draw ( -- ) kidfish each [ presentation>> cpos 0 1 flipspr spr(******) ]. for ;
].
: masc (#\) 272 , ; : femme (#\) 273 , ;
t[ femme femme femme femme masc masc masc masc ] 
each [ safe_spots tpick [ pos ]. ] kidfish.new for

t[ ::player
:: new ( x y -- p ) t[ to-pos 0 >>t 0 >>gt 0 >>bt false >>flip t[ ] >>spawned  ] ;
:: draw ( # -- ) 256 cpos 4 5 -xy 0 1 flipspr 0 2 1 spr(*********) ;
:: tic ( # -- ) ++t "gt" ++ "bt" ++
t>> 1 mod? if 1 B_R 1 B_L - 1 B_D 1 B_U - /flip-xy mov then
1 B_Y? gt>> 6 > and if 0 >>gt pos flipdir 0 bullets.spawn then 
1 B_X? bt>> 60 > and if 0 >>bt pos flipdir bombs.spawn then ; 
].

t[ ::pinkfish 
: pt-cloud ( # n -- pts ) t[ 2 swap dLH 1 do drop -4 4 dLH -4 4 dLH <xy> , loop ] ; 
:: spawn ( x y n -- ) { n } pinkfish [ t[ to-pos pick-swim-loc <xy> >>target 0 >>mt 0 >>t n pt-cloud >>fish ] , ]. ;
:: tic ( -- ) pinkfish each [
    ++t  fish>> each  [ 20 dX 9 eq? if -1 1 dLH -1 1 dLH mov x>> 8clamp >>x y>> 8clamp >>y then ]. for
    target pos dist 2 < if pick-swim-loc <xy> >>target then 
    t>> 4 mod? if towards-target mov then
    0 100 dLH 99 > if pos bubbles.spawn then
]. for ;
:: draw ( -- ) pinkfish each [ 
    cpos { atx aty } fish>> each [ atx aty pos +xy 2dup 1 +x 6 line(*****) ]. for   
]. for ;
].

0 0 1 player.new { p1 }


: TIC ( -- )
    0 cls(*)
    \ A lil debugging
    15 keyp if kidfish.wave_start then
    16 keyp if kidfish.wave_end then
    p1 [ "@" x>> .. ", " .. y>> ..  ]. 10 10 4 print(****)
    p1 [ player.tic ]. kidfish :tic() pinkfish :tic() bullets :tic() bubbles :tic() bombs :tic()
    p1 [ pos to-cam ]. 
    cmap bubbles :draw() kidfish :draw() p1 [ player.draw ].  bullets :draw() bombs :draw() pinkfish :draw()
    1 += T
;

: BOOT ( -- ) tstamp(\*) math.randomseed(*)
    p1 [ 101 98 8 *xy to-pos ].
    240 0 do { x } 134 0 do { y } x y mget(**\*) 
        dup [ 11 eq? ] 12 eq? or if x y 0 mset(***) x y 8 *xy 3 pinkfish.spawn then
    loop loop
;

\ Plot:

