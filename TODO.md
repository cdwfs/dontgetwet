TODO:
- fx: sparkles on refill stations to make them stand out more
- fx: Player disappears in a splash in deep water
- fx: spawn splash particles when characters enter or move in water
- fx: spawn droplets in player rect after getting hit with balloon
- fx: wet footprints after leaving water or getting hit
- ui: about screen
- ui: help screen
- ui: credits screen
- bug: guess what the background a spawned object should be replaced with. Look at surrounding tiles, count grass/pavement/water, and go with whatever you see the most of.
- bug: remove "kill everyone but player one" hack
- art: new palette for menus, with a darker background instead of something unused.
- art: add actual title logo to main menu
- fx: mode transition: dozens of balloons fly at the screen and explode in splashes, which wash away to reveal the new mode
- fx: victory screen: a steady rain of the winning team's balloons falling and exploding on losing players
- feature: enable hidden characters. Check for button combo at player creation time?
- sound: unique sfx for players on left & right side of the screen
- art: sand tiles? (slow running)
- art: Basketball hoop sprites
- art: winning player animation
- art: losing player animation
- art: up & down leg animations are currently the same. Differentiate? Add a tshirt logo?
  
DONE:
* strip invisibrawl arrows/blood code
* refactor init_player
* Implement pal() helper
* Players are visible by default in other viewports
* change player size to 8x16
* replace complex dir field with dirx,diry. Rename existing dx,dy to movex,movey or vx,vy.
* implement throwing, spawning/despawning, drawing balloons
* implement balloons hitting terrain
* 2d vector math type
* Water balloons
  * implement balloons hitting players
  * implement windup
  * implement splash damage
* recharge stations
  * implement health bars and ammo counters
  * implement recharges
  * implement pings when players recharge
* don't set hflip when player is facing up. Just flip the sprite in the sheet.
* 2nd run doesn't work, the map has already been modified.
X Players are invisible in grass in other viewports. Dithered on their own. [nah, just have tall grass obscure them]
X AI [defer to quadplay]
* implement running
* eliminated players can still move/throw/refill/etc.
* add sprite flag for "blocks balloons", separate from "blocks movement".
* add fade-to-black helper, and fade between modes during transitions
* flip hat direction for upward-facing kid. Or delete it.
* call mode:leave() automatically
* vararg dsprint()
* paths
* replace color 9 with dark brown (suitable for hair, skin, dirt, wood, etc.)
* decouple leg animations from face sprites. Add multiple variations of face, with skin/hair palette swaps.
* replace orange in title screen palette with 0xFFF9
* signs
* forward character face/skin/hair from game to victory to make sure they look the same
* random grass variations
* main menu sounds
* in-game sounds
* players can form teams
* add a delay & prompt to victory screen
* bushes block balloons but not movement? (you'd still get splash damage)
* don't allow running with windup, to make chases more interesting.
* move refill station cooldown from per-player to per-station
* more sign variety
* tiles for streams & ponds
* seesaw sprites
* toilet sprites
* add "no shadows" sprite flag. Add to wall tiles. draw them after the main shadow pass, but before sorted draws.
* rock sprites
* deeper water is instant death. Player disappears in a splash
* shallow water is slowdown / energy drain. (draw players offset a few pixels lower, clip off their legs, add splash particles)
* sudden death. (everyone gets one last refill, and then all refill stations disappear)
* About/Help/Credits navigation
* music: in-game
* music: sudden death
X fx: head bob. For ABCB walk cycle, draw head one pixel lower when moving in the middle of the A and C frames. [tried it, it doesn't look right]
* music: victory
* music: main menu
X feature: helper to find an available sound channel for sfx. Needs to handle being called multiple times a frame. [didn't end up needing it]
* feature: push_clip()/pop_clip() helpers to temporarily restrict drawing to an even smaller area
* vertically offset players standing in shallow water, with a splash sound when they enter
* bug: add player velocity to initial balloon velocity
* bug: diagonal balloons are thrown too far
* art: picnic blanket tiles
