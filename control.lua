function prob_low (value)
  return value^2
end


function prob_high (value)
  return (1-(1-value)^2)
end


function get_season_length (shortest_season, longest_season, speed_rnd)
  -- local rnd_high = 1-(1-math.random())*(1-speed_rnd)
  local rnd_high = prob_high (speed_rnd)
  return (math.ceil((shortest_season + rnd_high*(longest_season-shortest_season))/60)*60)
end


function get_value (point_1, point_2, tick)
  local lenght = point_2.tick - point_1.tick -- positive
  -- game.print ('lenght: ' .. lenght)
  local high = point_2.value - point_1.value -- positive or negative
  -- game.print ('high: ' .. high)
  local t = tick - point_1.tick
  -- game.print ('t: ' .. t)
  local k = (t/lenght)
  -- game.print ('k: ' .. k)
  local phi = k*math.pi
  -- game.print ('phi: ' .. phi)
  local p = high*(1-math.cos(phi))/2
  -- game.print ('p: ' .. p)
  local result = (point_1.value + p)
  -- game.print ('result: ' .. result)
  
  
  return result
end

function on_nth_tick ()
  if not global.surface_handlers then global.surface_handlers = {} end
  local tick = game.tick
  
  local max_speed = 0.2 -- really high speed
  local min_speed = 0
  
  local shortest_season = 20*60   -- 20 seconds
  -- local shortest_season = 5*60 -- 10 seconds ; 1 = tick; 1*60 = one second; 1*60^2 = one minute; 1*60^3 = one hour
  -- local longest_season =   2*60^2 -- two minutes
  -- local longest_season =   5*60^2 -- five minutes
  local longest_season =   3*60^2 -- three minutes
  -- local longest_season = 20*60 -- 20 seconds
  
  for surface_name, surface in pairs (game.surfaces) do
    if not global.surface_handlers[surface_name] then global.surface_handlers[surface_name] = {min_speed = min_speed, max_speed = max_speed} end
    local handler = global.surface_handlers[surface_name]
    if not handler.sign then
      -- first start
      local season_length = math.ceil(math.random (shortest_season, longest_season)/60)*60 -- in ticks
      local till_tick = tick + season_length
      local actual_wind_speed = surface.wind_speed
      local sign = 1
      if actual_wind_speed > max_speed then sign = -1 end
      -- game.print ('sign = ' .. sign )
      local next_point_value
      local rnd = math.random()
      if sign > 0 then -- goes up
        -- game.print ('actual_wind_speed = ' .. actual_wind_speed .. ' rnd = ' .. rnd .. ' max_speed = ' .. max_speed)
        next_point_value = actual_wind_speed + rnd * (max_speed - actual_wind_speed) 
        -- game.print ('next_point_value = ' .. next_point_value)
      else  -- goes down
        next_point_value = actual_wind_speed - rnd * (actual_wind_speed - min_speed) 
      end
      -- game.print ('season: ' .. (season_length/60) .. ' seconds; next value: ' .. next_point_value)
      handler.sign = sign
      handler.points = {{tick = tick, value = actual_wind_speed}, {tick = till_tick, value = next_point_value}}
      handler.wait_for_tick = till_tick
      
    elseif handler.wait_for_tick <= tick then
      -- new point

      local actual_wind_speed=surface.wind_speed
      local sign = -handler.sign
      local next_point_value
      local rnd = math.random()
      local wind_changing
      
      if sign > 0 then -- goes up
        wind_changing = prob_low (rnd) * (max_speed - actual_wind_speed)
        next_point_value = actual_wind_speed + wind_changing
      else -- goes down
        wind_changing = prob_low (rnd) * (actual_wind_speed - min_speed)
        next_point_value = actual_wind_speed - wind_changing
        wind_changing = -wind_changing -- just for direction
      end
      
      -- game.print ('season: ' .. (season_length/60) .. ' seconds; next value: ' .. next_point_value)
      handler.sign = sign
      
      -- local season_length = math.ceil(math.random (shortest_season, longest_season)/60)*60 -- in ticks
      local season_length = get_season_length (shortest_season, longest_season, rnd)
      
      -- game.print ('season_length: ' .. (season_length/60) .. ' s, wind_changing: ' .. wind_changing)
      
      local till_tick = tick + season_length
      
      table.insert (handler.points, {tick = till_tick, value = next_point_value})
      handler.wait_for_tick = till_tick
      
    else
      -- change the wind
      local points_amount = #handler.points
      local prelast_point = handler.points[points_amount-1]
      local    last_point = handler.points[points_amount]
      local new_wind_speed = get_value (prelast_point, last_point, tick)
      -- game.print ('new_wind_speed: ' .. new_wind_speed .. ' and goes to ' .. last_point.value .. ' next update after ' .. ((last_point.tick-tick)/60) .. ' seconds')
      surface.wind_speed = new_wind_speed
    end
    
  end
end

script.on_nth_tick(60, on_nth_tick)