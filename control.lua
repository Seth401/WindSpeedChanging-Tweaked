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

-- get_values
-- The function returns a intermediate value for a given point
-- in time between pointA and pointB. Instead of using a simple average
-- the goal is to have a somewhat nicer curve that connects both points.
-- That way instead of having a zigzag change there is a gradual value change.
local function get_value (pointA, pointB)
  local duration = pointB.tick - pointA.tick -- Tick difference between points.
  local targetValue = pointB.value - pointA.value -- Value difference between points.
  local currentPosition = game.tick - pointA.tick -- Current position between points.
  local k = (currentPosition/duration) -- Percentage of progress.
  local phi = k*math.pi -- Percentage of PI for current value calculation.
  
  -- In order to have a smoothed out change a trigonomtry function is used as a base
  -- to "ride" on with the gradual calculation of the value for a given tick.
  -- The value that is being calculated is used as a precentage of the value difference
  -- between pointA and point B.
  -- The cosine will be between 1 and -1. By calculating 1-cos it's going to be between
  -- 0 and 2 and by dividing this by 2 it will be normalized to be between 0 and 1 and
  -- can be used a precentage.
  local p = targetValue*(1-math.cos(phi))/2

  return (pointA.value + p) -- Value for current position.
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
      local sign = (actual_wind_speed > max_speed and 1 or -1)
      
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
      local new_wind_speed = get_value (prelast_point, last_point)
      
      surface.wind_speed = new_wind_speed
    end
    
  end -- End of loop for surface
end -- End of on_nth_tick

script.on_nth_tick(60, on_nth_tick)