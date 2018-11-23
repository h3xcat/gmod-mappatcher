# mappatcher-gmod
An easy-to-use tool which allows server staff to patch various exploits within maps.
Multiple exploits exist in maps that allow players to get out of the map when they're not supposed to. This tool allows for server staff to patch such exploits in less than a minute. Aside from exploit patching, this tool also allows you to block off parts of a map using forcefields, or setup teleport points, making your map one of a kind.

## Steam Workshop

https://steamcommunity.com/sharedfiles/filedetails/?id=1572250342

## Video Demo
https://www.youtube.com/watch?v=48pFpVRVkpY

## Features

* Ability to view map playerclip brushes, makes finding map exploits 100 times easier.
* No resource files, meaning no impact on download time on join. The textures are generated through Lua.
* Gamemode independent tool, should work with most gamemodes.

## Available Brush Types

* **Player Clip** - Collides with players but nothing else.
* **Hurt** - Damages players over time, various time intervals are customizable through the menu.
* **Kill** - Kills anyone on touch.
* **Remove** - Removes any entities that touches it.
* **Force Field** - Clip with sound and texture.
* **Teleport** - Teleport player to given destination.
* **Bullet Clip** - Blocks bullets but nothing else.
* **Prop Clip** - Blocks props.
* **Clip** - Blocks everything.

## Commands

`mappatcher` - Opens the mappatcher editor.

`mappatcher_draw 0/1` - Enables the drawing of objects and clip brushes outside the editor.

## Setup

Just drop the folder into addons folder. If you have ULX or ServerGuard installed, you can setup access through admin mod, otherwise you can change permissions in mappatcher/lua/mappatcher/config.lua.

## Screenshots

![](https://i.imgur.com/roqNMGg.jpg)
![](https://i.imgur.com/Ngxv1xY.jpg)
![](https://i.imgur.com/r88T2LT.png)
