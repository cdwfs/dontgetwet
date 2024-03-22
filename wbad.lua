-- title:   Water Balloons At Dawn
-- author:  Bitterly Indifferent Games
-- desc:    Stealth-focused water-balloon fight game for 2-4 players.
-- site:    github.com/cdwfs/wbad
-- license: Creative Commons Zero v1.0 Universal
-- version: 0.1
-- script:  lua

--local _ENV = require 'std.strict'(_G)
--local undies=my_undefined_global_var

------ GLOBALS

-- constants
K_MAX_HEALTH=100
K_MAX_AMMO=5
K_MAX_PING_RADIUS=600
K_REFILL_COOLDOWN=60*5
K_MAX_WINDUP=60
K_MIN_THROW=20
K_MAX_THROW=70
K_BALLOON_RADIUS=2
K_SPLASH_DIST=14
-- palette color indices
PID_COLORS={2,10,4,12}
C_WHITE=8
C_BLACK=0
C_DARKGREY=3
C_LIGHTBLUE=13
C_RED=5
C_TRANSPARENT=5 -- by default
-- sounds
SFX_FOO=0
-- music patterns
MUS_MENU=0
-- map tile ids
TID_GRASS=100
TID_GRASS_NOMOVE=2
TID_SPAWN_TREE=112
TID_SPAWN_MBARS=113
TID_SPAWN_SWING=114
TID_SPAWN_REFILL=115
TID_SPAWN_PLAYER=116
TID_SPAWN_ELEPHANT=117
TID_SPAWN_XXX=118
TID_SPAWN_BUSH=119
-- sprite ids
SID_PLAYER=288
SID_REFILL=283
SID_BUSH=263
SID_ELEPHANT=299
SID_TREE=269
SID_SWING=416
SID_MBARS=420
-- sprite flags
SF_IMPASSABLE=0
SF_PLAYER=1

-- make an oop-like object.
-- see www.lexaloffle.com/bbs/?tid=49047
_g=_ENV -- store global environment for future reference
function obj(t)
 return setmetatable(t,{__index=_ENV})
end

-- pico8 compatibility aliases
-- https://github.com/neilpopham/tic80/blob/master/projects/gunslugs/pico8.lua
add=table.insert
sqrt=math.sqrt
abs=math.abs
min=math.min
max=math.max
flr=math.floor
ceil=math.ceil
function sub(str,i,j) return str:sub(i,j) end
function mid(a,b,c) t={a,b,c} table.sort(t) return t[2] end
function rnd(a) a=a or 1 return math.random()*a end
function cos(x) return math.cos((x or 0)*(math.pi*2)) end
function sin(x) return math.sin(-(x or 0)*(math.pi*2)) end
function atan2(x,y) return (0.75 + math.atan2(x,y) / (math.pi * 2)) % 1.0 end
function sgn(a) if a>=0 then return 1 end return -1 end
function sget(x,y)
 x,y=flr(x),flr(y)
 local addr=0x8000+64*(flr(x/8)+flr(y/8)*16)
  return peek4(addr+(y%8)*8+x%8)
end
function del(t,a)
 for i,v in ipairs(t) do
  if v==a then
   local r=v
   t[i]=t[#t]
   t[#t]=nil
   return r
  end
 end
end
function pal(c0,c1,type)
 c0=c0 or -1
 c1=c1 or -1
 type=type or 0
 if c0<0 and c1<0 then
  if type==0 then
   for i=0,15 do
    poke4(0x7FE0+i,i)
   end
  end
 else
  c0=flr(c0%16)
  if c1<0 then
   c1=c0
  end
  c1=flr(c1%16)
  if type==0 then
   poke4(0x7FE0+c0,c1)
  else
   local stri
   for i=0,5 do
    stri=#__p8_pal-(c1+1)*6+i
    poke4(0x3FC0*2+#__p8_pal-(c0+1)*6+i,tonumber(__p8_pal:sub(stri,stri),16))
   end
  end
 end
end
-- pico8-like camera() feature, plus
-- overloaded draw calls that
-- automatically add the camera offset
camera_x,camera_y=0,0
function camera(x,y)
 camera_x,camera_y=x or 0,y or 0
end
tic80spr=spr
spr=function(id,x,y,colorkey,scale,flip,rotate,w,h)
 tic80spr(id, x-camera_x, y-camera_y,
          colorkey or -1, scale or 1,
          flip or 0, rotate or 0,
          w or 1, h or 1)
end
tic80map=map
map=function(x,y,w,h,sx,sy,colorkey,scale,remap)
 tic80map(x or 0, y or 0,
          w or 30, h or 17,
          (sx or 0)-camera_x,
          (sy or 0)-camera_y,
          colorkey or -1,
          scale or 1, remap)
end
tic80line=line
line=function(x0,y0,x1,y1,color)
 tic80line(x0-camera_x,y0-camera_y,
  x1-camera_x,y1-camera_y,color)
end
tic80circ=circ
circ=function(x,y,radius,color)
 tic80circ(x-camera_x,y-camera_y,radius,color)
end
tic80circb=circb
circb=function(x,y,radius,color)
 tic80circb(x-camera_x,y-camera_y,radius,color)
end
tic80rect=rect
rect=function(x,y,w,h,color)
 tic80rect(x-camera_x,y-camera_y,w,h,color)
end
tic80rectb=rectb
rectb=function(x,y,w,h,color)
 tic80rectb(x-camera_x,y-camera_y,w,h,color)
end
tic80pix=pix
pix=function(x,y,color)
 return tic80pix(x-camera_x,y-camera_y,color)
end
tic80elli=elli
elli=function(x,y,a,b,color)
 tic80elli(x-camera_x,y-camera_y,a,b,color)
end
tic80ellib=ellib
ellib=function(x,y,a,b,color)
 tic80ellib(x-camera_x,y-camera_y,a,b,color)
end
-- tiny vector2 library
-- adapted from vector.p8 (https://www.lexaloffle.com/bbs/?tid=50410)
function v2(x,y) return {x=x or 0,y=y or 0} end
function v2polar(l,a) return v2(l*sin(a),l*cos(a)) end
function v2rnd()      return v2polar(1,rnd()) end
function v2cpy(v)     return v2(v.x,v.y) end
function v2unpck(v)   return v.x,v.y end
function v2arr(v)     return {v2unpck(v)} end
function v2tostr(v,d) return "["..v.x..", "..v.y.."]" end
function v2isvec(v)   return type(v)=="table" and type(v.x)=="number" and type(v.y)=="number" end
function v2eq(a,b)    return a.x==b.x and a.y==b.y end
function v2add(a,b) return v2( a.x+b.x,  a.y+b.y) end
function v2sub(a,b) return v2( a.x-b.x,  a.y-b.y) end
function v2scl(v,n) return v2( v.x*n,    v.y*n) end
v2mul=v2scl
function v2div(v,n) return v2( v.x/n,    v.y/n) end
function v2neg(v)   return v2(-v.x,     -v.y) end
function v2dot(a,b)   return a.x*b.x+a.y*b.y end
function v2magsq(v)   return v2dot(v,v)          end
function v2mag(v)     return sqrt(v2magsq(v))    end
function v2dstsq(a,b) return v2magsq(v2sub(b,a)) end
function v2dst(a,b)   return sqrt(v2dstsq(a,b))  end
function v2norm(v)    return v2div(v,v2mag(v))   end
function v2perp(v)    return v2(v.y, -v.x)   end
function v2sprj(a,b)  return v2dot(a,v2norm(b))  end
function v2proj(a,b)  return v2scl(v2norm(b),v2sprj(a,b)) end
function v2rot(v,t)    local s,c=sin(v2ang(v)-t),cos(v2ang(v)-t) return v2(v.x*c+v.y*s, -(s*v.x)+c*v.y) end
function v2ang(v)      return atan2(v.x,v.y)    end
function v2atwds(a,b)  return v2ang(v2sub(b,a)) end
function v2lerp(a,b,t) return v2(a.x+(b.x-a.x)*t, a.y+(b.y-a.y)*t) end
function v2flr(v)      return v2(flr(v.x),flr(v.y)) end
v2right=v2( 1, 0)
v2left =v2(-1, 0)
v2down =v2( 0, 1)
v2up   =v2( 0,-1)
v2above=v2cpy(v2down)
v2below=v2cpy(v2up  )
v2zero=v2()
v2one =v2(1,1)

-- gradually approach a target
-- c/o https://lisyarus.github.io/blog/programming/2023/02/21/exponential-smoothing.html
-- - x is the current value
-- - target is the target value
-- - speed is some measure of how quickly
--   x should approach target over time.
--   Formally, 1/speed is the time it
--   takes for the value to become
--   closer to target by a factor
--   of e=2.71828...
function approach(x,target,speed)
 local s=speed or 1
 local dt=1
 return x+(target-x)*(1-math.exp(-s*dt))
end

function clamp(x,low,hi)
 return max(low,min(hi,x))
end

function lerp(a,b,t)
 return a+(b-a)*t
end

-- return pixel x,y for a sprite.
-- useful for the ttri() function.
function sprxy(sid)
 return 8*(sid%16),8*(sid//16)
end

-- print with a drop-shadow
-- TODO: use ... and unpack(arg) to pass extra TIC80 args to print()
function dsprint(msg,x,y,c,cs)
 print(msg,x-1,y+1,cs)
 print(msg,x,y,c)
end

-- print centered on screen
function cprint(msg,y,c)
 print(msg,64-2*#msg,y,c)
end

-- creates an animation from a
-- list of values and frame counts.
-- one anim per running instance (all frames & counts will be stored per-instance)
-- a:nextv() increments the frame counter and returns the value for the new frame.
--       or nil when there are no frames remaining
-- if fcounts is a number,each value's fcount is that number.
-- if fcounts is omitted, each value's fcount is 1.
function anim(values,fcounts)
 return {
  vals=values,
  fc=fcounts or 1,
  fcit=type(fcounts)=="table",
  i=0,
  c=1,
  nextv=function(_ENV)
   -- todo: prevent wraparound
   -- error after anim ends.
   c=c-1
   if c==0 then
    i=i+1
    c=fcit and fc[i] or fc
   end
   return vals[i]
  end,
  rewind=function(_ENV)
   i,c=0,1
  end
 }
end
-- create a graph of interconnected
-- animation states.
-- each entry in state is a table with
-- two entries: {anim,next_state}
function animgraph(states,start_state)
 return {
  states=states,
  sn=start_state,
  s=states[start_state],
  v=states[start_state][1]:nextv(),
  nextv=function(_ENV)
   v=s[1]:nextv()
   while not v do
    s,sn=states[s[2]],s[2]
    s[1]:rewind()
    v=s[1]:nextv()
   end
   return v
  end,
  to=function(_ENV,new_state)
   s,sn=states[new_state],new_state
   s[1]:rewind()
   v=s[1]:nextv()
  end,
 }
end


-- game modes
-- don't edit these directly;
-- call set_next_mode() instead.
mode_enters={}
game_mode=""
next_mode=""
next_mode_enter_args={}
mode_obj=nil
mode_frames=0
game_frames=0
all_frame_hooks={}

-- switch to a new game mode.
-- args is passed to the new
-- mode's enter() function.
--
-- the transition takes place
-- on the frame following the
-- one in which this function
-- is called.
function set_next_mode(mode,args)
 next_mode=mode
 next_mode_enter_args=args
end

-- Register a callback to run after every frame.
-- Frame hook execution order is undefined.
-- callback(frames_left,total_frames,...):
--   frames_left ranges from [total_frames-1..0].
--   Can be nil.
--   If callback() returns true, the hook is removed
--   without running its end_callback.
-- end_callback(...):
--   Runs after callback() on the last frame.
--   Can be nil.
-- frames: the number of frames to run the callback.
--   If nil, defaults to math.huge.
-- run_in_mode: the name of the mode to run the hook in.
--   If nil, defaults to the current mode.
-- Returns a hook object, pass to remove_frame_hook()
function add_frame_hook(callback,end_callback,
  frames,run_in_mode,...)
 local total_frames=frames or math.huge
 local h={
  cb=callback,
  end_cb=end_callback,
  total_frames=total_frames,
  frames_left=total_frames-1,
  mode=run_in_mode,
  data=table.pack(...),
 }
 table.insert(all_frame_hooks,h)
 return h
end
function delay(callback,delay_frames,...)
 return add_frame_hook(nil,callback,delay_frames,nil,...)
end
-- Remove the provided hook immediately, without running
-- its end_callback.
function remove_frame_hook(hook)
 for i,h in ipairs(all_frame_hooks) do
  if h==hook then
   table.remove(all_frame_hooks,i)
   break
  end
 end
end
-- Remove all hooks registered for the provided mode.
-- If mode is nil, remove all hooks where run_in_mode=nil.
function remove_frame_hooks_by_mode(mode)
 process_frame_hooks_by_mode(mode,"remove")
end
-- (internal) iterates over registered frame hooks for the
-- provided mode.
-- op can be "exec" (run hooks for mode)
-- or "remove" (remove all hooks for mode)
function process_frame_hooks_by_mode(mode,op)
 local new_hooks={}
 for _,h in ipairs(all_frame_hooks) do
  --mode=play h.mode=nil. don't keep this
  if op=="remove" then
   if mode==nil then
    if h.mode~=nil and h.mode==game_mode then
     table.insert(new_hooks,h)
    end
   elseif h.mode==nil then
    if mode~=game_mode then
     table.insert(new_hooks,h)
    end
   else -- mode and h.mode are not nil
    if h.mode~=mode then
     table.insert(new_hooks,h)
    end
   end
  elseif op=="exec" then
   local remove_early=nil
   if not h.mode or h.mode==mode then
    if h.cb then
     remove_early=h.cb(h.frames_left,h.total_frames,table.unpack(h.data))
    end
    if h.frames_left==0 and not remove_early and h.end_cb then
     h.end_cb(table.unpack(h.data))
    end
    h.frames_left=remove_early and -1 or h.frames_left-1
   end
   if h.frames_left>=0 then
    table.insert(new_hooks,h)
   end
  end
 end
 all_frame_hooks=new_hooks
end

function BOOT()
  trace("**BOOT** "..tstamp()//1000)
  mode_enters={
  menu=menu_enter,
  combat=cb_enter,
 }
 game_mode="menu"
 next_mode,next_mode_enter_args=game_mode,nil
 cls(0)
 mode_obj=mode_enters[game_mode]()
 mode_frames=0
 game_frames=0
end

function TIC()
 mode_obj:update()
 mode_obj:draw()
 process_frame_hooks_by_mode(game_mode,"exec")
 mode_frames=mode_frames+1
 if next_mode~=game_mode then
  game_mode=next_mode
  mode_frames=0
  mode_obj=mode_enters[game_mode](next_mode_enter_args)
 end
 game_frames=game_frames+1
end

------ MENU

mm={}

function menu_enter()
 camera(0,0)
 cls(0)
 music(MUS_MENU)
 mm=obj({
  update=menu_update,
  draw=menu_draw,
  leave=menu_leave,
  player_count=2, -- must be 2-4
 })
 return mm
end

function menu_leave(_ENV)
 clip()
 music()
end

function menu_update(_ENV)
 -- input
 if btnp(2) then
  player_count=(player_count-2+2)%3+2
 elseif btnp(3) then
  player_count=(player_count-2+1)%3+2
 end
 if btnp(4) then
  mm:leave() -- TODO call this automatically
  set_next_mode("combat",{
   player_count=player_count,
  })
 end
end

function menu_draw(_ENV)
 cls(C_BLACK)
 spr(32,80,40,0,2,0,0,5,3)
 print("< "..player_count.." PLAYERS >",80,100,12,true)
end

------ COMBAT

cb={}

function cb_enter(args)
 camera(0,0)
 cb=obj({
  update=cb_update,
  draw=cb_draw,
  leave=cb_leave,
  all_player_count=args.player_count,
  player_spawns={},
  players={}, -- see cb_init_players()
  live_player_count=args.player_count,
  balloons={},
  refills={},
  wparts={}, -- water particles
  refill_pings={},
  -- scenery entities
  trees={},
  mbars={},
  swings={},
  elephants={},
  bushes={},
 })
 -- adjust clip rects based on player count
 local pid_clips={
  {  0, 0,240,136},
  {120, 0,120,136},
  {  0,68,120, 68},
  {120,68,120, 68},
 }
 if cb.all_player_count>=2 then
  pid_clips[1][3]=120
 end
 if cb.all_player_count>=3 then
  pid_clips[1][4]=68
  pid_clips[2][4]=68
 end
 cb.clips=pid_clips
 -- parse map and spawn entities at
 -- indicated locations
 for my=0,135 do
  for mx=0,239 do
   local tid=mget(mx,my)
   if tid==TID_SPAWN_TREE then
    add(cb.trees,{
     pos=v2(mx*8,my*8),
     flip=flr(rnd(2)),
    })
    mset(mx,my,TID_GRASS_NOMOVE)
   elseif tid==TID_SPAWN_MBARS then
    add(cb.mbars,{
     pos=v2(mx*8,my*8),
     colorkey=15,
    })
    -- monkey bars are 3 tiles wide
    -- but the middle is passable
    mset(mx+0,my,TID_GRASS_NOMOVE)
    mset(mx+1,my,TID_GRASS)
    mset(mx+2,my,TID_GRASS_NOMOVE)
   elseif tid==TID_SPAWN_SWING then
    add(cb.swings,{
     pos=v2(mx*8,my*8),
    })
    -- swings are 4 tiles wide
    for x=mx,mx+3 do
     mset(x,my,TID_GRASS_NOMOVE)
    end
   elseif tid==TID_SPAWN_ELEPHANT then
    add(cb.elephants,{
     pos=v2(mx*8,my*8),
    })
    mset(mx,my,TID_GRASS_NOMOVE)
   elseif tid==TID_SPAWN_REFILL then
    add(cb.refills,{
     pos=v2(mx*8,my*8),
    })
    mset(mx,my,TID_GRASS)
   elseif tid==TID_SPAWN_PLAYER then
    add(cb.player_spawns,v2(mx,my))
    mset(mx,my,TID_GRASS)
   elseif tid==TID_SPAWN_BUSH then
    add(cb.bushes,{
     pos=v2(mx*8+rnd(4)//1,
            my*8+rnd(7)//1),
     flip=flr(rnd(2)),
    })
    mset(mx,my,TID_GRASS)
   end
  end
 end
 -- spawn players
 cb_init_players(cb)
 return cb
end

function cb_create_player(pid)
 return {
  --[[
  notes on player coordinates:
  - positions are for the player's
    upper-left corner
  - fpos is raw floating-point pos,
    which should only be used for motion.
  - pos is fpos rounded to the nearest
    pixel (always integers)
  - move is the player's current raw
    movement in each axis: -1,0,1
    (later scaled by speed). If no dpad input
    is pressed, they will be zero.
  - dir is the player's current
    facing direction -- the last direction
    they moved. This is used for throwing
    balloons and choosing a sprite when
    not in motion.
  - vpcenter are the pixel offsets to the
    center of the current player's
    viewport. These are computed once at
    startup and are constant for each
    player thereafter.
  - focus is the world-space
    position that should be drawn at
    the center of the player's viewport.
  - The final screen-space coordinates
    for an object at world-space pos wp
    for a given player are:
    vpcenter-focus+wp
  ]]
  fpos=v2(0,0),
  pos=v2(0,0),
  move=v2(0,0),
  dir=v2(1,0),
  vpcenter=v2(0,0),
  focus=v2(0,0),
  color=PID_COLORS[pid],
  pid=pid,
  speed=0, -- how far to move in current dir per frame
  health=K_MAX_HEALTH,
  ammo=K_MAX_AMMO,
  refill_cooldown=0,
  dead=false,
  windup=0,
  anims=animgraph({
   idlelr={anim({258},8),"idlelr"},
   idled={anim({290},8),"idled"},
   idleu={anim({322},8),"idleu"},
   walklr={anim({256,258,260,258},8),"walklr"},
   walkd={anim({288,290,292,290},8),"walkd"},
   walku={anim({320,322,324,322},8),"walku"},
  },"idlelr"),
  hflip=0,
 }
end
function cb_init_players(cb)
 for pid=1,cb.all_player_count do
  local p=cb_create_player(pid)
  -- choose a spawn tile
  --local ispawn=1+flr(rnd(#cb.player_spawns))
  local ispawn=pid
  p.fpos=v2scl(
   v2cpy(cb.player_spawns[ispawn]),8)
  p.pos=v2flr(v2add(p.fpos,v2(0.5,0.5)))
  local pclip=cb.clips[pid]
  p.vpcenter=v2(
   pclip[1]+pclip[3]/2,
   pclip[2]+pclip[4]/2)
  add(cb.players,p)
 end
end

function cb_leave(_ENV)
 clip()
 music()
end

local function canwalk(px,py)
 local t=mget((px+0.5)//8,(py+0.5)//8)
 return not fget(t,SF_IMPASSABLE)
end

function cb_update(_ENV)
 -- update water particles
 local wparts2={}
 for _,wp in ipairs(wparts) do
  wp.ttl=wp.ttl-1
  if wp.ttl>0 then
   wp.pos=v2add(wp.pos,wp.vel)
   wp.vel=v2scl(wp.vel,0.9)
   add(wparts2,wp)
  end
 end
 wparts=wparts2
 -- update balloons
 local balloons2={}
 for _,b in ipairs(balloons) do
  local pop=false
  b.t=b.t+1
  if b.t>b.t1 then
   pop=true
   goto end_balloon_update
  end
  b.pos=v2lerp(b.pos0,b.pos1,b.t/b.t1)
  -- collide with terrain
  if not canwalk(b.pos.x,b.pos.y) then
   pop=true
   goto end_balloon_update
  end
  -- collide with players
  for _,p in ipairs(players) do
   if b.pid~=p.pid
   and b.pos.x>=p.pos.x-b.r
   and b.pos.y>=p.pos.y-8-b.r
   and b.pos.x<=p.pos.x+7+b.r
   and b.pos.y<=p.pos.y+7+b.r then
    pop=true
    -- direct hits do extra damage
    p.health=max(0,p.health-25)
    goto end_balloon_update
   end
  end
  ::end_balloon_update::
  if pop then
   -- check for nearby players and
   -- assign splash damage
   local splash_dist2=K_SPLASH_DIST*K_SPLASH_DIST
   for _,p in ipairs(players) do
    local pc=v2add(p.pos,v2(4,4))
    if b.pid~=p.pid
    and v2dstsq(pc,b.pos)<splash_dist2 then
     p.health=max(0,p.health-25)
    end
   end
   local disth=K_SPLASH_DIST/2
   for i=1,50 do
    add(wparts,{
     pos=v2cpy(b.pos),
     vel=v2scl(v2rnd(),0.5+rnd(1)),
     ttl=disth+rnd()*K_SPLASH_DIST,
     color=i<10 and PID_COLORS[b.pid]
                 or C_LIGHTBLUE,
     pid=b.pid,
    })
   end
  else
   -- balloon survives to next frame
   add(balloons2,b)
  end
 end
 balloons=balloons2
 -- decrease health of all players
 -- and check for death
 for _,p in ipairs(players) do
  p.health=max(0,p.health-0.02)
  if p.health==0 then
   p.dead=true
  end
 end
 -- handle input & move players
 for _,p in ipairs(players) do
  local pb0=8*(p.pid-1)
  p.move.y=(btn(pb0+0) and -1 or 0)+(btn(pb0+1) and 1 or 0)
  p.move.x=(btn(pb0+2) and -1 or 0)+(btn(pb0+3) and 1 or 0)
  p.speed=(v2eq(p.move,v2zero))
   and max(p.speed-0.1,0)
   or  min(p.speed+0.1,0.6)
  -- TODO: walk one pixel at a time
  local s=p.speed
  if p.move.y<0 then -- up
   if  canwalk(p.fpos.x+1,p.fpos.y-s)
   and canwalk(p.fpos.x+6,p.fpos.y-s) then
    p.fpos.y=p.fpos.y-s
    if p.move.x==0 then
     if not canwalk(p.fpos.x,p.fpos.y) then
      p.fpos.x=(p.fpos.x+1)//1
     elseif not canwalk(p.fpos.x+7,p.fpos.y) then
      p.fpos.x=(p.fpos.x-1)//1
     end
    end
   end
  elseif p.move.y>0 then -- down
   if  canwalk(p.fpos.x+1,p.fpos.y+7+s)
   and canwalk(p.fpos.x+6,p.fpos.y+7+s) then
    p.fpos.y=p.fpos.y+s
    if p.move.x==0 then
     if not canwalk(p.fpos.x,p.fpos.y+7) then
      p.fpos.x=(p.fpos.x+1)//1
     elseif not canwalk(p.fpos.x+7,p.fpos.y+7) then
      p.fpos.x=(p.fpos.x-1)//1
     end
    end
   end
  end
  if p.move.x<0 then -- left
   if  canwalk(p.fpos.x-s,p.fpos.y+1)
   and canwalk(p.fpos.x-s,p.fpos.y+6) then
    p.fpos.x=p.fpos.x-s
    if p.move.y==0 then
     if not canwalk(p.fpos.x,p.fpos.y) then
      p.fpos.y=(p.fpos.y+1)//1
     elseif not canwalk(p.fpos.x,p.fpos.y+7) then
      p.fpos.y=(p.fpos.y-1)//1
     end
    end
   end
  elseif p.move.x>0 then -- right
   if  canwalk(p.fpos.x+7+s,p.fpos.y+1)
   and canwalk(p.fpos.x+7+s,p.fpos.y+6) then
    p.fpos.x=p.fpos.x+s
    if p.move.y==0 then
     if not canwalk(p.fpos.x+7,p.fpos.y) then
      p.fpos.y=(p.fpos.y+1)//1
     elseif not canwalk(p.fpos.x+7,p.fpos.y+7) then
      p.fpos.y=(p.fpos.y-1)//1
     end
    end
   end
  end
  p.pos.x=(p.fpos.x+0.5)//1
  p.pos.y=(p.fpos.y+0.5)//1
  -- update facing direction
  if p.move.x~=0 or p.move.y~=0 then
   p.dir=v2cpy(p.move)
  end
  -- update animation state
  local new_sn=p.anims.sn
  if v2eq(p.move,v2zero) then
   if p.dir.y<0 then new_sn="idleu" p.hflip=1
   elseif p.dir.y>0 then new_sn="idled" p.hflip=0
   else new_sn="idlelr" p.hflip=p.dir.x<0 and 1 or 0
   end
  else
   if p.move.y<0 then new_sn="walku" p.hflip=1
   elseif p.move.y>0 then new_sn="walkd" p.hflip=0
   else new_sn="walklr" p.hflip=p.move.x<0 and 1 or 0
   end
  end
  if new_sn~=p.anims.sn then
   p.anims:to(new_sn)
  else
   p.anims:nextv()
  end
  -- Update player's camera focus.
  p.focus.x=approach(p.focus.x,p.pos.x+4,.2)//1
  p.focus.y=approach(p.focus.y,p.pos.y+4,.2)//1
  -- handle throwing balloons
  if p.ammo>0 and btn(pb0+5) then
   p.windup=min(K_MAX_WINDUP,p.windup+1)
  elseif not btn(pb0+5)
  and p.windup>0 then
   p.ammo=max(p.ammo-1,0)
   local borig=balloon_origin(p.pos,p.dir)
   add(balloons,{
    pos0=v2cpy(borig),
    pos=v2cpy(borig),
    pos1=balloon_throw_target(p),
    t=0,
    t1=40*1,
    pid=p.pid,
    color=p.color,
    r=K_BALLOON_RADIUS,
   })
   p.windup=0
  end
 end
 -- update refill station pings
 local refill_pings2={}
 for _,rp in ipairs(refill_pings) do
  rp.radius=rp.radius+1
  if rp.radius<=K_MAX_PING_RADIUS then
   add(refill_pings2,rp)
  end
 end
 refill_pings=refill_pings2
 -- update refill stations
 for _,p in ipairs(players) do
  p.refill_cooldown=max(0,p.refill_cooldown-1)
  for _,r in ipairs(refills) do
   if p.refill_cooldown==0
   and p.pos.x+7>=r.pos.x
   and p.pos.x  <=r.pos.x+7
   and p.pos.y+7>=r.pos.y
   and p.pos.y  <=r.pos.y+7 then
    -- TODO play sound
    p.health=K_MAX_HEALTH
    p.ammo=K_MAX_AMMO
    p.refill_cooldown=K_REFILL_COOLDOWN
    add(refill_pings,{
     pos=v2add(r.pos,v2(4,4)),
     radius=0,
    })
   end
  end
 end
end

function cb_draw(_ENV)
 clip()
 cls(C_BLACK)
 -- draw each player's viewport
 for _,p in ipairs(players) do
  local pclip=clips[p.pid]
  clip(table.unpack(pclip))
  camera(-(p.vpcenter.x-p.focus.x),
         -(p.vpcenter.y-p.focus.y))
  -- draw map
  map(0,0,30*3,17*6,0,0)
  -- build list of draw calls
  local draws={}
  -- draw the players
  for _,p2 in ipairs(players) do -- draw corpses
   add(draws,{
    order=p2.pos.y,order2=p2.pos.x,
    f=draw_player,
    args={p2},
   })
  end
  -- draw water particles
  for _,wp in ipairs(wparts) do
   local c=wp.ttl<2 and C_DARKGREY
                     or wp.color
   add(draws,{
    order=wp.pos.y,order2=wp.pos.x,
    f=pix,
    args={wp.pos.x,wp.pos.y,c},
   })
  end
  -- draw balloons
  for _,b in ipairs(balloons) do
   add(draws,{
    order=b.pos.y,order2=b.pos.x,
    f=draw_balloon,
    args={b.pos.x,b.pos.y,
          b.r,b.color,b.t,b.t1},
   })
  end
  -- draw trees
  for _,t in ipairs(trees) do
   add(draws,{
    order=t.pos.y+1,order2=t.pos.x,
    f=spr,
    args={SID_TREE,t.pos.x-8,t.pos.y-28,
          C_TRANSPARENT,1,t.flip,0,3,4},
   })
  end
  -- draw bushes
  for _,b in ipairs(bushes) do
   add(draws,{
    order=b.pos.y,order2=b.pos.x,
    f=spr,
    args={SID_BUSH,b.pos.x,b.pos.y-8,
          C_TRANSPARENT,1,b.flip,
          0,1,2},
   })
  end
  -- draw monkey bars
  for _,m in ipairs(mbars) do
   add(draws,{
    order=m.pos.y,order2=m.pos.x,
    f=spr,
    args={SID_MBARS,m.pos.x,m.pos.y-16,
          m.colorkey,1,0,
          0,3,3},
   })
  end
  -- draw swings
  for _,s in ipairs(swings) do
   add(draws,{
    order=s.pos.y,order2=s.pos.x,
    f=spr,
    args={SID_SWING,s.pos.x,s.pos.y-16,
          C_TRANSPARENT,1,0,
          0,4,3},
   })
  end
  -- draw elephants
  for _,e in ipairs(elephants) do
   add(draws,{
    order=e.pos.y,order2=e.pos.x,
    f=spr,
    args={SID_ELEPHANT,e.pos.x-4,e.pos.y-8,
          C_TRANSPARENT,1,0,
          0,2,2},
   })
  end
  -- draw refill station pings
  for _,rp in ipairs(refill_pings) do
   add(draws,{
    order=rp.pos.y,order2=rp.pos.x,
    f=circb,
    args={rp.pos.x,rp.pos.y,
          rp.radius,rp.radius%16},
   })
  end
  -- draw refill stations
  for _,r in ipairs(refills) do
   add(draws,{
    order=r.pos.y,order2=r.pos.x,
    f=spr,
    args={SID_REFILL,r.pos.x-4,r.pos.y,
          C_TRANSPARENT,1,0,0,2,1},
   })
   if p.refill_cooldown>0 then
    local h=8*p.refill_cooldown/K_REFILL_COOLDOWN
    add(draws,{
     order=r.pos.y+7,order2=r.pos.x,
     f=rect,
     args={r.pos.x-1,r.pos.y+8-h,10,h,
           C_RED},
    })
   end
   -- sort and emit draw calls.
   -- TODO: rebuilding & sorting this
   -- table per-player is wasteful;
   -- it is mostly identical for all.
   table.sort(draws,
    function(a,b)
     return a.order<b.order
     or (a.order==b.order and a.order2<b.order2)
    end
   )
   for _,d in ipairs(draws) do
    d.f(table.unpack(d.args))
   end
  end
  -- restore screen-space camera
  camera(0,0)
  -- draw player health and ammo bars
  rectb(pclip[1]+2,pclip[2]+2,
        32,4,K_WHITE)
  rect( pclip[1]+3,pclip[2]+3,
        30*p.health/K_MAX_HEALTH,2,C_RED)
  for ib=1,p.ammo do
   circ(pclip[1]+34+ib*6,pclip[2]+4,2,p.color)
   circb(pclip[1]+34+ib*6,pclip[2]+4,2,C_BLACK)
  end
  -- for low-health/ammo players, draw "refill" prompt
  if p.health<0.3*K_MAX_HEALTH
  or p.ammo==0 then
   print("REFILL!",
         p.vpcenter.x-12,p.vpcenter.y-4,
         C_WHITE,true)
   local pc=p.focus
   local closest=v2(math.huge,math.huge)
   local closest_d2=v2dstsq(pc,closest)
   for _,r in ipairs(refills) do
    local rc=v2add(r.pos,v2(4,4))
    local d2=v2dstsq(pc,rc)
    if d2<closest_d2 then
     closest=v2cpy(rc)
     closest_d2=d2
    end
   end
   local closest_d=sqrt(closest_d2)
   if closest_d>40 then
    local closest_dir=v2scl(
     v2norm(v2sub(closest,pc)),
     min(30,closest_d))
    circ(p.vpcenter.x+closest_dir.x,
        p.vpcenter.y+closest_dir.y,
        1,C_WHITE)
   end
  end
  -- draw "game over" message for eliminated players
  if p.dead then
   rect(p.vpcenter.x-38,p.vpcenter.y-20,75,9,C_BLACK)
   rectb(p.vpcenter.x-38,p.vpcenter.y-20,75,9,p.color)
   local w=print("KILLED BY PX",p.vpcenter.x-36,p.vpcenter.y-18,p.color,true)
  end
  -- draw viewport border.
  rectb(pclip[1],pclip[2],pclip[3],pclip[4],p.color)
 end
end

function balloon_throw_target(p)
 local dist=lerp(K_MIN_THROW,K_MAX_THROW,
             p.windup/K_MAX_WINDUP)
 return v2add(v2add(p.pos,v2(4,4)),
              v2scl(p.dir,dist))
end

function balloon_origin(pos,dir)
 -- compute position where balloon
 -- is thrown from, given player pos/dir.
 -- includes the 4,4 offset to
 -- middle of player tile
 if dir.y<0 then
  return v2add(pos,v2(7,4)) -- up
 elseif dir.y>0 then
  return v2add(pos,v2(0,4)) -- down
 elseif dir.x<0 then
  return v2add(pos,v2(7,2)) -- left
 else
  return v2add(pos,v2(0,2)) -- right
 end
end

function draw_balloon(x,y,r,color,t,t1)
 local t=t or 0
 local t1=t1 or 1
 local yoff=6*sin(-0.5*t/t1)
 local rx,ry=r+sin(.03*t)/2,
             r+cos(1.5+.04*t)/2
 if t>0 then -- drop shadow
  elli(x,y+2,rx,2,C_DARKGREY)
 end
 elli(x,y-yoff,rx+1,ry+1,C_BLACK)
 elli(x,y-yoff,rx,ry,color)
end

function draw_player(player)
 local p=player
 -- draw player
 local prev=peek4(2*0x03FF0+4)
 poke4(2*0x03FF0+4,p.color)
 spr(p.anims.v,
     p.pos.x-4,
     p.pos.y-8,
     C_TRANSPARENT,1,p.hflip,0,2,2)
 poke4(2*0x03FF0+4,prev)
 -- draw balloon and reticle
 -- if winding up
 if p.windup>0 then
  local borig=balloon_origin(p.pos,p.dir)
  draw_balloon(borig.x,borig.y,
   K_BALLOON_RADIUS,p.color)
  local target=balloon_throw_target(p)
  line(target.x-1,target.y,
       target.x+1,target.y,C_WHITE)
  line(target.x,target.y-1,
       target.x,target.y+1,C_WHITE)
 end
end

-- <TILES>
-- 001:001122330511223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 002:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 032:0000000000000000000000000000000000000022002222202220000000200000
-- 033:0000000000000000000000000000000020000000000000200000202020202020
-- 034:0000220002222000220000002000220020202020202020202020220020002020
-- 035:0000002000002002220022002020202020202202220020002020000020000000
-- 048:0020020000200220002002020020020000200200002002000020000000200022
-- 049:2020202020220020202000202000000000000022000020000222200020000000
-- 050:2200202002002200020000002000000000000000000000000000000055555555
-- 051:0000000000000000000000000000000000000000000000000000000055555555
-- 064:0020220022220000200000000000000000000000000000000000000000000000
-- 065:0000000500000005000000050000000500000005000000050000000500000005
-- 066:00000000000000000000000000000000000000000000000000000000ff00000f
-- 068:5000000050000000500000005000000050000000500000005000000050000000
-- 081:0000000500000005000000050000000500000005000000050000000500000005
-- 084:5000000050000000500000005000000050000000500000005000000050000000
-- 096:2222322222223222222232223333333322223222222232222222322222223222
-- 097:dddd3ddddddd3ddddddd3ddd33333333dddd3ddddddd3ddddddd3ddddddd3ddd
-- 098:7777377777773777777737773333333377773777777737777777377777773777
-- 099:cccc3ccccccc3ccccccc3ccc33333333cccc3ccccccc3ccccccc3ccccccc3ccc
-- 100:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 112:110000111001100100b11b0000b11b000b1111b0000cc000100cc00111000011
-- 113:1100001117777771070c0c7007cccc7007000070070000701700007111000011
-- 114:1100001117777771070400700704007007040070070cc0701700007111000011
-- 115:1100001110aa000100acc0000055c20007552270074444701077770111000011
-- 116:1108881110888801008800000088800000088800000088001088880111888011
-- 117:11000711100887710078877007777707077777070000c007100c00011100c011
-- 118:110000111044000104dddd4004ddddd004ddddd0004444401000000111000011
-- 119:110b0011100b90010b090b900b9a09000ababab000a0ab0010b0b00111000011
-- 144:1111111111b11a111111111b11111aa411aaa4441a4444441a444444b4444444
-- 145:111aa11111b44a11bb4444a14444444b44444444444444444484444448444444
-- 146:11b1111111111111bbbbb11144444bbb44444444444444444444444444444444
-- 147:111111111b111b11111a111111111111b111b1114b11111144b11111444b11b1
-- 148:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 149:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 150:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 160:b4444444b4444444b44444441b44444411bbb44411111a44111b1a441b1111a4
-- 161:8444444444444444444444444444444444444444444444444444444444444444
-- 162:4444444444444444444844444444444444444444844444484844444444444444
-- 163:444b1111444b1a11444b11118844bb11444444b1444444b14444431144444311
-- 164:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 165:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 166:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 167:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 171:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 176:1111111a11111111111b111111111b11111a11111b1111111111b11111111111
-- 177:44444444aa44444411b44444111bb4441b111bbb11111111b11a1b1111111111
-- 178:44444444444444444444444344333331bb111111111b111111111a1111111111
-- 179:444331113331111111111b11111a111111111111b11b11111111111111111111
-- 180:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 181:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 182:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 183:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
-- 208:2222220222222202222222022222220222200000222022220000222222202222
-- 209:2222022222220222222202222222022200000000222022222220222222202222
-- 210:2022222220222222202222222022222200002222222022222220000022202222
-- 211:7777770777777707777777077777770777700000777077770000777777707777
-- 212:7777077777770777777707777777077700000000777077777770777777707777
-- 213:7077777770777777707777777077777700007777777077777770000077707777
-- 214:cccccc0ccccccc0ccccccc0ccccccc0cccc00000ccc0cccc0000ccccccc0cccc
-- 215:cccc0ccccccc0ccccccc0ccccccc0ccc00000000ccc0ccccccc0ccccccc0cccc
-- 216:c0ccccccc0ccccccc0ccccccc0cccccc0000ccccccc0ccccccc00000ccc0cccc
-- 217:4444440444444404444444044444440444400000444044440000444444404444
-- 218:4444044444440444444404444444044400000000444044444440444444404444
-- 219:4044444440444444404444444044444400004444444044444440000044404444
-- 224:2220222222202222222022220000222222202222222000002220222222202222
-- 225:3333333333333333333333333333333333333333333333333333333333333333
-- 226:2220222222202222222022222220000022202222000022222220222222202222
-- 227:7770777777707777777077770000777777707777777000007770777777707777
-- 228:3333333333333333333333333333333333333333333333333333333333333333
-- 229:7770777777707777777077777770000077707777000077777770777777707777
-- 230:ccc0ccccccc0ccccccc0cccc0000ccccccc0ccccccc00000ccc0ccccccc0cccc
-- 231:3333333333333333333333333333333333333333333333333333333333333333
-- 232:ccc0ccccccc0ccccccc0ccccccc00000ccc0cccc0000ccccccc0ccccccc0cccc
-- 233:4440444444404444444044440000444444404444444000004440444444404444
-- 234:3333333333333333333333333333333333333333333333333333333333333333
-- 235:4440444444404444444044444440000044404444000044444440444444404444
-- 240:2220222200002222222022222220222222200000222222022222220222222202
-- 241:2222022222220222222202222222022200000000222022222220222222202222
-- 242:2220222222200000222022222220222200002222202222222022222220222222
-- 243:7770777700007777777077777770777777700000777777077777770777777707
-- 244:7777077777770777777707777777077700000000777077777770777777707777
-- 245:7770777777700000777077777770777700007777707777777077777770777777
-- 246:ccc0cccc0000ccccccc0ccccccc0ccccccc00000cccccc0ccccccc0ccccccc0c
-- 247:cccc0ccccccc0ccccccc0ccccccc0ccc00000000ccc0ccccccc0ccccccc0cccc
-- 248:ccc0ccccccc00000ccc0ccccccc0cccc0000ccccc0ccccccc0ccccccc0cccccc
-- 249:4440444400004444444044444440444444400000444444044444440444444404
-- 250:4444044444440444444404444444044400000000444044444440444444404444
-- 251:4440444444400000444044444440444400004444404444444044444440444444
-- </TILES>

-- <SPRITES>
-- 000:55550000555033445503344455000000550ccee3550ecee3550eeeee5550eeee
-- 001:00555555440555554440555500000005e3e05555e3e05555eee05555ee055555
-- 002:55550000555033445503344455000000550ccee3550ecee3550eeeee5550eeee
-- 003:00555555440555554440555500000005e3e05555e3e05555eee05555ee055555
-- 004:55550000555033445503344455000000550ccee3550ecee3550eeeee5550eeee
-- 005:00555555440555554440555500000005e3e05555e3e05555eee05555ee055555
-- 006:003322330033223344556677445566778899aacc8899aaccccddeeffccddeeff
-- 007:555a99555559a9955555a99955a55ab9559a59ab559ab9ab5559abba9a599a33
-- 008:5a5555559a555555ba559955ab599a55a9b9a555ab9a99a539a999a5aab99a55
-- 009:5555555555555555555555555555555555555555555555555555555555555555
-- 010:5555555555555555555555555555555555555555555555555555555555555555
-- 011:5555555555555555555555555555555555555555555555555555555555555555
-- 012:5555555555555555555555555555555555555555555555555555555555555555
-- 013:555555555555555155555111555511115555111155511bb15551bbbb5511b11b
-- 014:5111bbb5111bbbbb11bbb5bb1bbbc5bb1bbbbcc1bbbbbb51bbbbbbbbbbbbbbbb
-- 015:55555555b5555555bbb55555bbbb55551bbb5555111bb5551111b555b111bb55
-- 016:55550000555034445503444455e3444455ee444455500000550f0555550ff055
-- 017:005555554405555544405555444e555544ee55550005555550f0555550ff0555
-- 018:5555000055503444550344445503444455e0444455ee00005550f0555550ff05
-- 019:00555555440555554440555544405555440e555500ee55550f0555550ff05555
-- 020:55550000555034445503444455e3444455ee44445555000055550f0055550ff0
-- 021:005555554405555544405555444e555544ee555500555555f0555555ff055555
-- 022:5555555555555555555555555555555555555555555555555555555555555555
-- 023:59ab93a355ab9ba3553abb3b5553a33a5a333aba55aa3bba555333b355555333
-- 024:3b99aba5b99aba95ba99ab9539bab955b9ba3a55b333a35533aa3b953a33b555
-- 025:5555555555555555555555555555555555555555555555555555555555555555
-- 026:5555555555555555555555555555555555555555555555555555555555555555
-- 027:5555554455555a4255554ccc5555222a55533333555377775555377755555333
-- 028:425555552aa555552cc25555a444555533333555777735557773555533355555
-- 029:55b1111b55b111bb55b1115b55b11ccb55bb1bbb555b11bb555bbbbb5555bbbb
-- 030:bbbbbbbbbbbbbbb1bbbbbbb1bbbbbb11bbbbb1bbbbbbbbbbbbbbbbbb11bbbbb1
-- 031:bbb1bb55bcb1bb55c5bbbb55bbbbbb55bbbbbb551bbbb55511bbb55511bb5555
-- 032:55550000555033445503344455000000550ce3ee550ce3ee550eeeee5550eeee
-- 033:005555554405555544405555000000053ec055553ec05555eee05555ee055555
-- 034:55550000555033445503344455000000550ce3ee550ce3ee550eeeee5550eeee
-- 035:005555554405555544405555000000053ec055553ec05555eee05555ee055555
-- 036:55550000555033445503344455000000550ce3ee550ce3ee550eeeee5550eeee
-- 037:005555554405555544405555000000053ec055553ec05555eee05555ee055555
-- 038:5555555555555555555555555555555555555555555555555555555555555555
-- 039:5555555555555555555555555555555555555555555555555555555555555555
-- 040:5555555555555555555555555555555555555555555555555555555555555555
-- 041:5555555555555555555555555555555555555555555555555555555555555555
-- 042:5555555555555555555555555555555555555555555555555555555555555555
-- 043:5555555555555555555555555555555555555555555555555558777855877777
-- 044:5575555558775555587775555587775555877775887777758877757587775575
-- 045:5555bbb155555bbb5555555b5555555555555555555555555555555555555555
-- 046:111bbb1111bbb111bbbbbbbb5bbbbbb555599555555c9555555c9555555cc555
-- 047:11bb55551bb55555b55555555555555555555555555555555555555555555555
-- 048:5555000055503444550344445503444455e0444455e000005550f05555555555
-- 049:005555554405555544405555444e5555440e5555005555550f0555550f055555
-- 050:5555000055503444550344445503444455e0444455e500005550f0555550f055
-- 051:00555555440555554440555544405555440e5555005e55550f0555550f055555
-- 052:55550000555034445503444455e3444455e04444555500005550f0555550f055
-- 053:00555555440555554440555544405555440e5555000e55550f05555555555555
-- 054:5555555555555555555555555555555555555555555555555555555555555555
-- 055:5555555555555555555555555555555555555555555555555555555555555555
-- 056:5555555555555555555555555555555555555555555555555555555555555555
-- 057:5555555555555555555555555555555555555555555555555555555555555555
-- 058:5555555555555555555555555555555555555555555555555555555555555555
-- 059:5757737757557377555557775555553355555555555555335555535555555533
-- 060:8777357577773575775555773355555555355555335555555555555533355555
-- 061:5555555555555555555555555555555555555555555555555555555555555555
-- 062:555cc555555cc555555cc555555cc555355cc553333333333737737337377373
-- 063:5555555555555555555555555555555555555555555555555555555555555555
-- 064:55550000555033445503344455000000550ccccc550ccccc550eeeee5550eeee
-- 065:00555555440555554440555500000005ccc05555ccc05555eee05555ee055555
-- 066:55550000555033445503344455000000550ccccc550ccccc550eeeee5550eeee
-- 067:00555555440555554440555500000005ccc05555ccc05555eee05555ee055555
-- 068:55550000555033445503344455000000550ccccc550ccccc550eeeee5550eeee
-- 069:00555555440555554440555500000005ccc05555ccc05555eee05555ee055555
-- 070:5555555555555555555555555555555555555555555555555555555555555555
-- 071:5555555555555555555555555555555555555555555555555555555555555555
-- 072:5555555555555555555555555555555555555555555555555555555555555555
-- 073:5555555555555555555555555555555555555555555555555555555555555555
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:5555555555555555555555555555555555555555555555555555555555555555
-- 077:5555555555555555555555555555555555555555555555555555555555555555
-- 078:5555555555555555555555555555555555555555555555555555555555555555
-- 079:5555555555555555555555555555555555555555555555555555555555555555
-- 080:55550000555034445503444455e3444455e04444555500005550f0555550f055
-- 081:00555555440555554440555544405555440e5555000e55550f05555555555555
-- 082:5555000055503444550344445503444455e0444455e500005550f0555550f055
-- 083:00555555440555554440555544405555440e5555005e55550f0555550f055555
-- 084:5555000055503444550344445503444455e0444455e000005550f05555555555
-- 085:005555554405555544405555444e5555440e5555005555550f0555550f055555
-- 086:5555555555555555555555555555555555555555555555555555555555555555
-- 087:5555555555555555555555555555555555555555555555555555555555555555
-- 088:5555555555555555555555555555555555555555555555555555555555555555
-- 089:5555555555555555555555555555555555555555555555555555555555555555
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:5555555555555555555555555555555555555555555555555555555555555555
-- 093:5555555555555555555555555555555555555555555555555555555555555555
-- 094:5555555555555555555555555555555555555555555555555555555555555555
-- 095:5555555555555555555555555555555555555555555555555555555555555555
-- 096:55550000555033445503344455000000550ccee3550ecee3550eeeee5550eeee
-- 097:00555555440555554440555500000005e3e05555e3e05555eee05555ee055555
-- 098:55550000555033445503344455000000550ccee3550ecde3550eedde5550eeee
-- 099:00555555440555554440555500000005e3d05555e3d05555eee05555ee055555
-- 100:55550000555033445503344455000000550ccee3550ecde3550eedde5550eeee
-- 101:00555555440555554440555500000005e3d05555e3d05555eee05555ee055555
-- 102:5555555555555555555555555555555555555555555555555555555555555555
-- 103:5555555555555555555555555555555555555555555555555555555555555555
-- 104:5555555555555555555555555555555555555555555555555555555555555555
-- 105:5555555555555555555555555555555555555555555555555555555555555555
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:5555555555555555555555555555555555555555555555555555555555555555
-- 109:5555555555555555555555555555555555555555555555555555555555555555
-- 110:5555555555555555555555555555555555555555555555555555555555555555
-- 111:5555555555555555555555555555555555555555555555555555555555555555
-- 112:5555000055503044555034ee555034ee55550044555500005550f055550ff055
-- 113:0055555544055555440555554405555544055555005555550f0555550ff05555
-- 114:55550000555034dd5e0344445e034dd4555044d45555000055550f005550ff00
-- 115:00555555440555554d40e5554dd0e5554405555500555555f0555555ff055555
-- 116:55550000555034dd555044445e034dd45e0534d45555000055550f005550ff00
-- 117:00555555440555554d0555554dd0e5554450e55500555555f0555555ff055555
-- 118:5555555555555555555555555555555555555555555555555555555555555555
-- 119:5555555555555555555555555555555555555555555555555555555555555555
-- 120:5555555555555555555555555555555555555555555555555555555555555555
-- 121:5555555555555555555555555555555555555555555555555555555555555555
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:5555555555555555555555555555555555555555555555555555555555555555
-- 125:5555555555555555555555555555555555555555555555555555555555555555
-- 126:5555555555555555555555555555555555555555555555555555555555555555
-- 127:5555555555555555555555555555555555555555555555555555555555555555
-- 128:5555555555577755557733755573537555735555557355555a73a55555999555
-- 129:5555555555577755557733755573537555735445557355555a73a55555999555
-- 130:5555555555577755557733755573537555735445557355455a73a55555999555
-- 131:5555555555577755557733755573537555735555557355455a73a54555999555
-- 132:5555555555577755557733755573537555735555557355555a73a55555999545
-- 133:55555555555555555577777757dddddd7dd4ddd474ddd4dd3777777753777777
-- 134:555555555555555577777755dd4ddd75dddddd47dddd4dd77777777777777775
-- 135:55555555555555555577777757d4ddd474ddd4dd7ddddddd3777777753777777
-- 136:555555555555555577477755dddddd45dddd4dd7ddddddd77777777777777775
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:5555555555555555555555555555555555555555555555555555555555555555
-- 139:5555555555555555555555555555555555555555555555555555555555555555
-- 140:5555555555555555555555555555555555555555555555555555555555555555
-- 141:5555555555555555555555555555555555555555555555555555555555555555
-- 142:5555555555555555555555555555555555555555555555555555555555555555
-- 143:5555555555555555555555555555555555555555555555555555555555555555
-- 144:ffffffffff5555fff555555f5555555ff555555fff5555ffffffffffffffffff
-- 145:fffffffffff555ffff55555ff555555f5555555ff55555ffff555fffffffffff
-- 146:5555555555555555555555555555555555555555555555555555555555555555
-- 147:5555555555555555555555555555555555555555555555555555555555555555
-- 148:5555555555555555555555555555555555555555555555555555555555555555
-- 149:5555555555555555555555555555555555555555555555555555555555555555
-- 150:5555555555555555555555555555555555555555555555555555555555555555
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:5555555555555555555555555555555555555555555555555555555555555555
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:5555555555555555555555555555555555555555555555555555555555555555
-- 155:5555555555555555555555555555555555555555555555555555555555555555
-- 156:5555555555555555555555555555555555555555555555555555555555555555
-- 157:5555555555555555555555555555555555555555555555555555555555555555
-- 158:5555555555555555555555555555555555555555555555555555555555555555
-- 159:5555555555555555555555555555555555555555555555555555555555555555
-- 160:5555555555555555455555557777777733333773435555754355557543555575
-- 161:5555555555555555555555557777777733773333557555555575555555755555
-- 162:5555555555555555555555557777777733377333555575555555755555557555
-- 163:5555555555555555555555547777777377333334755555347555553475555534
-- 164:ffffffffffffffffffffccccfff5f3fffff5f3fffff5ccccfff5f3fffff5f3ff
-- 165:ffffffffffffffffccccccccffffffffffffffffccccccccffffffffffffffff
-- 166:ffffffffffffffffccccffffff3f5fffff3f5fffcccc5fffff3f5fffff3f5fff
-- 167:5555555555555555555555555555555555555555555555555555555555555555
-- 168:5555555555555555555555555555555555555555555555555555555555555555
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:5555555555555555555555555555555555555555555555555555555555555555
-- 171:5555555555555555555555555555555555555555555555555555555555555555
-- 172:5555555555555555555555555555555555555555555555555555555555555555
-- 173:5555555555555555555555555555555555555555555555555555555555555555
-- 174:5555555555555555555555555555555555555555555555555555555555555555
-- 175:5555555555555555555555555555555555555555555555555555555555555555
-- 176:4355557543555575453555754535557545355575453555754535557545355575
-- 177:5575555555755555557555555575555555755555557555555575555555755555
-- 178:5555755555557555555575555555755555557555555575555555755555557555
-- 179:7555553475555534755553547555535475555354755553547555535475555354
-- 180:fff5ccccfff5f3fffff5f3ffff5ff3ffff5ff3ffff5ff3ffff5ff3ffff5ff3ff
-- 181:ccccccccffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 182:cccc5fffff3f5fffff3f5fffff3ff5ffff3ff5ffff3ff5ffff3ff5ffff3ff5ff
-- 183:5555555555555555555555555555555555555555555555555555555555555555
-- 184:5555555555555555555555555555555555555555555555555555555555555555
-- 185:5555555555555555555555555555555555555555555555555555555555555555
-- 186:5555555555555555555555555555555555555555555555555555555555555555
-- 187:5555555555555555555555555555555555555555555555555555555555555555
-- 188:5555555555555555555555555555555555555555555555555555555555555555
-- 189:5555555555555555555555555555555555555555555555555555555555555555
-- 190:5555555555555555555555555555555555555555555555555555555555555555
-- 191:5555555555555555555555555555555555555555555555555555555555555555
-- 192:4535557545355575455355754553557545535ccc455355554553555545555555
-- 193:55755555557555555575555555755555cccc5555555555555555555555555555
-- 194:55557555555575555555755555557555555ccccc555555555555555555555555
-- 195:75555354755553547555355475553554cc553554555535545555355455555554
-- 196:ff5ff3ffff5ff3ffff5ff3ffff5ff3ffff5ff3ffff5ff3ffff5ff3ffff5ff3ff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:ff3ff5ffff3ff5ffff3ff5ffff3ff5ffff3ff5ffff3ff5ffff3ff5ffff3ff5ff
-- 199:5555555555555555555555555555555555555555555555555555555555555555
-- 200:5555555555555555555555555555555555555555555555555555555555555555
-- 201:5555555555555555555555555555555555555555555555555555555555555555
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 206:5555555555555555555555555555555555555555555555555555555555555555
-- 207:5555555555555555555555555555555555555555555555555555555555555555
-- 208:5555555555555555555555555555555555555555555555555555555555555555
-- 209:5555555555555555555555555555555555555555555555555555555555555555
-- 210:5555555555555555555555555555555555555555555555555555555555555555
-- 211:5555555555555555555555555555555555555555555555555555555555555555
-- 212:5555555555555555555555555555555555555555555555555555555555555555
-- 213:5555555555555555555555555555555555555555555555555555555555555555
-- 214:5555555555555555555555555555555555555555555555555555555555555555
-- 215:5555555555555555555555555555555555555555555555555555555555555555
-- 216:5555555555555555555555555555555555555555555555555555555555555555
-- 217:5555555555555555555555555555555555555555555555555555555555555555
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 222:5555555555555555555555555555555555555555555555555555555555555555
-- 223:5555555555555555555555555555555555555555555555555555555555555555
-- 224:5555555555555555555555555555555555555555555555555555555555555555
-- 225:5555555555555555555555555555555555555555555555555555555555555555
-- 226:5555555555555555555555555555555555555555555555555555555555555555
-- 227:5555555555555555555555555555555555555555555555555555555555555555
-- 228:5555555555555555555555555555555555555555555555555555555555555555
-- 229:5555555555555555555555555555555555555555555555555555555555555555
-- 230:5555555555555555555555555555555555555555555555555555555555555555
-- 231:5555555555555555555555555555555555555555555555555555555555555555
-- 232:5555555555555555555555555555555555555555555555555555555555555555
-- 233:5555555555555555555555555555555555555555555555555555555555555555
-- 234:5555555555555555555555555555555555555555555555555555555555555555
-- 235:5555555555555555555555555555555555555555555555555555555555555555
-- 236:5555555555555555555555555555555555555555555555555555555555555555
-- 237:5555555555555555555555555555555555555555555555555555555555555555
-- 238:5555555555555555555555555555555555555555555555555555555555555555
-- 239:5555555555555555555555555555555555555555555555555555555555555555
-- 240:5555555555555555555555555555555555555555555555555555555555555555
-- 241:5555555555555555555555555555555555555555555555555555555555555555
-- 242:5555555555555555555555555555555555555555555555555555555555555555
-- 243:5555555555555555555555555555555555555555555555555555555555555555
-- 244:5555555555555555555555555555555555555555555555555555555555555555
-- 245:5555555555555555555555555555555555555555555555555555555555555555
-- 246:5555555555555555555555555555555555555555555555555555555555555555
-- 247:5555555555555555555555555555555555555555555555555555555555555555
-- 248:5555555555555555555555555555555555555555555555555555555555555555
-- 249:5555555555555555555555555555555555555555555555555555555555555555
-- 250:5555555555555555555555555555555555555555555555555555555555555555
-- 251:5555555555555555555555555555555555555555555555555555555555555555
-- 252:5555555555555555555555555555555555555555555555555555555555555555
-- 253:5555555555555555555555555555555555555555555555555555555555555555
-- 254:5555555555555555555555555555555555555555555555555555555555555555
-- 255:5555555555555555555555555555555555555555555555555555555555555555
-- </SPRITES>

-- <MAP>
-- 016:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009dadadadadadadadadadadadadadadadadadafafafafafafafbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009e4646464646464646464646464646464646464646464646469fbd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009e464646464646464646464646464646464646464646464646469fbd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009e4646464646464646464646464646464646464646464646464646be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000009dadadadadbf46464646469dadadadadadadadadadadadadadbd464646464646be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:00000000000000000000000000000000000000000000000000000000000000000000000000000000be464646464646464646469e00000000000000000000000000be464646464646be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:00000000000000000000000000000000000000000000000000000000000000000000000000000000be464646091929394646469e00000000000000000000000000be464646460746be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:00000000000000000000000000000000000000000000000000000000000000000000000000000000be4646460a1a2a3a4677779e00000000000000009dadadbd00be464646464646be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:00000000000000000000000000000000000000000000000000000000000000000000000000000000be4646460b1b2b3b4677779e00000000000000009e46379e00be464617171746be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:00000000000000000000000000000000000000000000000000000000000000000000000000000000be464646464646464677779e00000000000000009e46469e00be464646464646be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:00000000000000000000000000000000000000000000000000000000000000000000000000000000be464646464646464677779e00000000000000009e07469e00be464646464646be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:00000000000000000000000000000000000000000000000000000000000000000000000000000000be464646464646464646469e00000000000000009e46469e00be464646467777be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:0000000000000000000000000000000000000000000000000000000000009dadadadadadadadadadbf461717174646464646469e00000000000000009e46469e00be464646467777be0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:000000000000000000000000000000000000000000000000000000000000be37777777774646464646464646464646464646469fafafafafafafafafbf77779fafbf464646469dafbf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:000000000000000000000000000000000000000000000000000000000000be4646464646464646464646464646464646464646464646464646464646464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:000000000000000000000000000000000000000000000000000000000000be4646464646464646464646464646464646464646074646464646464646464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:000000000000000000000000000000000000000000000000000000000000be4627272727464646464646464646464646464646464646464646467746464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:000000000000000000000000000000000000000000000000000000000000be4646464646464646464646464646464657464646464646464646464677464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:0000000000000000000000000000000000000000000000000000000000009fafafafafaf5d464646464646464746464646464646464646464646464646464646464646463dafbf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000000000000000000000000000000000000000000000000000000000000000000000005e464646464646464646465746464646464646464646464646464646464646463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:0000000000000000000000000000000000000000000000000000000000000000000000005e464646460746464646464646464646464646464646464646464646464646463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:0000000000000000000000000000000000000000000000000000000000000000000000005e464646464646464646464646464646464646464646465746574627272727463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:0000000000000000000000000000000000000000000d1d1d1d1d1d1d1d1d2d00000000005e464646464646464646464646464646091929394646464646464646464646463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:00000000000000000000000000000000000d1f1f1f2f46464646464646460e00000000005e4677464646464646464646464646460a1a2a3a46463d4f4f4f4f4f4f4f4f4f5f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:000000000000000000000000000000000d2f4646464646464646464646460e00000000005e4646774646464646464646464646460b1b2b3b46463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000d2f464646464607460746074607460e00000000005e4646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000000000000000000000d2f46464646464646464646374646460e00000000005e4646464646464646464646464646464646464646463e003d4d4d4d4d4d4d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000d2f4646464646464646464646464646460e00000000005e4646464646464646774646464646464646464646463e003e4646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000000000000000000e464646464746464646460919293946460e00000000005e4646464646774646464677464646467a46464646463f4f5f4646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000e465746464646464677770a1a2a3a46460e00000000005e4646074646464646464646464646467b46464646464646464646464746465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:000000000000000000000000000e464646464646464677770b1b2b3b46460e00000000005e4646464646464677464646464646462727272746464646464646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:000000000000000000000000000e464646464646464646464646464646460e00000000005e4617171746464646464646464657464646464646463d4d5d4646463746465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:000000000000000000000000000e464646464646464646464646464646460e00000000005e4646464646464646464646464646464646464646463e003e4646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000e464646464646464646464646464646460e00000000005e46464646464646463d4d4d4d4d4d5d4646464646463e003f4f4f4f4f4f4f5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000e464646464646464646464646464646460e00000000005e46464646464646463e46464646465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:000000000000000000000000000e464646464646464646464646464646460e00000000005e46464646464646463e46464646465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:000000000000000000000000000e464646460d1d1d1d1d1d2d46464646460e00000000005e46464646464646463e46464646465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:000000000000000000000000000e464646070e00000000002e46464646460e00000000005e46464646464646463e46074607465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:000000000000000000000000000e464646460e00000000002e46464646460e00000000005e46464646464646463e46463746465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:000000000000000000000000000e464607460e00000d1f1f2f46464646460e00000000005e46464646464646467777773d4f4f5f4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:000000000000000000000000000e464646460e00000e46464646464646460e00000000005e46464646464646467777773e7777464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:000000000000000000000000000e464646070f1f1f2f46574646464646463f4f4f4f4f4f5f46464646464646463e77773e4646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 058:000000000000000000000000000e464646464646464646464646464646464646464646464646464646464646463f4f4f5f4646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:000000000000000000000000000e46464646464646464646464646464646464646464646464646464646464646464677774646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:000000000000000000000000000e46464646464646464646464646464646464646464646464646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:000000000000000000000000000f2d464646464646464646464646464646464646464646464646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:00000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:0000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:000000000000000000000000000000000f2d464677464646464646464646464646464646574646464646464646464677464646464646073746463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:00000000000000000000000000000000000f1f1f1f2d46464646464646463d4d4d4d4d4d5d4646464646464646464646774646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:0000000000000000000000000000000000000000002e46464646464646460e00000000005e4646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:0000000000000000000000000000000000000000002e46464646464646460f2d000000005e4646464646464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:0000000000000000000000000000000000000000002e4646464646464677770f2d0000005e4646464646464646464646464646463d4f4f4f4f4f5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 069:0000000000000000000000000000000000000000002e464646464646467777370f2d00005e4646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:0000000000000000000000000000000000000000002e46464646464646464677770f1f1f2f4646464646464646464646464646466f7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d8d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:0000000000000000000000000000000000000000002e464646464646464646777746464646464646464646464646464646464646464646464646464646464646464646464646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:0000000000000000000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646467777464657464646464646464646464646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:000000000000000000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646460919293946464646460746468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:00000000000000000000000000000000000000000000000f2d464646464646464646464646464646465746464646464646464646272727274646464646460a1a2a3a46464646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000000000000000000000000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646464646464646460b1b2b3b46464646474646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:000000000000000000000000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 077:00000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f7f7f7f8d464646464646464646464646464646466d7d8d464646466d7d7d8d4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 078:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e008e464646468e00008e4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 079:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e008e464646468e00008e4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 080:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646460919293946464646468e008e464646468e00008e4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 081:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646460a1a2a3a46464646468e008e464646466f7d7d8f4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 082:000000000000000000000000000000000000000000000000000000000000000000000000000000008e461717174646460b1b2b3b46464646468e008e46464646777746464646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 083:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e008e46464646777777774646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 084:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e008e46464646464677774646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e008e464646466d7d7d8d4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e008e464646468e00008e4646465746468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e006f7f7f7f7f8f00008e4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e0000000000000000008e4646463746468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e0000000000000000008e4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 090:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646272727274646464646468e0000000000000000008e4646464646468e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 091:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e0000000000000000006f7f7f7f7f7f7f8f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646463746464646464646468e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646074607468e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:000000000000000000000000000000000000000000000000000000000000000000000000000000008e464646464646464646464646464646468e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:000000000000000000000000000000000000000000000000000000000000000000000000000000006f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0023456789abcdffffdcba9876543200
-- 002:02469a96786777890b6c861204a257e9
-- </WAVES>

-- <SFX>
-- 000:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100304000000000
-- 016:030723007300a300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300300000000000
-- 017:a007600620050004000300010000000d000b00085008a008f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000b60000000000
-- 048:01000100210041006100a100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100300000000000
-- 049:020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200300000000000
-- 056:23008300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300500000000000
-- </SFX>

-- <PATTERNS>
-- 000:400807100811b00807100811400807100811b00807100811400807100811b00807100811400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801
-- 001:00000080088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000060088b00000040088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000040088b60088b80088b00000000000040088b00000000000000000000000040088b00000000000060088b00000000000000000000000040088b00000000000040088b00000000000000000000000070088b00000000000040088bd0088900000050088b
-- 002:002c110fc911800817100811b00817d00817b00817100811400817100811000000000000100811000000400819100811000000000000e00817d00817e00817100811b00817100811000000000000000000000000000000000000900817800817900817100811800817100811b00817d00817b00817100811800817100811400817e00815100811000811600817100811800817100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:002c110cf91140081b100811e00819d00819e0081910081180081910081100000000000080081b10081140081b100811000000000000800819600819800819100811900819100811000000000000000000000000000000000000e00819d00819b0081910081140081b100811e00819b00819d00819100811e00819100811d00819b00819100811000811e00819100811b00819100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <FLAGS>
-- 000:00001000101000001010000000000000000000001010100010100000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010101010101000000000000000001010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100010101010000000101010101010101010101010100000001000101000101000101000101000000010101010101010101010101010000000
-- </FLAGS>

-- <PALETTE>
-- 000:00000074b72ea858a82936403b5dc9ff0006ff79c2566c87f4f4f42571794cda85466d1ded820e41a6f6ffe5b4ffe761
-- </PALETTE>

