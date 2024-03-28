TODO:
- sound
  - walk loop
  - run loop
  - windup
  - throw
  - splash (terrain)
  - splash (player)
  - refill
  - refill warning
  - player eliminated
  - victory
- music
  - menu
  - in-game
  - victory
- main menu
- help screen
- credits screen
- time limit (either explicit, or battle-royale-style arena shrinking)
- bugs
  - add a delay & prompt to victory screen
  - remove "kill everyone but player one" hack
  - players should collide with other players
  - bushes block balloons but not movement? (you'd still get splash damage)
  - dark green drop-shadows don't look right over paths. avoid placing pushes and trees to the left/right of paths? Crazy shadow-clipping?
  - drop-shadows draw over neighboring walls. THAT should be solved with clipping.
  - don't allow running with windup, to make chases more interesting.
- art
  - winning player animation
  - losing player animation
  - streams/general-purpose ponds
  - sparkles on refill stations to make them stand out more
  - up & down leg animations are currently the same. Differentiate? Add a tshirt logo?
- polish
  - mode transition: dozens of balloons fly at the screen and explode in splashes, which wash away to reveal the new mode
  - victory screen: a steady rain of the winning team's balloons falling and exploding on losing players
  
  
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
* grass variations
* main menu sounds