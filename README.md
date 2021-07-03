# MeteoRain (GBA)


A Game Boy Advance game for the [GBA Jam 2021](https://itch.io/jam/gbajam21)

by **Dr. Ludos** *(2021)*

This is the source code, you can get a precompiled rom from here: \
https://drludos.itch.io/meteorain-gba-jam-2021

 
***
Get all **my other games**: http://drludos.itch.io/ \
**Support my work** and get access to betas and prototypes:\
http://www.patreon.com/drludos
***

**Meteors are falling from the sky! Avoid them as long as possible to make an high score!**

![meteorain_gameplay](https://user-images.githubusercontent.com/42076899/124360581-f3aefa00-dc2a-11eb-8335-5b5ec7418855.gif)

This is a port/remake of a previous homebrew game I did for the [SEGA Mega Drive / Genesis](https://drludos.itch.io/meteorain-gameshell-jam-1). But for the GBA Jam, I programmed this version from scratch as it's **100% made in Lua!** Indeed, I used the wonderful **[BPCore-Engine by Evan Bowman](https://github.com/evanbowman/BPCore-Engine  )** that allows to create a GBA games in Lua. If you ever used a fantasy console like PICO-8 or TIC-80, it's a very similar tool, but the resulting game will run on a actual console, our beloved Game Boy Advance! 

If you want to try your hand at making GBA games, I really recommend you BPCore-Engine: it's a real pleasure to make games with it. And I'm also sharing the heavily commented code source of my game here if it can help you making your own GBA games in Lua!

## Music credits

Ingame music: **"Overmode" by Warlord**, used under a CC-BY-NC-SA licence:\
http://battleofthebits.org/arena/Entry/Overmode/7738/  

The music was converted to a 16kHz signed 8bit PCM audio format (see "music.raw" file) to be played back on the GBA.

## How to build

This game was made using [BPCore-Engine 0.05](https://github.com/evanbowman/BPCore-Engine/releases/tag/0.0.5), that is also included here for convenience.

To build the rom, you'll need to have Lua 5.3 installed on your system, and to launch the "build.lua" script. It'll take the raw "BPCoreEngine.gba" rom, and inject both the assets (graphics, audio) and code (lua scripts) to generate a fully working GBA rom with the game.

The whole game code is located in the "main.lua" file, that is heavily commented to help you read the code. The final rom release actually use a "minified" version of the same code, also included here "mainMINIFIED.lua". I used the following site to minify the lua script: https://mothereff.in/lua-minifier

I hope you'll enjoy the game, and don't hesitate to ask me if you have any question about the source code!
