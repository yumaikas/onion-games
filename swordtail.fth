\ Math and support words, to be added to a "game.fth" some day
: 2dup { a b -- * * * * } a b a b ;
: zero? (*\*) 0 eq? ;
: mod? (**\*) mod 0 eq? ;
: pos? (*\*) 0 > ;
: neg? (*\*) 0 < ;
: max (**\*) math.max(**\*) ;
: min (**\*) math.min(**\*) ;
: range-clamp { l h -- f } : (*\*) l max h min ; ;
-2 2 range-clamp { clamper }
-8 8 range-clamp { clamp8 } behaves clamp8 (*\*) 
: clamp1 (*\*) clamper(*\*) ;
: str (*\*) tostring(*\*) ;
: sq (*\*) dup * ;
: ? { pred a b -- * } pred if a else b then ; 
: , ( # v -- ) table.insert(#*) ;
: +x { x y dx -- x' y } x dx + y ;
: +y { x y dy -- x y' } x y dy + ;
: ++t ( # -- ) t>> 1 + >>t ;
: ++ { # n -- } it n it n get 1 + put ;
: pos ( # -- x y ) x>> y>> ;
: target ( # -- x y ) target>> [ pos ]. ;
: dist { x1 y1 x2 y2 -- d } x1 x2 - sq y1 y2 - sq + math.sqrt(*\*) ;
: vmag { x y -- m } 0 x 0 y dist ;
: norm { x y -- x' y' } x y vmag { l } x l div clamp1 y l div clamp1 ;
: to-pos ( # x y -- ) >>y >>x ;
: /flip-xy { # dx dy -- dx dy } dx zero? not if dx neg? >>flip then dx dy ;
: flipdir (#\*) flip>> -1 1 ? ;
: flipspr (#\*) flip>> 0 1 ? ;  
: +xy { x y dx dy  -- x' y' } x dx + y dy + ;
: -xy { x y dx dy  -- x' y' } x dx - y dy - ;
: *xy { x y m -- x' y' } x m * y m * ;
: div-xy { x y m -- x' y' } x m div y m div ;
: mod-xy { x y m -- x' y' } x m mod y m mod ;
: mov ( # x y -- ) y>> + >>y x>> + >>x ;
: <xy> ( x y -- xy ) t[ to-pos ] ;
: tpick { t -- c }  1 t len math.random(**\*) t get ;
: towards-target ( # -- x y ) target pos -xy norm 0.5 *xy ;
: target-dist ( # -- d ) target pos dist ;
: o-dist { a b -- d } a [ pos ]. b [ pos ]. dist ;
: closest { me spots -- spot } @nil @math.huge { ret min-dist } 
spots each { s } s me o-dist { d } d min-dist < if s d { ret min-dist } then for ret ;
: dX ( x -- d ) 1 swap math.random(**\*) ;
: rX ( x -- d ) 0 swap math.random(**\*) ;
: dLH ( l h -- d ) math.random(**\*) ;
: filter { # pred -- } it { coll } 
coll len 1 -1 +do [ it coll get pred(*\*) not if coll it table.remove(**) then ]. loop ;


\ TIC-80 specific stuff
: cell-mid ( x y -- x' y' ) [ 8 * 4 + ] 8 * 4 + ;
: bt? { p v -- fn } p 1 - 8 * v + btn(*\*) ; 
: bt (**\*) bt? 1 0 ? ;
: B_U (*\*) 0 bt ; : B_D (*\*) 1 bt ;
: B_L (*\*) 2 bt ; : B_R (*\*) 3 bt ;
: B_A? (*\*) 4 bt? ; : B_B? (*\*) 5 bt? ;
: B_X? (*\*) 6 bt? ; : B_Y? (*\*) 7 bt? ;

0 { T }
: sway { p m -- s } T p div math.sin(*\*) m * ;

\ A sprite is 32 bytes, or 64 nibbles
\ Sprite IDs start 0x4000 bytes or 0x8000 nibbles
: splat { x y id -- s } 
t[ x y to-pos 1 >>t 0x8000 id 64 * + { addr } 63 0 do addr + peek4(*\*) , loop ] ;
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
] ;

\ Camera functions
0 0 { CX CY }
: cam-xy ( x y -- x' y' ) CX CY -xy 120 68 +xy ;
: pt! (***\) [ cam-xy ] pix(***) ;
: cpos ( # --  x y ) x>> y>> cam-xy ;
: cmap (\) 
CX CY 8 div-xy 15 8 -xy 
32 18 
8 8 CX CY 8 mod-xy -xy 8 8 -xy
00 1 map(********) ;

\ Support for "systems" that manage a list of entities
: cull ( # -- ) alive>> filter ;


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
:: tic (\) bubbles each [ 0 -1 mov ++t ]. for bubbles cull ;
:: draw (\) bubbles each [ cpos t>> 20 div 1 max 11 circ(****) ]. for ;
].

t[ ::bombs
:: spawn ( x y dx -- ) bombs [ t[ >>dx to-pos 0 >>t ] , ]. ;
:: alive (*\*) .t 120 < ;
:: tic (\) bombs each [ ++t t>> 2 mod? dx>> 0 ? -1 mov ]. for bombs cull ;
:: draw (\) bombs each [ cpos 1 3 -xy 2 t>> 15 div max 6 min 9 circ(****) ]. for ;
].


t[ ::bullets 
:: spawn ( x y dx dy -- ) bullets [ t[ >>dy >>dx to-pos 1 >>t ] , ]. ;
:: hurt ( # -- ) 121 >>t ;
:: alive ( * -- ? ) .t 120 < ;
:: tic (\)
    bullets each [ dx>> 3 * dy>> mov ++t ]. for bullets cull
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

t[ ] { safe_spots }
: wander ( # t -- ) >>target "wander" >>state ; : wander? ( # -- ? ) state>> "wander" eq? ;
: hide ( # t  -- ) >>target "hide" >>state ; : hide?  ( # -- ? ) state>> "hide" eq? ;
t[ ::kidfish
    :: new ( x y id -- ) kidfish [ 
        t[ >>presentation to-pos 0 >>t false >>flip pick-swim-loc wander ] , ]. ;
    :: mov? ( # -- m ) hide? 4 8 ? ;
    :: alive ( * -- ? ) drop true ;
    :: wave_start ( -- ) kidfish each [ it safe_spots closest hide ]. for ;
    :: wave_end ( -- ) kidfish each [ pick-swim-loc wander ]. for ;
    :: tic ( -- ) kidfish each [ 
        ++t 
        cond
            hide? target-dist 5 < -> @nil drop of
            wander? target-dist 5 < -> pick-swim-loc wander of
            kidfish.mov? -> towards-target /flip-xy mov of
        end
    ]. for ;
    :: draw ( -- ) kidfish each [ presentation>> cpos 0 1 flipspr spr(******) ]. for ;
].

t[ ::player
:: new ( x y b -- p ) t[ >>b to-pos 0 >>t 0 >>gt 0 >>bt false >>flip t[ ] >>spawned  ] ;
:: draw ( # -- ) 256 cpos 0 1 flip>> if 0 else 1 then 0 2 1 spr(*********) ;
:: tic ( # -- ) ++t "gt" ++ "bt" ++
t>> 1 mod? if 1 B_R 1 B_L - 1 B_D 1 B_U - /flip-xy mov then
1 B_Y? gt>> 6 > and if 0 >>gt pos flipdir 0 bullets.spawn then 
1 B_X? bt>> 60 > and if 0 >>bt pos flipdir bombs.spawn then ; 
].

t[ ::pinkfish 
: pt-cloud ( # n -- pts ) t[ 2 swap dLH 1 do -4 4 dLH -4 4 dLH <xy> , loop ] ; 
:: spawn ( x y n -- ) { n } t[ to-pos pick-swim-loc >>target 0 >>mt 0 >>t n pt-cloud >>fish ]. ;
:: tic ( -- ) pinkfish each [
    ++t  fish>> each [ -1 1 dLH -1 1 dLH mov x>> clamp8 >>x y>> clamp8 >>y ]. for
    target pos dist 2 < if pick-swim-loc >>target then 
    t>> 4 mod? if towards-target mov then
    0 100 dLH 99 > if pos bullets.spawn then
]. for ;
:: draw ( -- ) pinkfish each [ 
    cpos { at } fish>> each [ at pos +xy 2dup 1 +x 6 line(*****) ]. for   
]. for ;
].


