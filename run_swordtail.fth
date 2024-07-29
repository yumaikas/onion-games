"art_carts/SwordTail.rb" { art_cart_path }

: throw (**\) assert(**) ;

"build/swt_o.lua" { game_built_path }
"build/swordtail.lua" io.output(*)

"lua ../onion/cli.lua --compile swordtail.fth build/swt_o.lua" os.execute(*\**) throw

: echo ( ln -- ) "\n" .. io.write(*) ;

"-- title:   Swordtail" echo
"-- author:  yumaikas" echo
"-- desc:    swordtail" echo
"-- site:    https://github.com/yumaikas/onion-games/blob/main/swordtail.fth" echo
"-- license: MIT License" echo
"-- version: 0.2" echo
"-- script:  lua" echo
"" echo
game_built_path io.lines[*\*] echo for
"" echo

: fix-echo (*\) [ "^#" "--" ] :gsub(**\*) echo ;
false { out? }
art_cart_path io.lines[*\*] 
    out? if fix-echo else dup "<TILES>" string.find(**\*) if true { out? } fix-echo else drop then then
for


io.close() @io.stdout io.output(*)

"tic80 --skip build/swordtail.lua" os.execute(*\**) throw
