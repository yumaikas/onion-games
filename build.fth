"/home/yumaikas/.local/share/com.nesbox.tic/TIC-80/glass.lua" { art_cart_path }

: throw (**\) assert(**) ;

"pobp_o.lua" { game_built_path }
"pop_or_be_popped.lua" io.output(*)

"lua ../onion/cli.lua --compile pop_or_be_popped.fth pobp_o.lua" os.execute(*\**) throw

: echo ( ln -- ) "\n" .. io.write(*) ;

"-- title:   Pop or be popped" echo
"-- author:  yumaikas" echo
"-- desc:    A small survival game" echo
"-- site:    https://gist.github.com/yumaikas/125ab5700aed5c19cf020b7e2657f70a" echo
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

"tic80 --skip pop_or_be_popped.lua" os.execute(*\**) throw
