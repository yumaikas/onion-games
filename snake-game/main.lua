function _comma_(it, p1) table.insert(it, p1)   end  
 function s_slash_join(it)  local _1 = table.concat(it)   return _1 end  
 function str(p1)  local _2 = tostring(p1)   return _2 end  

 

 function max(p1, p2)  local _3 = math.max(p1, p2)   return _3 end  
 function min(p1, p2)  local _4 = math.min(p1, p2)   return _4 end  

 function randint(p1, p2)  local _5 = math.random(p1, p2)   local _6 = math.floor(_5)   return _6 end  
 function randf()  local _7 = math.random()   return _7 end  

 function array() local _8 = {}   return _8 end  
 function between(i, ra, rb)  
      local _9 = min(ra, rb)  
      local _10 = max(ra, rb)   return ((i >= _9) and (i <= _10)) end  

 function __1_(p1)  return (p1 - 1) end  
 function __2dup(a, b)  return a, b, a, b end  
 function div_xy(x, y, m)  return (x / m), (y / m) end  
 function draw_rect(p1, p2, p3, p4, p5) love.graphics.rectangle(p1, p2, p3, p4, p5)   end  
 function floor(p1)  local _11 = math.floor(p1)   return _11 end  
 function floor_xy(x, y)  local _12 = floor(x)   local _13 = floor(y)   return _12, _13 end  
 function rnd(p1, p2)  local _14 = math.random(p1, p2)   return _14 end  
 function color(p1, p2, p3) love.graphics.setColor(p1, p2, p3)   end  
 function fullscr(p1) love.window.setFullscreen(p1)   end  
 function position(it)  return it.x, it.y end  

  local _15, _16 = love.graphics.getDimensions()   local _17, _18, _19, _20 = __2dup(_15, _16)  local scr_h,scr_w = _20, _19 local aspect_ratio = (_17 / _18) 
 local width = 50 

  local _21 = floor((width / aspect_ratio))  local height = _21 
  local _22, _23 = div_xy(scr_w, scr_h, width)  local cell_h,cell_w = _23, _22 

  local _24, _25 = div_xy(width, height, 2)   local _26, _27 = floor_xy(_24, _25)  local cy,cx = _27, _26 

 local state,input = nil, nil 

 local refresh_rate = 0.125 
 local score,time,vy,vx = 0, 0, 0, 1 

  local _28 = array()  local _29 = {}  local food,snake = _29, _28 

 function refresh_question_(p1) time = time + p1  return (time > refresh_rate) end  
 function reset_timer() time = 0  end  

 function last(p1)  return p1[#p1] end  
 function snake_len()  return #snake end  
 function head()  local _30 = last(snake)   return _30 end  
 function cut() table.remove(snake, 1)   end  

 function spawn_snake(p1) 
      local _31 = array()  snake = _31 
          local _32 = floor((p1 / 2))   for _33 = (_32 * -1),_32 do local i = _33 
             local _34 = {}  _34.x = (cx + i)  _34.y = cy  _comma_(_31, _34)  
          end   
      end  

 function spawn_food() 
      local _35 = rnd(1, (width - 2))  food.x = _35  
      local _36 = rnd(1, (height - 2))  food.y = _36   end  

 function init() 
     score = 0  
     vy,vx = 0, 1 
     input = nil 
     state = "playing" 
     spawn_food()   
     spawn_snake(3)   end  
    
 function translate(p1, p2)  return ((p2 * cell_h) * cell_w), p1 end  
 function translate(x, y)  return (x * cell_w), (y * cell_h) end  

 function draw_text(p1, p2, p3) love.graphics.print(p1, p2, p3, 0, 3, 3)   end  

 function red()  return 1, 0, 0 end  
 function green()  return 0, 1, 0 end  
 function blue()  return 0, 0, 1 end  
 function white()  return 1, 1, 1 end  


 function draw_block(x, y)  
      local _37, _38 = translate(x, y)  draw_rect("fill", _37, _38, cell_w, cell_h)   end  

 function draw_snake()  for _, _39 in ipairs(snake) do  local _40, _41 = position(_39)  draw_block(_40, _41)   end   end  
 function draw_food()  local _42, _43 = position(food)  draw_block(_42, _43)   end  

 function draw_cage()  
      local _44 = __1_(width)   for _45 = 0,_44 do local i = _45 
         draw_block(i, 0)  
         draw_block(i, (height - 1))  
      end  
      local _46 = __1_(height)   for _47 = 0,_46 do i = _47 
         draw_block(0, i)  
         draw_block((width - 1), i)  
      end   end  

 function draw_score()  local _48, _49 = translate(0, 0)  draw_text(("Score: " .. score), _48, _49)   end  

 function draw_message() 
      if (state == "game-over") then 
          local _50, _51 = translate((cx - 8), (cy - 1))  draw_text("Game Over! Press SPACE to restart.", _50, _51)  
      end   end  

 function x_equal_(p1, p2)  return (p1 == p2.x.x) end  
 function x_equal_(p1, p2)  return (p1.x == p2.x) end  
 function y_equal_(p1, p2)  return (p1.y == p2.y) end  

 function hit_question_(p1)  
      local _52 = head()   local _53 = x_equal_(p1, _52)   
      local _54 = head()   local _55 = y_equal_(p1, _54)   return (_53 and _55) end  

 function advance()  
     local _56 = {}  
              local _57 = head()  _56.x = (_57.x + vx)  
              local _58 = head()  _56.y = (_58.y + vy)  
     _comma_(snake, _56)   end  
    
 function hit_wall_question_() 
      local _59 = head()   local _60 = head()  
      local _61 = head()   local _62 = head()   return (((_59.x < 1) or (_60.x >= (width - 1))) or ((_61.y < 1) or (_62.y >= (height - 1)))) end  

 function hit_self_question_() local ret = false 
      for _63 = 1,(#snake - 1) do local i = _63  local _64 = hit_question_(snake[i])  ret = ret or _64  end  
      return ret end  

 function detect_hit()  
      local _65 = hit_wall_question_()   local _66 = hit_self_question_()   if (_65 or _66) then state = "game-over"  end  
      local _67 = hit_question_(food)   
          if _67 then spawn_food()  score = score + 1  
          else cut()   end   end  

 function turn_left()  if (vx ~= 1) then vy,vx = 0, -1  end   end  
 function turn_right()  if (vx ~= -1) then vy,vx = 0, 1  end   end  
 function turn_up()  if (vy ~= 1) then vy,vx = -1, 0  end   end  
 function turn_down()  if (vy ~= -1) then vy,vx = 1, 0  end   end  


 input = nil 

 function control() 
      if 
      (input == "k") then turn_up()  
       elseif (input == "j") then turn_down()  
       elseif (input == "h") then turn_left()  
       elseif (input == "l") then turn_right()  
     end   end  

 function love.load()  
      local _68 = os.time()  math.randomseed(_68)   
     fullscr(true)  
     init()   end  

 function love.draw() 
      local _69, _70, _71 = green()  color(_69, _70, _71)  draw_snake()  
      local _72, _73, _74 = blue()  color(_72, _73, _74)  draw_cage()  
      local _75, _76, _77 = red()  color(_75, _76, _77)  draw_food()  
      local _78, _79, _80 = white()  color(_78, _79, _80)  draw_message()  
      local _81, _82, _83 = white()  color(_81, _82, _83)  draw_score()   end  

 function love.update(dt) 
     
      local _84 = refresh_question_(dt)   if ((state ~= "game-over") and _84) then 
         control()  
         advance()  
         detect_hit()  
         reset_timer()  
      end  
  end  
    
 function love.keypressed(key) 
      if 
        (key == "escape") then love.event.quit()  
         elseif (key == "space") then  if ("game-over" == state) then init()   end  
         elseif true then input = key 
     end  
  end  

  