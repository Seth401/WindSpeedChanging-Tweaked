data:extend(
    {
        {
            setting_type = "runtime-global",
            name = "WindSpeedChanging-Tweaked-seasonShortest",
            
            type = "int-setting",
            default_value = 30,
            minimum_value = 1,
        },
        {
            setting_type = "runtime-global",
            name = "WindSpeedChanging-Tweaked-seasonLongest",
            
            type = "int-setting",
            default_value = 3 * 60,
            minimum_value = 2,
        },
        {
            setting_type = "runtime-global",
            name = "WindSpeedChanging-Tweaked-windSpeedMin",
            
            type = "double-setting",
            default_value = 0,
            minimum_value = 0,
        },
        {
            setting_type = "runtime-global",
            name = "WindSpeedChanging-Tweaked-windSpeedMax",
            
            type = "double-setting",
            default_value = 0.2,
            minimum_value = 0,
        },
    }
)
