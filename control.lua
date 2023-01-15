local windSpeedMax = settings.global["WindSpeedChanging-Tweaked-windSpeedMax"].value
local windSpeedMin = settings.global["WindSpeedChanging-Tweaked-windSpeedMin"].value

-- Season length given in ticks. One tick is 1/60th of a second.
-- 1 = tick; 1*60 = one second; 1*60^2 = one minute; 1*60^3 = one hour
local seasonShortest = settings.global["WindSpeedChanging-Tweaked-seasonShortest"].value*60
local seasonLongest = settings.global["WindSpeedChanging-Tweaked-seasonLongest"].value*60

local varySurfaceSpeeds = settings.global["WindSpeedChanging-Tweaked-varySurfaceSpeeds"].value
local varySurfaceSpeedsCoefficient = settings.global["WindSpeedChanging-Tweaked-varyCoefficient"].value

local function calcSeasonLength(lengthMin, lengthMax)
    local durationVariance = (lengthMax-lengthMin) -- Difference between the min and max
    return lengthMin + math.ceil(durationVariance * (1-(1-math.random())^2))
end

local function initSurface(surface_name)
    -- If the surface hasn't been intialized yet define the basic structure.
    local surfaceWindSpeed = game.get_surface(surface_name).wind_speed
    local surfaceWindMin = windSpeedMin
    local surfaceWindMax = windSpeedMax
    
    if varySurfaceSpeeds == true then
        local surfaceWindMinLower = math.max(0, (windSpeedMin - (windSpeedMin * varySurfaceSpeedsCoefficient)))
        local surfaceWindMinUpper = math.max(0, (windSpeedMin + (windSpeedMin * varySurfaceSpeedsCoefficient)))
        surfaceWindMin = surfaceWindMinLower + (surfaceWindMinUpper-surfaceWindMinLower) * math.random()
        
        local surfaceWindMaxLower = math.max(0, (windSpeedMax - (windSpeedMax * varySurfaceSpeedsCoefficient)))
        local surfaceWindMaxUpper = math.max(0, (windSpeedMax + (windSpeedMax * varySurfaceSpeedsCoefficient)))
        surfaceWindMax = surfaceWindMaxLower + (surfaceWindMaxUpper-surfaceWindMaxLower) * math.random()
    end
    
    if not global.surfaceHandlers[surface_name] then
        global.surfaceHandlers[surface_name] = {
            windSpeedMin = surfaceWindMin,
            windSpeedMax = surfaceWindMax,
            sign = ( surfaceWindSpeed > surfaceWindMax and 1 or -1 ),
            points = {
                {tick = 0, value = surfaceWindSpeed},
                {tick = 1, value = surfaceWindSpeed}
            }
        }
    else
        global.surfaceHandlers[surface_name].windSpeedMin = surfaceWindMin
        global.surfaceHandlers[surface_name].windSpeedMax = surfaceWindMax
        global.surfaceHandlers[surface_name].sign = ( surfaceWindSpeed > surfaceWindMax and 1 or -1 )
    end
    
    -- game.print("Intialized Surface " .. surface_name .. " with max " .. surfaceWindMax .. " (" .. string.format("%.3f", (surfaceWindMax/windSpeedMax)*100) .. "%) and min " .. surfaceWindMin .. " (" .. string.format("%.3f", (surfaceWindMin/windSpeedMin)*100) .. "%) " .. (varySurfaceSpeeds == false and "and can't be varied" or "while it can be varied by " .. (varySurfaceSpeedsCoefficient*100) .. "%"))
end


local function onConfigurationChanged(event)
    local options = {
        "WindSpeedChanging-Tweaked-windSpeedMax",
        "WindSpeedChanging-Tweaked-windSpeedMin",
        "WindSpeedChanging-Tweaked-seasonShortest",
        "WindSpeedChanging-Tweaked-seasonLongest",
        "WindSpeedChanging-Tweaked-varySurfaceSpeeds",
        "WindSpeedChanging-Tweaked-varyCoefficient"
    }
    local foundOption = false
    
    for _,v in pairs(options) do
        if v == event.setting then
            foundOption = true
        end
    end
    
    if foundOption == false then
        return
    end
    
    -- This doesn't do anything yet.
    windSpeedMax = settings.global["WindSpeedChanging-Tweaked-windSpeedMax"].value
    windSpeedMin = settings.global["WindSpeedChanging-Tweaked-windSpeedMin"].value
    
    -- Season length given in ticks. One tick is 1/60th of a second.
    -- 1 = tick; 1*60 = one second; 1*60^2 = one minute; 1*60^3 = one hour
    seasonShortest = settings.global["WindSpeedChanging-Tweaked-seasonShortest"].value*60
    seasonLongest = settings.global["WindSpeedChanging-Tweaked-seasonLongest"].value*60
    
    varySurfaceSpeeds = settings.global["WindSpeedChanging-Tweaked-varySurfaceSpeeds"].value
    varySurfaceSpeedsCoefficient = settings.global["WindSpeedChanging-Tweaked-varyCoefficient"].value
    
    for surfaceName, _ in pairs(game.surfaces) do
        initSurface(surfaceName)
        
        local handler = global.surfaceHandlers[surfaceName]
        
        for i, point in ipairs(handler.points) do
            if point.value > windSpeedMax then
                handler.points[i].value = windSpeedMax
            end
            
            if point.value < windSpeedMin then
                handler.points[i].value = windSpeedMin
            end
        end
        
        global.surfaceHandlers[surfaceName] = handler
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
    
    for surfaceName, _ in pairs (game.surfaces) do
        initSurface(surfaceName)
    end
end

-- getValue
-- The function returns a intermediate value for a given point
-- in time between pointA and pointB. Instead of using a simple average
-- the goal is to have a somewhat nicer curve that connects both points.
-- That way instead of having a zigzag change there is a gradual value change.
local function getValue (pointA, pointB)
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
    for surfaceName, surface in pairs (game.surfaces) do
        local handler = global.surfaceHandlers[surfaceName]
        
        if handler.points[2].tick <= tick then
            -- End of the last defined season has been reached
            
            local windSpeedCurrent = surface.wind_speed
            local sign = -handler.sign
            local valueNext = nil
            local rnd = math.random()
            local windChange
            local seasonLength = calcSeasonLength (seasonShortest, seasonLongest)
            local tickFuture = tick + seasonLength
            
            handler.sign = sign
            
            if sign > 0 then -- trending towards windSpeedMax
                windChange = (rnd^2) * (handler.windSpeedMax - windSpeedCurrent)
                valueNext = windSpeedCurrent + windChange
            else -- trending towards windSpeedMin
                windChange = (rnd^2) * (windSpeedCurrent - handler.windSpeedMin)
                valueNext = windSpeedCurrent - windChange
            end
            
            -- Update the last element
            handler.points[1] = handler.points[2]
            handler.points[2] = {tick = tickFuture, value = valueNext}
            
            -- game.print("New Season with a length of " .. (math.ceil(seasonLength/60)) ..    " s for surface " .. surfaceName .. " between " .. handler.windSpeedMin .. " and " .. handler.windSpeedMax .. " target " .. string.format("%.3f", ((valueNext/handler.windSpeedMax)*100)) .. "%")
        end
        
        local pointsPrevious = handler.points[1]
        local     pointsLast = handler.points[2]
        local   windSpeedNew = getValue (pointsPrevious, pointsLast)
        surface.wind_speed = windSpeedNew
        
        -- game.print("Remaining time for season " .. (math.ceil((pointsLast.tick - game.tick)/60)) .. " s, current wind " .. string.format("%.3f", ((surface.wind_speed/handler.windSpeedMax)*100)) .. "%")
        
    end -- End of loop for surface
end -- End of on_nth_tick

commands.add_command("wind_information", nil, function(command)
    for surfaceName, surface in pairs (game.surfaces) do
        if not global.surfaceHandlers[surfaceName] then
            game.print(("Surface " .. surfaceName .. " doesn't have a handler."))
        else
            local handler = global.surfaceHandlers[surfaceName]
            
            game.print(
                "Surface " .. surfaceName ..
                " does have a min of " .. handler.windSpeedMin .. " (" .. string.format("%.3f",(handler.windSpeedMin/windSpeedMin)*100) .. "%)" ..
                " a max of " .. handler.windSpeedMax  .. " (" .. string.format("%.3f",(handler.windSpeedMax/windSpeedMax)*100) .. "%)" ..
                " currently trending towards " .. (handler.sign > 0 and "max, " or "min, ") .. 
                " current speed is " .. string.format("%.3f",(surface.wind_speed/handler.windSpeedMax)*100) .. "% of max" ..
                " current season runs another " .. (math.ceil((handler.points[2].tick - game.tick)/60)) .. "s"
            )
        end
    end
end)

script.on_init(onInit)
script.on_nth_tick(60, onNthTick)

-- script.on_configuration_changed(onConfigurationChanged)
script.on_event(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

script.on_event(defines.events.on_surface_created, onSurfaceCreated)
script.on_event(defines.events.on_surface_imported, onSurfaceImported)
script.on_event(defines.events.on_surface_renamed, onSurfaceRenamed)