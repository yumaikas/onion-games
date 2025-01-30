\ Simple snake game, written in Onion, ported from vimsnake in Equinox Forth
\ HJKL for controls, vim-style

\ To run, `onion --compile snake.fth snake-game/main.lua`, then run `love snake-game`

: 1- (*\*) 1 - ;
: 2dup { a b -- * * * * } a b a b ;
: div-xy { x y m -- x' y' } x m div y m div ;
: draw-rect (*****\) love.graphics.rectangle(*****) ;
: floor (*\*) math.floor(*\*) ;
: floor-xy { x y -- x' y' } x floor y floor ;
: rnd (**\*) math.random(**\*) ;
: color (***\) love.graphics.setColor(***\) ;
: fullscr (*\) love.window.setFullscreen(*\) ;
: position (#\**) x>> y>> ;

love.graphics.getDimensions(\**) 2dup { scr_w scr_h } div { aspect_ratio }
50 { width }

width aspect_ratio div floor { height }
scr_w scr_h width div-xy { cell_w cell_h }

width height 2 div-xy floor-xy { cx cy }

@nil @nil { input state }

0.125 { refresh_rate }
1 0 0 0 { vx vy time score }

array table { snake food }

: refresh? ( dt -- ? ) += time time refresh_rate > ;
: reset-timer (\) 0 { time } ;

: last (*\*) dup len swap get ;
: head ( -- p ) snake last ;
: cut (\) snake 1 table.remove(**\) ;

: spawn-snake ( len -- )
    array [ it { snake }
        2 div floor dup -1 * do { i }
            t[ cx i + >>x cy >>y ] ,
        loop 
    ]. ;

: spawn-food (\) food [
    1 width  2 - rnd >>x
    1 height 2 - rnd >>y ]. ;

: init (\)
    0 { score } 
    1 0 { vx vy }
    @nil { input }
    "playing" { state }
    spawn-food 
    3 spawn-snake ;
    
\ Drawing and graphics
\ Seems to be a bug? Keeping this around for later bugfix investigations
: translate ( x y -- 'x' y ) cell_h * swap cell_w * swap ;
\ At least this form works
: translate { x y -- 'x' y } x cell_w * y cell_h * ;

: draw-text ( s x y -- ) 0 3 3 love.graphics.print(******) ;

: red   (\***) 1 0 0 ;
: green (\***) 0 1 0 ;
: blue  (\***) 0 0 1 ;
: white (\***) 1 1 1 ;


: draw-block { x y -- } 
    "fill" x y translate cell_w cell_h draw-rect ;

: draw-snake (\) snake each [ position draw-block ]. for ;
: draw-food (\) food [ position ]. draw-block ;

: draw-cage (\) 
    width 1- 0 do { i }
        i 0          draw-block
        i height 1 - draw-block
    loop
    height 1- 0 do { i }
        0         i draw-block
        width 1 - i draw-block
    loop ;

: draw-score (\) "Score: " score .. 0 0 translate draw-text ;

: draw-message (\)
    state "game-over" eq? if
        "Game Over! Press SPACE to restart."
            cx 8 - cy 1 - translate draw-text
    then ;

\ Collision detection

\ Another case of swap being bugged around accessors
: x= ( p1 p2 -- ? ) .x swap .x eq? ;
: x= { p1 p2 -- ? } p1 .x p2 .x eq? ;
: y= { p1 p2 -- ? } p1 .y p2 .y eq? ;

: hit? ( pt -- ? ) 
    dup head x= 
    swap head y= and ;

: advance (\) 
    snake [ t[
            head .x vx + >>x
            head .y vy + >>y
    ] , ]. ;
    
: hit-wall? ( -- ? )
    head .x 1 < head .x width 1 - >= or
    head .y 1 < head .y height 1 - >= or or ;

: hit-self? ( -- ? ) false { ret }
    snake len 1 - 1  do { i } i snake get hit? or= ret loop
    ret ;

: detect-hit (\) 
    hit-wall? hit-self? or if "game-over" { state } then
    food hit? 
        if spawn-food 1 += score 
        else cut then ;

: turn-left (\)  vx  1 neq? if -1  0 { vx vy } then ;
: turn-right (\) vx -1 neq? if  1  0 { vx vy } then ;
: turn-up (\)    vy  1 neq? if  0 -1 { vx vy } then ;
: turn-down (\)  vy -1 neq? if  0  1 { vx vy } then ;


@nil { input }

: control (\)
    cond
      input "k" eq? -> turn-up of
      input "j" eq? -> turn-down of
      input "h" eq? -> turn-left of
      input "l" eq? -> turn-right of
    end ;

: love.load (\) 
    os.time(\*) math.randomseed(*\) 
    true fullscr
    init ;

: love.draw (\)
    green color draw-snake
    blue  color draw-cage
    red   color draw-food
    white color draw-message
    white color draw-score ;

: love.update { dt -- }
    state "game-over" neq?
    dt refresh? and if
        control
        advance
        detect-hit
        reset-timer
    then
;
    
: love.keypressed { key -- }
    cond
        key "escape" eq? -> love.event.quit() of
        key "space" eq?  -> "game-over" state eq? if init then of
        true -> key { input } of
    end
;

