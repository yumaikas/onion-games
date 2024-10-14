"art_carts/glass.lua" { art_cart_path }

: throw (**\) assert(**) ;

"build/pobp_o.lua" { game_built_path }
"build/pop_or_be_popped.lua" io.output(*)

"lua ../onion/onion.lua --compile pop_or_be_popped.fth build/pobp_o.lua" os.execute(*\**) throw

: echo ( ln -- ) "\n" .. io.write(*) ;

"-- title:   Pop or be popped" echo
"-- author:  yumaikas" echo
"-- desc:    A small action game" echo
"-- site:    https://github.com/yumaikas/onion-games/blob/main/pop_or_be_popped.fth" echo
"-- license: MIT License (change this to your license of choice)" echo
"-- version: 0.5" echo
"-- script:  lua" echo
"" echo
game_built_path io.lines[*\*] echo for
"" echo

false { out? }
art_cart_path io.lines[*\*] 
    out? if echo else dup "<TILES>" string.find(**\*) if true { out? } echo else drop then then
for


io.close() @io.stdout io.output(*)

"tic80 --skip build/pop_or_be_popped.lua" os.execute(*\**) throw
