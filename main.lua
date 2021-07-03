--[[# -------------------------------------------------------------

			METEORAIN
	
	A Game Boy Advance game made for the GBA Jam 2021
		by Dr. Ludos (2021)
	
	This game is a port/remake of a Mega Drive / Genesis game I made in 2019:
	https://drludos.itch.io/meteorain-gameshell-jam-1
	
	The game is made in Lua using the wonderful BPCore-Engine by Evan Bowman:
	https://github.com/evanbowman/BPCore-Engine
	
	You may also note that, in order to reduce the game startup time, this Lua script is minified
	in the actual rom. I used this online minifier: https://mothereff.in/lua-minifier
	
	Get all my other games: 
		http://drludos.itch.io/
	Support my work and get access to betas and prototypes:
		http://www.patreon.com/drludos

	Gameplay music: Warlord - Overmode
	Used under a Creative Commons BY-NC-SA license:
	http://battleofthebits.org/arena/Entry/Overmode/7738/

# ------------------------------------------------------------- --]]



--# ------------------------------------
--# ------- VARIABLES ---------
--# ------------------------------------

--# Player
playerX=0
playerY=-16
playerAnim=0
playerFlipX=nil

--# Foes (active/x/y/speedY)
foes={}
foesMax=14
foesTimer=0
for i=0,foesMax,1 do
	table.insert(foes,{
		active=0
		,x=math.random(224)
		,y=-16
		,speedX=0
		,speedY=0
	})
end 	


--# Gameplay
STATE=0 --#Gameplay state: 0 (title) / 1 (gameplay) / 2 (gameover) / 3 (screen fade to (re)start game
ticks=0
score=0
highscore=-1
ticks_anim=0
screenshake=0

--# ------------------------------------
--# ----- LOAD ASSETS ------
--# ------------------------------------

--# Hide the screen
fade(1)

--# Load tiles data for each layer
txtr(0, "overlay.bmp")
txtr(1, "tiles.bmp")
txtr(2, "tiles.bmp")
txtr(4, "sprites.bmp")

--#Build the Background

--# -= Star filled sky =-
--#Paint it black
--#For every line
for i = 0,19,1 do 
	--#For every column
	for j = 0,29,1 do 
		--#Manually put a "black" tile in the layer
		tile(3, j, i, 62)
	end
end

--#Add random stars
for i = 0,40,1 do
	--#Put a random star tile in a random position on the map
	tile(3, math.random(29), math.random(16), 62+math.random(9))
end


--# -= Lunar ground =-
--#For every column
for i = 0,29,1 do 
	--#Display the ground over 4 lines
	--#Top row
	tile(2, i, 17, i+2)
	--#Middle row
	tile(2, i, 18, i+32)
	--#Bottom row (plain grey tile)
	tile(2, i, 19, 1)
	--#out of screen bottomest row (plain grey tile in case of screenshake)
	tile(2, i, 20, 1)
end

--#Reorder the layer priority so the sprites are displayed OVER the overlay (other layers are kept to their default values)
priority(0, 2, 3, 3)



--# ----------------------------------
--# ------- GAME INIT --------
--# ----------------------------------
function init()
	
	--#Init gameplay vars
	ticks=0
	score=0
	foesTimer=60
	
	--#Reset screenshake
	screenshake=0
	scroll(2, 0, 0)
	
	--# Init player vars
	playerX=112
	playerY=140
	playerFlipX=nil
	playerAnim=1
	
	--# Init the meteors
	foes={}
	for i=0,foesMax,1 do
		table.insert(foes,{
			active=0
			,x=math.random(224)
			,y=-16
			,speedX=0
			,speedY=0
		})
	end 	
	
	--#Erase the overlay messages
	--#For every line
	for i = 0,19,1 do 
		--#For every column
		for j = 0,30,1 do 
			--#Manually put a "blank" tile in the layer (tile id 1 in the overlay.bmp asset) - NB: there is no way to erase text with transparent tile for now
			tile(0, j, i, 1)
		end
	end
	
	--#Print score label
	--#print("score:0", 11, 0)
	
	--# Play music
	music("music.raw", 0)
end


--# ------------------------------------
--# ----- GAME UPDATE ------
--# ------------------------------------
function update()

	--# === TICKS ===
		
	--# Count ticks (used for game timing)
	ticks = ticks+1
	
	--# Reset ticks counter every 60 seconds (i.e. after 1 min)
	if ticks > 3601 then
		ticks=1
	end

	--#OPTIMIZATION: make a local var with the same name as the global one, now that we won't be modifying it anymore but we'll read it quite often in the rest of the script / main loop
	local ticks=ticks

	--# === GAMEPLAY STATE ===
	if STATE == 1 then
		
		--# === OPTIMIZATION ===
		--# Make local vars with the same names as the global ones, then we'll copy back the values from local to global vars at the end of the main loop
		local playerX=playerX
		local playerY=playerY
		local playerAnim=playerAnim
		local playerFlipX=playerFlipX
		local screenshake=screenshake
		local foesTimer=foesTimer
		local score=score
	
	
		--# === PLAYER ===
		
		--# Local variable to check wether we can increase animation frame if player walks
		local animate=ticks % 5 == 0
		
		--# Move player in X
		
		--# Moving RIGHT
		if btn(5) then
			
			--# Move player X position
			playerX = playerX + 3
			
			--# Prevent player from exiting screen
			if playerX > 225 then
				playerX=225
			end
			
			--# Disable horizontal flipping
			playerFlipX=nil
			
			--# If it's an animation frame
			if animate then
				--#Increase player walking animation frame
				playerAnim=playerAnim+1
				--# Make animation loop
				if playerAnim > 4 then
					playerAnim=1
				end
			end
			
		--# Moving LEFT
		elseif btn(4) then
			
			--# Move player X position
			playerX = playerX - 3
			
			--# Prevent player from exiting screen
			if playerX < -1 then
				playerX=-1
			end
			
			--# Enable horizontal flipping
			playerFlipX=1
			
			--# If it's an animation frame
			if animate then
				--#Increase player walking animation frame
				playerAnim=playerAnim+1
				--# Make animation loop
				if playerAnim > 4 then
					playerAnim=1
				end
			end	
			
		--# Else, the player is not moving	
		else
			--# Reset player animation to standing still
			playerAnim=1
		end
	
		--# === METEORS ===
		
		local gravity = ticks % 8
		
		--#Compute Player Size once to optimize CPU time a bit!
		local playerX2=playerX+16
		local playerY2=playerY+16
		
		--# For each foe
		for i = 1,14,1 do 
		
			--#Get the current object in a local variable for (slightly) faster access
			local obj=foes[i]
		
			--#If the foe is active
			if obj.active == 1 then
			
				--# Move foe according to its speed
				obj.y=obj.y+obj.speedY
				
				--# Ohh, gravity
				if gravity == 0 and obj.y < 145 then
					obj.speedY = obj.speedY+1;
				end

				--#If the meteor hits the player
				if playerX < (obj.x+16) and playerX2 > obj.x and playerY < (obj.y+16) and playerY2 > obj.y then
				
					--# Disable the meteor
					obj.active=0
					--# reset the meteor positions
					obj.x=math.random(224)
					obj.y=-16
					obj.speedY=0
					
					--# Play Game Over
					sound("sfx_gameover.raw", 0)
					
					--# Stop the music (play a silence audio file as there doesn't seem to be a way to stop music in the API)
					music()
					
					--# Change player animation to death
					playerAnim=5
					
					--#Make a screen fade to emphasize Game Over
					fade(1, 0xFFFFFF, nil, 1)
					
					--#Set the timer for fade / cooldown countdown during Game Over state
					ticks_anim=180
					
					--# Game over man!
					STATE = 2
				end
				
				--#If the meteor hits the ground
				if obj.y >= 145 then
				
					--#Increase score
					score = score+1
					--#print(tostring(score), 17, 0)
				
					--# Disable the meteor
					obj.active=0
					
					--# reset the meteor positions
					obj.x=math.random(224)
					obj.y=-16
					obj.speedY=0
					
					--#Shake screen too
					screenshake=3
					
					--#Stop the impact effects when there are too much meteors on screen (cause it slows down, but also I synched it with the music starting running wild)
					if score < 27 then
						
						--#Play a crashing sound,
						sound("sfx_crash.raw", 0)					
					end
				end

			end

		end
		
		--# === SPAWN METEORS ===
		--#Decrease spawn countdown if neede
		if foesTimer > 1 then
			foesTimer = foesTimer -1
		--# Else, countdown is over, when can generate a new foe!
		else
			--# Spawn a new foe
			spawnFoe()
			
			--# Reset the countdown timer (difficulty increases with score!)
			if score < 2 then
				foesTimer=60
			elseif score < 8 then
				foesTimer=40
			elseif score < 12 then
				foesTimer=30	
			elseif score < 15 then
				foesTimer=20
			elseif score < 30 then
				foesTimer=10
			elseif score < 40 then
				foesTimer=9			
			elseif score < 60 then
				foesTimer=8		
			elseif score < 80 then
				foesTimer=7	
			else
				foesTimer=6
			end
		end 
		
		
		--# === SCREENSHAKE ===
		
		--# If we must apply screenshake
		if screenshake > 0 then
		
			--#Decrease screenshake counter
			screenshake = screenshake-1
			
			--# If we are still in screenshake mode, raise the ground, else put it back to normal position (it's hackjob to avoid using a modulo as we don't need an actual screenshake every 2 frames, but just a way to make the ground move a little after each meteor hitting ground)
			if screenshake > 0 then
				scroll(2, 0, 2)
			else 
				scroll(2, 0, 0)
			end	
		end
		
		--# === OPTIMIZATION === 
		--# Copy back the values from local to global vars with the same name at the end of the main loop (for gameplay only, other states are not so time critical so we didn't optimize them. And for gameover I actually use slowdown voluntarily for a more dramatic effect!)
		_G.playerX=playerX
		_G.playerY=playerY
		_G.playerAnim=playerAnim
		_G.playerFlipX=playerFlipX
		_G.screenshake=screenshake
		_G.foesTimer=foesTimer
		_G.score=score


	--# === GAME OVER STATE ===	
	elseif STATE == 2 then
	
		--#If the game over animation isn't finished
		if ticks_anim > 0 then
		
			--#Decrease countdown
			ticks_anim = ticks_anim-1
			
			--#Init : display load of meteor piece on the first frame
			if ticks_anim == 179 then
				
				--# For each foe - DONT'T optimize this loop (by using for i + locals instead of ipairs + global like we did for gameplay and rendering) as the slowdown produces a better effect on the game over screen!
				for i, obj  in ipairs(foes) do 
					
					--#Activate the foe
					obj.active=1
					
					--#Position it over the player
					obj.x=playerX+5-math.random(9)
					obj.y=playerY-5+math.random(7)
					
					--#And set its speed values
					obj.speedX=3-math.random(7)
					obj.speedY=-(2+math.random(4))
				end
				
				--#Stop the screenshake
				screenshake=0
				scroll(2, 0, 0)
			end
			
			--#Display Game over message
			if ticks_anim == 130 then
			
				--#Erase the top line of text overlay (where score is displayed ingame)
				--#For every column
				for i = 0,30,1 
				do 
					--#Manually put a "black" tile in the layer
					tile(0, i, 0, 1)
				end
			
				--#Display Game Over
				print("GAME OVER", 10, 4)
				
				--#Display score
				--#Different X position depending on score length
				if score < 100 then
					print("score:"..tostring(score), 11, 8)
				else 
					print("score:"..tostring(score), 10, 8)
				end
				
				--#Display highscore
				--#Did we make a new record?
				if score > highscore then
					
					--#Display congratulations message
					print("NEW RECORD!", 9, 10)
					
					--#Save the current highscore
					highscore = score
				
				--#Else, we didn't beat the record
				else 	
				
					--#Display the highscore - different X position depending on score length, so they are always aligned
					if score < 100 then
						print("best:"..tostring(highscore), 12, 10)
					else 
						print("best:"..tostring(highscore), 11, 10)
					end
				end	
				
			end
			
			--#Fade out slowly 
			if ticks_anim < 120 and ticks_anim >= 20 then
				fade( (ticks_anim-20)/100, 0xFFFFFF, nil, 1)
			end
			
			--# When anim is finished, reset ticks so the blinking message starts immediatedly on the next frame
			if ticks_anim == 0 then
				ticks=29
			end

		--#Else the countdown is finished, so we can restart the game if needed
		else 
			--#Display blinking press button to start message
			j=ticks % 60
			if j == 30 then
				print("press button to restart", 4, 15)
			elseif j == 0 then
				--#erase the message (printing a "space" will leave a black square, this code put a transparent tile instead)
				for i = 4,26,1 do 
					tile(0, i, 15, 1)
				end
			end
		
			--#Restart game when button pressed
			if btnp(0) or btnp(1) then
				--#Restart the game! (using a fading handled by a separate state)
				STATE=3
				ticks_anim = 60
			end
		end	
		
		
		
		--#Animate the meteor pieces falling
		
		--#Compte gravity only once for all meteors
		local gravity = ticks % 7
		
		--# For each foe - DONT'T optimize this loop (by using for i + locals instead of ipairs + global like we did for gameplay and rendering) as the slowdown produces a better effect on the game over screen!
		for i, obj  in ipairs(foes) do 
		
			--#If the foe is active
			if obj.active == 1 then
			
				--# Move foe according to its speed
				obj.x=obj.x+obj.speedX
				obj.y=obj.y+obj.speedY
				
				--# Ohh, gravity
				if gravity == 0 then
					obj.speedY = obj.speedY+1;
				end
				
				--#If the meteor goes out of the screen
				if obj.y > 240 then
				
					--# Disable the meteor
					obj.active=0
					
					--# reset the meteor positions
					obj.x=math.random(224)
					obj.y=-16
					obj.speedY=0
					obj.speedX=0
				end	
				
			end
		end	
		
		
	--# === GAME (RE)START FADING STATE ===	
	elseif STATE == 3 then
	
		--#If the animation isn't finished
		if ticks_anim > 0 then
		
			--#Decrease countdown
			ticks_anim = ticks_anim-1
			
			--#Fade out slowly 
			if ticks_anim > 30 then
				fade( 1-((ticks_anim-30)/30), 0x000000, 1, 1)
			
			--#(re)set game
			elseif ticks_anim == 30 then
				init()	
				
			--#Fade in slowly 
			elseif ticks_anim > 0 then
				fade(  ticks_anim/30, 0x000000, 1, 1)
			
			--#Animation finished, start the game
			else 
				STATE=1
			end

		end
	
	
	--# === TITLE SCREEN STATE ===	
	elseif STATE == 0 then
	
		--#If the animation isn't finished
		if ticks_anim > 0 then
		
			--#Decrease countdown
			ticks_anim = ticks_anim-1
			
			--#Init : display title screen elements
			if ticks_anim == 59 then
				
				--#Display title
				print("METEORAIN", 10, 4)
				
				--#Display credits
				print("a game by", 21, 15)
				print("Dr.LUDOS", 22, 16)
				print("music by", 0, 15)
				print("WARLORD", 0, 16)
			end
			
			--#Fade in slowly 
			if ticks_anim >= 0 then
				fade( ticks_anim/60, 0x000000, 1, 1)
			end

		--#Else the countdown is finished, so we can start the game if needed
		else 
		
			--#Display blinking press button to start message
			j=ticks % 60
			if j == 30 then
				print("press button to start", 5, 10)
			elseif j == 0 then
				--#erase the message (printing a "space" will leave a black square, this code put a transparent tile instead)
				for i = 5,25,1 do 
					tile(0, i, 10, 1)
				end
			end
		
			--#Restart game when button pressed
			if btnp(0) or btnp(1) then
			
				--#Start the game! (using a fading handled by a separate state)
				STATE=3
				ticks_anim = 60
			end
		end	
		
	end	
	
end


--# ------------------------------------
--# --- RENDER SCREEN ----
--# ------------------------------------
--# MEMO: sprites are drawn from front to bottom in BPCore-Engine
function draw()
	
	--# === OPTIMIZATION ===
	--# Make local vars with the same names a the global one for faster access (no need to copy back values at the end of the function, as it only reads them)
	local playerX=playerX
	local playerY=playerY
	local playerAnim=playerAnim
	local playerFlipX=playerFlipX
	
	--#If we are in gameplay, display regular meteors
	if STATE == 1 then
	
		--# Display Player before meteors
		spr(playerAnim, playerX, playerY, playerFlipX)
	
		--# For each foe
		for i = 1,14,1 do 
			--#Get the current object in a local variable for (slightly) faster access
			local obj=foes[i]
			
			--#If the foe is active, display it on screen
			if obj.active == 1 then
				spr(0, obj.x, obj.y)
			end
		end
		
	--#Else display meteor pieces for the game over screen
	else
	
		--# Don't do it if ticks_anim == 180, meaning we haven't initialized the meteors yet (this check avoid displaying meteors at their original place before they are reused for the game over explosion parts, looking like a glitch)
		if ticks_anim ~= 180 then
		
			--# For each foe
			for i = 1,14,1 do 
				
				--#Get the current object in a local variable for (slightly) faster access
				local obj=foes[i] 
				
				--#If the foe is active, display it on screen (use their index if foes table to attribute them a different anim)
				if obj.active == 1 then
					spr(6+(i%4), obj.x, obj.y)
				end
			end
		end	
	
		--# Display Player after meteors pieces
		spr(playerAnim, playerX, playerY, playerFlipX)
	end
	
	--# Then display Player
	spr(playerAnim, playerX, playerY, playerFlipX)
	
end


--# ------------------------------------
--# --- SPAWN METEOR ----
--# ------------------------------------
function spawnFoe()

	--# Check among the Foes for an empty slot (else, silently skip generating a foe)
	for i = 1,14,1 do 
	
		--#Get the current object in a local variable for (slightly) faster access
		local obj=foes[i]
	
		--#If the foe is inactive, then makes it active!
		if obj.active == 0 then
		
			--#Activate it (the position value are already randomly generated when the foe is disabled)
			obj.active=1
			
			--# Job done, quit function for now!
			return
		end
	end
	
end



--# Count how much RAM the whole LUA script is using (max 256kb)
--#print(tostring(collectgarbage("count")*1024), 0, 19)


--# ------------------------------------
--# ------- MAIN LOOP ---------
--# ------------------------------------

--#First, display the title screen (we are still with the screen faded off completely, so the "fade in" will be made by title screen state)
STATE=0
--#Define the duration for the title screen animation (fade in)
ticks_anim=60

--#Then, enter the endless loop of the program
while true do
	--#Update the game code (don't use the delta variable time as we don't need it for this game - every CPU cycle counts here!)
	update()
	--# Clear screen and waits for Vblank
	clear()
	--# Draw screen (make the spr and tile calls)
	draw()
	--# Process the spr and tile calls to actually update the display
	display()	
end

