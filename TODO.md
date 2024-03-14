TODO:
- Player visibility
  - Players are invisible in grass in other viewports. Dithered on their own.
- Player movement
  - implement running
  - draw differently in bushes
- Water balloons
  * implement balloons hitting players
  - implement windup
  - implement splash damage
- recharge stations
  * implement health bars and ammo counters
  * implement recharges
  - implement pings when players recharge
- helpers
  - formalize mode:leave() method
  - bring over the fade() helper function, if needed
  - vararg print() helpers
  - implement ttri()-based rspr() if I need it

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
