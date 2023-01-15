# Wind Speed Changing (Tweaked) #

Ever wondered what being on the surface would feel like? Right now it would be a constant breeze making sure that your hair nicely blows in the air.

What if we could change that? This mod is a modified version of [WindSpeedChanging by darkfrei](https://mods.factorio.com/mod/WindSpeedChanging) which makes most of its aspect configurable and also adds some more features.

This means that rather than constant breeze there will be a more dynamic surface wind on Nauvis and other surfaces added by mods. In comparison to the original version the defaults should bring it more inline with the vanilla breeze. The original version by darkfrei set an upper limit that was 10 times higher than the vanilla breeze.

If you want to get some details on how strong wind is blowing you can use the command `/wind_information` to get an overview.

## What do I use it for? ###

You could use it purefly for aestethics as it will influence how fast clouds are moving as well as how far smoke from e.g. your power generation or fires is being blown but the real goal is to use a mod that adds some form of wind turbine and have it be a bit more dynamic.

Mods that are currently able to do this include:

- [Vertical Axis Wind Turbines by darkfrei](https://mods.factorio.com/mod/VerticalAxisWindTurbines)
- [Wind Turbines 2 Configurable Power by ethanatos](https://mods.factorio.com/mod/windturbines-2-configurable-power)
- [Wind Turbines 2 by majuss](https://mods.factorio.com/mod/windturbines-2)

## Details ##

Just like the original version this mod uses seasons or rather periods to gradually change how strong the wind is blowing. They have a random duration that is configurable and will vary speed beteween the minimum and maximum that's set for a surface.

A season sets a goal and afterwards a function is used to approach it. Upon reaching a season end a new goal is generator and again the function continues to trend towards it.

## Incompatabilities ##

Mods that also try to modify `wind_speed` for surfaces will at the very least lead to some unforseen consequences. One such mod is the original [Wind Turbines by OwnlyMe](https://mods.factorio.com/mod/windturbines). The Wind Turbines 2 versinos listed above remove the problematic code segment and do have an implict reliance on mod that changes `surface_wind`. One option for this is this mod.

## Future ##

In the future I'd like to add a remote interface so other mods can set limits on how strong the wind should be on a surface and/or also either a commandline interface or GUI to configure limits manually. Right now they're randomized on creation and configuration change.