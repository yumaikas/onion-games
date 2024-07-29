: throw (**\) assert(**) ;

"lua ../onion/cli.lua --compile pattern_conf.fth pattern/conf.lua" os.execute(*\**) throw
"lua ../onion/cli.lua --compile pattern_picker.fth pattern/main.lua" os.execute(*\**) throw
"love pattern --console" os.execute(*\**) 
