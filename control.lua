local function prob_low (value)
  return value^2
end

local function prob_high (value)
  return (1-(1-value)^2)
end

local function get_season_length (shortest_season, longest_season, speed_rnd)
  local rnd_high = prob_high (speed_rnd)
  return (math.ceil((shortest_season + rnd_high*(longest_season-shortest_season))/60)*60)
end

local function get_value (point_1, point_2, tick)
  local length = point_2.tick - point_1.tick -- Tick difference between points.
  local high = point_2.value - point_1.value -- Value difference between points.
  local t = tick - point_1.tick -- Current position between points.
  local k = (t/length) -- Percentage of progress.
  local phi = k*math.pi -- Percentage of PI for current value calculation.
  local p = high*(1-math.cos(phi))/2 -- Percentage of value difference between points at current position.
  local result = (point_1.value + p) -- Value for current position.
  return result
end

local function on_nth_tick ()
  -- Mod hasn't been intialized
  if not global.surface_handlers then
    global.surface_handlers = {}
  end
  
  local tick = game.tick
  local max_speed = 0.2 -- really high speed, default surface speed is 0.02
  local min_speed = 0
  
  -- Season length given in ticks. One tick is 1/60th of a second.
  -- 1 = tick; 1*60 = one second; 1*60^2 = one minute; 1*60^3 = one hour
  local shortest_season = 20*60
  local longest_season =   3*60^2
  
  -- Iterate all surfaces and modify wind_speed on each surface.
  for surface_name, surface in pairs (game.surfaces) do
    -- If the surface hasn't been intialized yet define the basic structure.
    if not global.surface_handlers[surface_name] then
      global.surface_handlers[surface_name] = {min_speed = min_speed, max_speed = max_speed}
    end

    local handler = global.surface_handlers[surface_name]
    
    if not handler.sign then
      -- If the surface hasn't been modified since it's been intialized
      
      local season_length = math.ceil(math.random (shortest_season, longest_season)/60)*60 -- in ticks
      local till_tick = tick + season_length
      local actual_wind_speed = surface.wind_speed
      local next_point_value
      local rnd = math.random()
      local sign = 1
      if actual_wind_speed > max_speed then sign = -1 end

      if sign > 0 then -- trending towards max_speed
        next_point_value = actual_wind_speed + rnd * (max_speed - actual_wind_speed) 
      else  -- trending towards min_speed
        next_point_value = actual_wind_speed - rnd * (actual_wind_speed - min_speed) 
      end

      handler.sign = sign
      handler.points = {{tick = tick, value = actual_wind_speed}, {tick = till_tick, value = next_point_value}}
      handler.wait_for_tick = till_tick
      
    elseif handler.wait_for_tick <= tick then
      -- End of the last defined season has been reached
      
      local actual_wind_speed=surface.wind_speed
      local sign = -handler.sign
      local next_point_value
      local rnd = math.random()
      local wind_changing
      local season_length = get_season_length (shortest_season, longest_season, rnd)
      local till_tick = tick + season_length
      
      handler.sign = sign
      handler.wait_for_tick = till_tick
      
      if sign > 0 then -- trending towards max_speed
        wind_changing = prob_low (rnd) * (max_speed - actual_wind_speed)
        next_point_value = actual_wind_speed + wind_changing
      else -- trending towards min_speed
        wind_changing = prob_low (rnd) * (actual_wind_speed - min_speed)
        next_point_value = actual_wind_speed - wind_changing
      end
      
      -- Add season to the list of seasons so far
      table.insert (handler.points, {tick = till_tick, value = next_point_value})
      
    else
      -- Season is in progress
      
      local points_amount = #handler.points -- Length of points table
      local prelast_point = handler.points[points_amount-1]
      local    last_point = handler.points[points_amount]
      local new_wind_speed = get_value (prelast_point, last_point, tick)
      
      surface.wind_speed = new_wind_speed
    end
    
  end -- End of loop for surface
end -- End of on_nth_tick

script.on_nth_tick(60, on_nth_tick)