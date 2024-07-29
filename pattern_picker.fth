#include(libgame)

@nil @nil @nil { image idata odata } 
0 0 { ox oy } \ origin
: o+xy ( x y -- ) ox oy +xy { ox oy } ;
1 1 { sx sy } \ scale
: s+xy ( x y -- ) sx sy +xy { sx sy } ;

20 20 { gox goy } \ grid origin
: g+xy ( dx dy -- ) gox goy +xy { gox goy } ;
18.9 21.2 { cx cy } \ cell size -- determined via experimenting for one image
: c+xy ( dx dy -- ) cx cy +xy { cx cy } ;
39 30 { gw gh } \ grid size

1300 80 { px py } \ preview
: p+xy ( dx dy -- ) px py +xy { px py } ;

: between? { v l h -- ? } v l >= v h < and ;

: get-pixel { # x y -- r g b } 
    it :getDimensions(\**) { w h }
    x 0 w between? 
    y 0 h between? and if
        x y it :getPixel(**\***)
    else
        1 0 1 
    then
;

: set-pixel { # x y r g b -- }
    it :getDimensions(\**) { w h }
    x 0 w between? 
    y 0 h between? and if
        x y r g b it :setPixel(*****)
    then
;


1 { save_count } 

@love.keyboard.isDown { keydown? } behaves keydown? (*\*)
@love.mouse.isDown { mousedown? } behaves mousedown? (*\*) 

@love.graphics { gfx } 

: love.load { args -- } 5 gfx.setPointSize(*) gw gh 1 1 +xy love.image.newImageData(**\*) { odata } ;
: love.update { dt -- }
;

: love.draw { -- } 
    image if 
        gfx.push()
        20 20 gfx.translate(**\)
        image ox oy 0 sx sy gfx.draw(******\)

        gw 0 do { cell-x } gh 0 do { cell-y } 
            cx cy cell-x cell-y *xxyy gox goy +xy { xx yy }
            1 0 1 gfx.setColor(***)
            xx yy gfx.points(**)
            idata [ xx yy ox oy -xy get-pixel { r g b } ].
            r g b gfx.setColor(***)
            cell-x cell-y 5 *xy px py +xy gfx.points(**)
            1 1 1 gfx.setColor(***)
            odata [ cell-x cell-y r g b set-pixel ].
        loop  loop
        1 1 1 gfx.setColor(***)

        gfx.pop()

    then
;
: shift-down? (\*) "lshift" keydown? "rshift" keydown? or ;

: love.mousemoved { x y dx dy -- } 
"q" keydown? image and if dx dy o+xy then 
"w" keydown? image and if dx dy g+xy then 
"e" keydown? image and if dx dy p+xy then
;

: love.keypressed { key -- }
    key print(*\)
    "escape" key eq? if @nil { image } then
    "=" key eq? shift-down? and if 0.1 0.1 s+xy then
    "-" key eq? shift-down? and if -0.1 -0.1 s+xy then
    "=" key eq? "a" keydown? and if 0.1 0 c+xy then
    "-" key eq? "a" keydown? and if -0.1 0 c+xy then
    "=" key eq? "s" keydown? and if 0 0.1 c+xy then
    "-" key eq? "s" keydown? and if 0 -0.1 c+xy then
    "f" key eq? if "png" "mpatt" save_count .. ".png" .. odata :encode(**) 1 += save_count then
    "space" key eq? if
        "Grid Origin: " gox goy print(***) 
        "Cell size: " cx cy print(***) 
    then
;

: love.filedropped { file -- } 
    file :getFilename(\*) "%.%w+$" swap :match(*\*) { ext }
    ext ".png" eq? if 
        "r" file :open(*\)
        "data" file :read(*\*) 
        love.image.newImageData(*\*) dup { idata }
        love.graphics.newImage(*\*) 
        { image }
        0 0 { ox oy }
    then
;


