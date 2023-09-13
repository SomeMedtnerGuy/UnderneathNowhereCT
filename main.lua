function love.load()
  require "levels"
  
  music1 = love.audio.newSource("assets/level1.wav", "stream")
  music2 = love.audio.newSource("assets/level2.wav", "stream")
  music3 = love.audio.newSource("assets/level3.wav", "stream")
  music4 = love.audio.newSource("assets/rest_of_game.wav", "stream")

  -- Several basic settings
  love.window.setMode(1280, 720)
  window_width = love.graphics.getWidth()
  window_height = love.graphics.getHeight()
  title_font = love.graphics.newFont(40)
  main_font = love.graphics.newFont(16)
  
  gamestate = "start"
  
  -- Keeps track of level progress
  progress = {}
  for i,v in pairs(level_list) do
    table.insert(progress, false)
  end
  
  levels_start_pos = {}
  levels_start_pos[1] = {start_x = 3, start_y = 9, start_z = 1, start_w = 1}
  levels_start_pos[2] = {start_x = 10, start_y = 9, start_z = 1, start_w = 1}
  levels_start_pos[3] = {start_x = 7, start_y = 13, start_z = 1, start_w = 1}
  levels_start_pos[4] = {start_x = 7, start_y = 13, start_z = 1, start_w = 1}
  levels_start_pos[5] = {start_x = 6, start_y = 7, start_z = 1, start_w = 1}
  levels_start_pos[6] = {start_x = 3, start_y = 13, start_z = 1, start_w = 1}
  
  w_colors = {
    {1, 1, 1},
    {1, 0, 0},
    {0, 1, 0},
    {0, 0, 1}
  }
  
  current_level = 1
  
  -- Keeps track of which rooms of the level the player has already visited (to draw the map dinamically)
  mapview = {}
  for i,level in pairs(level_list) do
    mapview[i] = {}
    for j,w in pairs(level) do
      mapview[i][j] = {}
      for k,z in pairs(w) do
        mapview[i][j][k] = false
      end
    end
  end
  
  -- A few miscellaneous variables for various individual events of the game
  key_needed_timer = 0
  tutorial_done_timer = 0
  player_moved = false
  player_on_key = false
  
  -- Variables for level 3-4 transition
  fade_timer = 0
  alpha = 0
  fade_in = 0.70
  display = 2.90
  fade_out = 3.65
  text_list = {
    "So far, so good...",
    "But now, buckle up.",
    "Because things are about to get...",
    "... interesting.",
    "x: ",
    "x:   y: ",
    "x:   y:   z: ",
    "x:   y:   z:   w: "
  }
  current_text = 1
  
  -- World graphics
  local tileset_image = love.graphics.newImage("assets/completetileset.png")
  tileset = {
    image = tileset_image,
    width = tileset_image:getWidth(),
    height = tileset_image:getHeight(),
    tile_width = 32,
    tile_height = 32,
    ground = 1,
    solid = 2,
    stairs_up = 3,
    stairs_down = 4,
    key = 5,
    keyhole = 14
  }
  
  quads = {}
  for i=0,1 do
    for j=0,7 do
      table.insert(quads, love.graphics.newQuad(j * tileset.tile_width, i * tileset.tile_height, tileset.tile_width,        tileset.tile_height, tileset.width, tileset.height))
    end
  end
  
  -- Background canvas, filled just with the "ground" quad. The reason is that not only reduces the number of things to draw, but also because the "stairs up" would have a black background if each quad was drawed individually, which would make them almost impossible to distinguish from the "stairs down" quad".
  canvas = love.graphics.newCanvas()
  love.graphics.setCanvas(canvas)
  for i=1,17 do
    for j=1,20 do
      love.graphics.draw(tileset.image, quads[1], j * tileset.tile_width, i * tileset.tile_height)
    end
  end
  love.graphics.setCanvas()
  
  --Player info
  player = {
    image = love.graphics.newImage("assets/player.png"),
    pos_x = nil, -- By multiplying these values by width/height, we get the position of a specific tile.
    pos_y = nil,
    pos_z = nil,
    pos_w = nil,
    width = 32,
    height = 32,
    orientation = 0, -- Value to be multiplied by pi when player drawn.
    key = false
  }
end

function love.update(dt)
  -- Sets dinamic soundtrack
  if current_level == 1 then
    if not music1:isPlaying() then
      music1:play()
    end
  elseif current_level == 2 then
    if not music1:isPlaying() and not music2:isPlaying() then
      music2:play()
    end
  elseif current_level == 3 then
    if not music2:isPlaying() and not music3:isPlaying() then
      music3:play()
    end
  elseif awesome_drop then
    if not music4:isPlaying() then
      music3:stop()
      music4:play()
    end
  end
  
  -- Uses progress tracker to define which level should be active.
  if gamestate == "start" or gamestate == "play_next" then
    for level,v in pairs(progress) do
      if progress[level] == false then
        world = level_list[level]
        current_level = level
        break
      end
    end
    -- Definition of the revelation of the main mechanic (4d movement) from level 3 to 4
  elseif gamestate == "badass transition" then
    fade_timer = fade_timer + dt
    if fade_timer < fade_in then 
      alpha = fade_timer/fade_in
    elseif fade_timer < display then 
      alpha = 1
    elseif fade_timer < fade_out then 
      alpha = 1 - ((fade_timer-display)/(fade_out-display))
    else 
      alpha = 0
      current_text = current_text + 1
      fade_timer = 0
      if current_text == 5 then
        fade_in = 0
        display = 3.65
        fade_out = 3.65
      elseif current_text == 7 then
        display = 7.45
        fade_out = 7.45
      elseif current_text == 8 then
        display = 1.85
        fade_out = 1.85
      elseif text_list[current_text] == nil then
        gamestate = "level"
      end
    end
  end
  
  -- Defines wether the message to teach about the coordinate notation/how to pick up the key should be on
  if current_level == 1 then
    if player.pos_x == 4 then
      player_moved = true
    end
    if player.pos_x == 12 then
      player_on_key = true
    end
  end
  
  
  -- Tells love.draw for how long to show message in case player tries to open the door without the key 
  if key_needed then
    key_needed_timer = key_needed_timer + dt
    if key_needed_timer > 3 then
      key_needed = false
    end
  end
  
  -- Defines temporary message telling the player he/she is done with the tutorial
  if current_level == 5 and gamestate == "level" then
    tutorial_done_timer = tutorial_done_timer + dt
    if tutorial_done_timer < 6 then
      tutorial_done_message = "You have all the knowledge you need to navigate through this 4 dimentional world. Good luck!!"
    else
      tutorial_done_message = false
    end
  end
end


function love.draw()
  -- Draws titlescreen
  if gamestate == "start" then
    love.graphics.setFont(title_font)
    love.graphics.printf("Underneath Nowhere (CT)", 0, 200, window_width, "center")
    love.graphics.draw(player.image, window_width/2, window_height/2, math.pi/8, 3, 3, 16, 16) 
    love.graphics.setFont(main_font)
    love.graphics.printf("press 'Space' to start", 0, 600, window_width, "center")
    love.graphics.printf("Made by: Nuno Ventura de Sousa (Valongo, Portugal)", 0, 680, window_width, "center")

  -- Draws each set of instructions for each tutorial level
  elseif gamestate == "level" then
    if current_level == 1 then
      love.graphics.printf("Welcome to 'Underneath Nowhere (CT)'! Your objective in each level is to collect the key and exit through the door.", (window_width/3)*2, 50, window_width/3 - 50, "right") 
      love.graphics.printf("Use the right/left arrow keys to move yourself horizontally.", (window_width/3)*2, 125, window_width/3 - 50, "right")
      if player_moved then
        love.graphics.printf("You will notice that your x coordinate value is displayed (and constantly updated) on the bottom-left corner. Might be useful later...", (window_width/3)*2, 175, window_width/3 - 50, "right")
      end
      if player_on_key then
        love.graphics.printf("To pick up keys (or open doors), use the 'Space'... key.", (window_width/3)*2, 300, window_width/3 - 50, "right")
      end
    elseif current_level == 2 then
      love.graphics.printf("Use the up/down arrow keys to move yourself vertically. Your y position is also now available to you.", (window_width/3)*2, 50, window_width/3 - 50, "right")
    elseif current_level == 3 then
      love.graphics.printf("You can use the 'Space' key to go up and down the stairs. Your z coordinate indicates which floor you are on. You also have a map to help you out on your navigation", (window_width/3)*2, 50, window_width/3 - 50, "right")
    elseif current_level == 4 then
      love.graphics.printf("It is possible to move along the w axis (4th dimention) the same way you can move along the z axis. The diference is that, while to change z coordinate you would have to find a hole in the ceiling (or floor) to pass through (using stairs), to change w coordinate, you have to find a hole in the 4th dimention's walls.", (window_width/3)*2, 50, window_width/3 - 50, "right")
      love.graphics.printf("The evidence of such occurrence is in the light. A distinct light color emanates from each 'floor' in the w axis (W-floor), and whenever there is a hole in the wall, light passes through and can be seen in the current W-floor.", (window_width/3)*2, 200, window_width/3 - 50, "right")
      love.graphics.printf("To pass through that hole, just place yourself where the light from a different W-floor shines on and press 'space' to move to it.", (window_width/3)*2, 350, window_width/3 - 50, "right")
    end
    
    if tutorial_done_message then
      love.graphics.printf(tutorial_done_message, 0, window_height - 100, window_width, "center")
    end
    
    -- Draws world map, setting first the color of the W-floor the player can travel to (if that is the case). The number 1 is the tile used for the ground the different W-floors have in common. 
    love.graphics.setColor(w_colors[player.pos_w])
    love.graphics.draw(canvas)
    for i,row in ipairs(world[player.pos_w][player.pos_z]) do
      for j,tile in ipairs(row) do
        if tile ~= 0  then
          if world[player.pos_w + 1] ~= nil then
            if world[player.pos_w][player.pos_z][i][j] == 1 and world[player.pos_w + 1][player.pos_z][i][j] == 1 then
              love.graphics.setColor(w_colors[player.pos_w + 1])
            end
          end
          if world[player.pos_w - 1] ~= nil then
            if world[player.pos_w][player.pos_z][i][j] == 1 and world[player.pos_w - 1][player.pos_z][i][j] == 1 then
              love.graphics.setColor(w_colors[player.pos_w - 1])
            end
          end
          love.graphics.draw(tileset.image, quads[tile], j * tileset.tile_width, i * tileset.tile_height)
          love.graphics.setColor(w_colors[player.pos_w])
        end
      end
    end
    -- Draws player. In order for the offset be in the center to allow rotation, I must calculate first which tile the player should be in, and then add the offset value.
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(player.image, (player.pos_x * tileset.tile_width) + player.width/2, (player.pos_y * tileset.tile_height) + player.height/2, player.orientation * math.pi, 1, 1, player.width/2, player.height/2)
    -- Draws coordinate indications
    love.graphics.print("x: " .. player.pos_x, 50, window_height - 50)
    if current_level >= 2 then
      love.graphics.print("y: " .. player.pos_y, 150, window_height - 50)
    end
    if current_level >= 3 then
      love.graphics.print("z: " .. player.pos_z, 250, window_height - 50)
    end
    if current_level >= 4 then
      love.graphics.print("w: " .. player.pos_w, 350, window_height - 50)
    end
    
    -- Draws minimap
    if current_level >= 3 then
      for j,row in ipairs(world) do
        for i, tile in ipairs(row) do
          for k in pairs(w_colors) do
            if j == k then
              love.graphics.setColor(w_colors[k])
            end
          end
          if player.pos_z == i and player.pos_w == j and mapview[current_level][j][i] == true then
            love.graphics.rectangle("fill", 700 + (j * 50), 50 + (window_height - 300 - (i * 40)), 75, 40)
          elseif mapview[current_level][j][i] == true then
            love.graphics.rectangle("line", 700 + (j * 50), 50 + (window_height - 300 - (i * 40)), 75, 40)
          end
        end
      end
    end
    love.graphics.setColor(1, 1, 1)
    
    --  Draws various messages for different cases
    if key_needed then
      love.graphics.printf("You need a key to unlock this door!", 0, window_height - 50, window_width, "center")
    end
    if player.key then
      love.graphics.printf("You have a key", 0, window_height - 50, window_width - 50, "right")
    end
    
    -- Draws the different between-levels-screens
  elseif gamestate == "play_next" then
    if progress[6] == true then
      love.graphics.printf("Thanks for playing 'Underneath Nowhere (concept test)'! I hope you enjoyed your time and the general concept, as testing its fun was the main objective of this project!! Perhaps a full game is on the horizon... for now, have a great day!!! (Presss 'space' to exit)", window_width/4, window_height/2, window_width/2, "center")
    else
      love.graphics.print("Level " .. current_level - 1 .. " completed!", 400, 200)
      love.graphics.print("Press 'Space' key to go to next level", 400, 300)
    end
  elseif gamestate == "badass transition" then
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(text_list[current_text], 0, window_height/2, window_width, "center") 
  end
end

-- Handles input for different between-levels-screens
function love.keypressed(key)
  if gamestate == "start" or gamestate == "play_next" then
    if key == "space" then
      level_prep()
      if current_level == 4 then
        awesome_drop = true
        gamestate = "badass transition"
      elseif progress[6] == true then
        love.event.quit()
      else
        gamestate = "level"
      end
    end
  elseif gamestate == "badass transition" then
    if key == "space" then
      gamestate = "level"
    end
  
  --Handles input during levels. The input is reflected to temporary coordinates and in the end it is checked if it is actually possible for the player to move there.
  elseif gamestate == "level" then
    local x = player.pos_x
    local y = player.pos_y
    local z = player.pos_z
    local w = player.pos_w
    if key == "left" then
      x = x - 1
      player.orientation = -0.5
    elseif key == "right" then
      x = x + 1
      player.orientation = 0.5
    elseif key == "up" then
      y = y - 1
      player.orientation = 0
    elseif key == "down" then
      y = y + 1
      player.orientation = 1
    end
    
    if key == "space" then
      if world[w][z][y][x] == tileset.key then
        player.key = true
        world[w][z][y][x] = 0
      elseif world[w][z][y][x] == tileset.keyhole then
        if player.key == true then
          progress[current_level] = true
          gamestate = "play_next"
        else
          key_needed_timer = 0
          key_needed = true
        end
      elseif world[w][z][y][x] == tileset.stairs_up then
        z = z + 1
      elseif world[w][z][y][x] == tileset.stairs_down then
        z = z - 1
      end
      
      -- All these different cases are necessary because any other configuration (that I can think of) would lead to an attempt to index a nill value (because players might be on an W-floor that doesnt have any below or above him/her).
      if world[w + 1] ~= nil and world[w - 1] ~= nil then
        if world[w][z][y][x] == world[w + 1][z][y][x] and world[w][z][y][x] == 1 then
          w = w + 1
        elseif world[w][z][y][x] == world[w - 1][z][y][x] and world[w][z][y][x] == 1 then
          w = w - 1
        end
      elseif world[w + 1] ~= nil then
        if world[w][z][y][x] == world[w + 1][z][y][x] and world[w][z][y][x] == 1 then
          w = w + 1
        end
      elseif world[w - 1] ~= nil then
        if world[w][z][y][x] == world[w - 1][z][y][x] and world[w][z][y][x] == 1 then
          w = w - 1
        end
      end
    end
    
    if isEmpty(x, y, z, w) then
      player.pos_x = x
      player.pos_y = y
      player.pos_z = z
      player.pos_w = w
      -- To make that room of the minimap visible
      mapview[current_level][w][z] = true
    end
  end  
end
-- Check if new coordinate is not stone
function isEmpty(x, y, z, w)
  return world[w][z][y][x] ~= 2
end
-- Prepares player for next level, taking key away and putting it in corresponding coordinates
function level_prep()
  player.key = false
  player.pos_x = levels_start_pos[current_level].start_x
  player.pos_y = levels_start_pos[current_level].start_y
  player.pos_z = levels_start_pos[current_level].start_z
  player.pos_w = levels_start_pos[current_level].start_w
end  