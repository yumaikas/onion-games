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
: *xxyy { x y x1 y1 -- x' y' } x x1 * y y1 * ;
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
