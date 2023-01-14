local windSpeedMax = settings.global["WindSpeedChanging-Tweaked-windSpeedMax"].value
local windSpeedMin = settings.global["WindSpeedChanging-Tweaked-windSpeedMin"].value

-- Season length given in ticks. One tick is 1/60th of a second.
-- 1 = tick; 1*60 = one second; 1*60^2 = one minute; 1*60^3 = one hour
local seasonShortest = settings.global["WindSpeedChanging-Tweaked-seasonShortest"].value*60
local seasonLongest = settings.global["WindSpeedChanging-Tweaked-seasonLongest"].value*60

local function calcSeasonLength(shortest_season, longest_season, speed_rnd)
  local rnd_high = (1-(1-speed_rnd)^2)
  return (math.ceil((shortest_season + rnd_high*(longest_season-shortest_season))/60)*60)
end

local function onConfigurationChanged()
  -- This doesn't do anything yet.
  windSpeedMax = settings.global["WindSpeedChanging-Tweaked-windSpeedMax"].value
  windSpeedMin = settings.global["WindSpeedChanging-Tweaked-windSpeedMin"].value

  -- Season length given in ticks. One tick is 1/60th of a second.
  -- 1 = tick; 1*60 = one second; 1*60^2 = one minute; 1*60^3 = one hour
  seasonShortest = settings.global["WindSpeedChanging-Tweaked-seasonShortest"].value*60
  seasonLongest = settings.global["WindSpeedChanging-Tweaked-seasonLongest"].value*60
end

local function initSurface(surface_name)
  -- If the surface hasn't been intialized yet define the basic structure.
  if not global.surfaceHandlers[surface_name] then
    global.surfaceHandlers[surface_name] = {min_speed = windSpeedMin, max_speed = windSpeedMax}
  else
    return
  end

  local handler = global.surfaceHandlers[surface_name]

  if not handler.sign then
    -- If the surface hasn't been modified since it's been intialized
    
    local season_length = math.ceil(math.random (seasonShortest, seasonLongest)/60)*60 -- in ticks
    local till_tick = game.tick + season_length
    local actual_wind_speed = game.get_surface(surface_name).wind_speed
    local next_point_value
    local rnd = math.random()
    local sign = (actual_wind_speed > windSpeedMax and 1 or -1)
    
    if sign > 0 then -- trending towards max_speed
      next_point_value = actual_wind_speed + rnd * (windSpeedMax - actual_wind_speed)
    else  -- trending towards min_speed
      next_point_value = actual_wind_speed - rnd * (actual_wind_speed - windSpeedMin)
    end
    
    handler.sign = sign
    handler.points = {{tick = game.tick, value = actual_wind_speed}, {tick = till_tick, value = next_point_value}}
    handler.wait_for_tick = till_tick
    
  end
end

local function onSurfaceCreated(event)
  initSurface(game.get_surface(event.surface_index).name)
end

local function onSurfaceImported(event)
  if global.surfaceHandlers[event.original_name] then
    global.surfaceHandlers[game.get_surface(event.surface_index).name] = global.surfaceHandlers[event.original_name]
  else
    initSurface(game.get_surface(event.surface_index).name)
  end
end

local function onSurfaceRenamed(event)
  if global.surfaceHandlers[event.old_name] then
    global.surfaceHandlers[event.new_name] = global.surfaceHandlers[event.old_name]
  else
    initSurface(event.new_name)
  end
end

local function onInit()
  -- Mod hasn't been intialized
  if not global.surfaceHandlers then
    global.surfaceHandlers = {}
  end

  for surface_name, surface in pairs (game.surfaces) do
    initSurface(surface_name)
  end
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

local function onNthTick ()
  local tick = game.tick
  
  -- Iterate all surfaces and modify wind_speed on each surface.
  for surface_name, surface in pairs (game.surfaces) do
    local handler = global.surfaceHandlers[surface_name]
    
    if handler.wait_for_tick <= tick then
      -- End of the last defined season has been reached
      
      local actual_wind_speed=surface.wind_speed
      local sign = -handler.sign
      local next_point_value
      local rnd = math.random()
      local wind_changing
      local season_length = calcSeasonLength (seasonShortest, seasonLongest, rnd)
      local till_tick = tick + season_length
      
      handler.sign = sign
      handler.wait_for_tick = till_tick
      
      if sign > 0 then -- trending towards max_speed
        wind_changing = (rnd^2) * (windSpeedMax - actual_wind_speed)
        next_point_value = actual_wind_speed + wind_changing
      else -- trending towards min_speed
        wind_changing = (rnd^2) * (actual_wind_speed - windSpeedMin)
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

script.on_init(onInit)
script.on_nth_tick(60, onNthTick)

script.on_configuration_changed(onConfigurationChanged)
script.on_event(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

script.on_event(defines.events.on_surface_created, onSurfaceCreated)
script.on_event(defines.events.on_surface_imported, onSurfaceImported)
script.on_event(defines.events.on_surface_renamed, onSurfaceRenamed)