-- title:   Water Balloons At Dawn
-- author:  Bitterly Indifferent Games
-- desc:    A playground water-balloon fight for 2-4 players.
-- site:    github.com/cdwfs/wbad
-- license: Creative Commons Zero v1.0 Universal
-- version: 0.1
-- script:  lua

------ GLOBALS

-- constants
K_MAX_ENERGY=100
K_ENERGY_HIT=25
K_ENERGY_SPLASH=10
K_ENERGY_WALK=0.02 -- drain per frame
K_ENERGY_RUN=0.1 -- drain per frame
K_ENERGY_WARNING=0.3*K_MAX_ENERGY
K_MAX_RUN_SPEED=1.0
K_MAX_WALK_SPEED=0.6
K_MAX_AMMO=5
K_MAX_PING_RADIUS=600
K_REFILL_COOLDOWN=60*5
K_MAX_WINDUP=60
K_MIN_THROW=20
K_MAX_THROW=70
K_BALLOON_RADIUS=2
K_SPLASH_DIST=14
-- palette color indices
TEAM_COLORS={2,15,4,12}
TEAM_NAMES={"Purple","Yellow","Blue","Orange"}
C_WHITE=8
C_BLACK=0
C_DARKGREY=3
C_DARKGREEN=11
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
SF_BLOCK_PLAYER=0
SF_BLOCK_BALLOON=1

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

-- a0,a1,b0,b1 are v2 bounds of two rects
function rects_overlap(a0,a1,b0,b1)
 return a1.x>=b0.x and a0.x<=b1.x
    and a1.y>=b0.y and a0.y<=b1.y
end

-- print with a drop-shadow
function dsprint(msg,x,y,c,cs,...)
 print(msg,x-1,y+1,cs,...)
 print(msg,x,y,c,...)
end

-- palette fade
original_palette={} -- 48 RGB bytes
function fade_init_palette()
 for i=0,47 do
  original_palette[i]=peek(0x3FC0+i)
 end
end
-- Sets the palette to (1-t)*original
-- t=0: master palette (no change)
-- t=1: fully black
function fade_black(t)
 local s=clamp(1-t,0,1)
 for i=0,47 do
  poke(0x3FC0+i,original_palette[i]*s//1)
 end
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
  victory=vt_enter,
 }
 game_mode="menu"
 next_mode,next_mode_enter_args=game_mode,nil
 cls(0)
 local mode_args={}
 mode_obj=mode_enters[game_mode](mode_args)
 mode_frames=0
 game_frames=0
end

update_time_history={}
draw_time_history={}
show_fps=false
function TIC()
 local t0=time()
 mode_obj:update()
 local t1=time()
 mode_obj:draw()
 local t2=time()
 local round2=function(x)
  return (10*x//1)*0.1
 end
 local update_ms=round2(t1-t0)
 local   draw_ms=round2(t2-t1)
 update_time_history[1+mode_frames%60]=update_ms
 draw_time_history[1+mode_frames%60]=draw_ms
 local update_avg=0
 local draw_avg=0
 for i=1,#draw_time_history do
  update_avg=update_avg+update_time_history[i]
  draw_avg=draw_avg+draw_time_history[i]
 end
 update_avg=round2(update_avg/#update_time_history)
 draw_avg=round2(draw_avg/#draw_time_history)
 camera()
 clip()
 if btnp(6) then show_fps=not show_fps end
 if show_fps then
  print("update: "..update_ms.." avg: "..update_avg,4,4,C_WHITE,true)
  print("  draw: "..draw_ms.." avg: "..draw_avg,4,12,C_WHITE,true)
 end
 process_frame_hooks_by_mode(game_mode,"exec")
 mode_frames=mode_frames+1
 if next_mode~=game_mode then
  mode_obj:leave()
  game_mode=next_mode
  mode_frames=0
  mode_obj=mode_enters[game_mode](next_mode_enter_args)
 end
 game_frames=game_frames+1
end

------ MENU

mm={}

function menu_enter(args)
 sync(1|2|4|32,1)
 camera(0,0)
 cls(0)
 music(MUS_MENU)
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  30)
 mm=obj({
  update=menu_update,
  draw=menu_draw,
  leave=menu_leave,
  player_count=args.player_count or 2, -- must be 2-4
  ignore_input=false,
 })
 return mm
end

function menu_leave(_ENV)
 clip()
 music()
end

function menu_update(_ENV)
 -- input
 if not ignore_input then
  if btnp(2) then
   player_count=(player_count-2+2)%3+2
  elseif btnp(3) then
   player_count=(player_count-2+1)%3+2
  end
  if btnp(4) then
   ignore_input=true
   -- fade to black & advance to next mode
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     set_next_mode("combat",{
      player_count=player_count,
     })
    end,
    60)
  end
 end
end

function menu_draw(_ENV)
 cls(C_LIGHTBLUE)
 map(0,0,30,1,0,0)
 map(0,1,14,16,0,8)
 spr(256, 14*8,8, -1, 1,0,0, 16,16)
 spr(128, 48,4, C_TRANSPARENT, 1,0,0,
     16,5)
 dsprint("< "..player_count.." kids >",
         34,90,C_WHITE,C_BLACK,true)
 dsprint("  Help",34,98,
         C_WHITE,C_BLACK,true)
 dsprint("  Credits",34,106,
         C_WHITE,C_BLACK,true)
end

------ COMBAT

cb={}

function cb_enter(args)
 sync(1|2|4|32,0)
 fade_init_palette()
 -- fade in from black
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  60)
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
  end_hook=nil,
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
     bounds0=v2(mx*8-8, my*8-24),
     bounds1=v2(mx*8+15,my*8+7),
    })
    mset(mx,my,TID_GRASS_NOMOVE)
   elseif tid==TID_SPAWN_MBARS then
    add(cb.mbars,{
     pos=v2(mx*8,my*8),
     bounds0=v2(mx*8,my*8-16),
     bounds1=v2(mx*8+23,my*8+7),
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
     bounds0=v2(mx*8, my*8-16),
     bounds1=v2(mx*8+31, my*8+7),
    })
    -- swings are 4 tiles wide
    for x=mx,mx+3 do
     mset(x,my,TID_GRASS_NOMOVE)
    end
   elseif tid==TID_SPAWN_ELEPHANT then
    add(cb.elephants,{
     pos=v2(mx*8,my*8),
     bounds0=v2(mx*8-4, my*8-8),
     bounds1=v2(mx*8+11,my*8+7),
    })
    mset(mx,my,TID_GRASS_NOMOVE)
   elseif tid==TID_SPAWN_REFILL then
    add(cb.refills,{
     pos=v2(mx*8,my*8),
     bounds0=v2(mx*8-5, my*8),
     bounds1=v2(mx*8+5, my*8+8),
    })
    mset(mx,my,TID_GRASS)
   elseif tid==TID_SPAWN_PLAYER then
    add(cb.player_spawns,v2(mx,my))
    mset(mx,my,TID_GRASS)
   elseif tid==TID_SPAWN_BUSH then
    local dx,dy=rnd(4)//1,rnd(7)//1
    add(cb.bushes,{
     pos=v2(mx*8+dx,my*8+dy),
     flip=flr(rnd(2)),
     bounds0=v2(mx*8+dx-8,my*8+dy-8),
     bounds1=v2(mx*8+dx+7,my*8+dy+7),
    })
    mset(mx,my,TID_GRASS)
   end
  end
 end
 -- spawn players
 cb_init_players(cb)
 return cb
end

function create_player(pid,team)
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
    It tracks the player's position, but
    lags slightly.
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
  color=TEAM_COLORS[team],
  pid=pid,
  team=team,
  running=false,
  speed=0, -- how far to move in current dir per frame
  energy=K_MAX_ENERGY,
  ammo=K_MAX_AMMO,
  refill_cooldown=0,
  eliminated=false,
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
  local team=pid -- TODO: plumb this in from menu
  local p=create_player(pid,team)
  -- choose a spawn tile
  local ispawn=math.random(#cb.player_spawns)
  p.fpos=v2scl(
   v2cpy(cb.player_spawns[ispawn]),8)
  table.remove(cb.player_spawns,ispawn)
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

function canwalk(px,py)
 local t=mget((px+0.5)//8,(py+0.5)//8)
 return not fget(t,SF_BLOCK_PLAYER)
end

function cb_update(_ENV)
 -- hack: kill all other players to
 -- advance to victory
 if btnp(7) then
  for _,p in ipairs(players) do
   if p.pid>1 then
    p.energy=0
    p.eliminated=true
   end
  end
 end
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
  local ms=mget((b.pos.x+0.5)//8,
                (b.pos.y+0.5)//8)
  if b.t>b.t1 then
   pop=true
   goto end_balloon_update
  end
  b.pos=v2lerp(b.pos0,b.pos1,b.t/b.t1)
  -- collide with terrain
  if fget(ms,SF_BLOCK_BALLOON) then
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
    p.energy=max(0,p.energy-K_ENERGY_HIT)
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
     p.energy=max(0,p.energy-K_ENERGY_SPLASH)
    end
   end
   local disth=K_SPLASH_DIST/2
   for i=1,50 do
    add(wparts,{
     pos=v2cpy(b.pos),
     vel=v2scl(v2rnd(),0.5+rnd(1)),
     ttl=disth+rnd()*K_SPLASH_DIST,
     color=i<10 and b.color or C_LIGHTBLUE,
     team=b.team,
    })
   end
  else
   -- balloon survives to next frame
   add(balloons2,b)
  end
 end
 balloons=balloons2
 -- decrease energy of all players
 -- and check for elimination
 for _,p in ipairs(players) do
  local drain = p.running
    and K_ENERGY_RUN or K_ENERGY_WALK
  p.energy=max(0,p.energy-drain)
  if p.energy==0 and not p.eliminated then
   p.eliminated=true
   p.hflip=0
   p.ammo=0 -- prevents throwing
   p.windup=0 -- cancel existing throw
   p.refill_cooldown=0
   p.anims:to("idlelr") -- TODO: defeat
   -- TODO other time-of-elimination
   -- effects go here
  end
 end
 -- handle input & move players
 for _,p in ipairs(players) do
  if p.eliminated then
   goto player_update_end
  end
  local pb0=8*(p.pid-1)
  p.move.y=(btn(pb0+0) and -1 or 0)+(btn(pb0+1) and 1 or 0)
  p.move.x=(btn(pb0+2) and -1 or 0)+(btn(pb0+3) and 1 or 0)
  p.running=btn(pb0+4)
  local max_speed=p.running
    and K_MAX_RUN_SPEED
     or K_MAX_WALK_SPEED
  p.speed=(v2eq(p.move,v2zero))
   and max(p.speed-0.1,0)
   or  min(p.speed+0.1,max_speed)
  -- TODO: walk one pixel at a time
  -- to make sure we don't get stuck
  -- in an obstacle
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
    team=p.team,
    color=p.color,
    r=K_BALLOON_RADIUS,
   })
   p.windup=0
  end
  ::player_update_end::
 end
 -- update refill station pings
 local refill_pings2={}
 for _,rp in ipairs(refill_pings) do
  rp.radius=rp.radius+2
  if rp.radius<=K_MAX_PING_RADIUS then
   add(refill_pings2,rp)
  end
 end
 refill_pings=refill_pings2
 -- update refill stations
 for _,p in ipairs(players) do
  if p.eliminated then
   goto refill_update_end
  end
  p.refill_cooldown=max(0,p.refill_cooldown-1)
  for _,r in ipairs(refills) do
   if p.refill_cooldown==0
   and rects_overlap(
    p.pos,v2add(p.pos,v2(7,7)),
    r.pos,v2add(r.pos,v2(7,7))) then
    -- TODO play sound
    p.energy=K_MAX_ENERGY
    p.ammo=K_MAX_AMMO
    p.refill_cooldown=K_REFILL_COOLDOWN
    add(refill_pings,{
     pos=v2add(r.pos,v2(4,4)),
     radius=0,
    })
   end
  end
  ::refill_update_end::
 end
 -- Check for end of match
 if not end_hook then
  local live_teams={}
  for _,p in ipairs(players) do
   if not p.eliminated then
    live_teams[p.team]=true
   end
  end
  local winning_team=nil
  local live_team_count=0
  for team,_ in pairs(live_teams) do
   winning_team=team
   live_team_count=live_team_count+1
  end
  if live_team_count<=1 then
   local player_teams={}
   for _,p in ipairs(players) do
    add(player_teams,p.team)
   end
   -- fade to black & advance to next mode
   end_hook=add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     set_next_mode("victory",{
      player_count=all_player_count,
      player_teams=player_teams,
      winning_team=live_team_count>0
       and winning_team or 0,
     })
    end,
    60)
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
  -- compute culling rectangle extents,
  -- in world-space pixels.
  local clipdim=v2(pclip[3],pclip[4])
  local cull0=v2flr(
   v2sub(p.focus,v2scl(clipdim,0.5)))
  local cull1=v2add(cull0,clipdim)
  local cull_padding=v2(2,2)
  cull0=v2sub(cull0,cull_padding)
  cull1=v2add(cull1,cull_padding)
  -- draw map
  local m0=v2(cull0.x//8,cull0.y//8)
  map(m0.x,m0.y,
      (cull1.x-cull0.x+7)//8,
      (cull1.y-cull0.y+7)//8 + 1,
      m0.x*8,m0.y*8)
  -- build list of draw calls inside
  -- the culling rect
  local draws={}
  -- draw players
  for _,p2 in ipairs(players) do -- draw corpses
   if rects_overlap(cull0,cull1,
       v2add(p2.pos,v2(-8,-8)),
       v2add(p2.pos,v2(8,8))) then
    elli(p2.pos.x+4,p2.pos.y+7,
         5,2,C_DARKGREEN)
    add(draws,{
     order=p2.pos.y, order2=p2.pos.x,
     f=draw_player, args={p2}
    })
   end
  end
  -- draw water particles
  -- TODO: maybe a draw-call per
  -- particle is overkill?
  for _,wp in ipairs(wparts) do
   if rects_overlap(cull0,cull1,
       wp.pos, wp.pos) then
    local c=wp.ttl<2 and C_DARKGREY
                      or wp.color
    add(draws,{
     order=wp.pos.y, order2=wp.pos.x,
     f=pix, args={
      wp.pos.x, wp.pos.y, c
     }
    })
   end
  end
  -- draw balloons
  for _,b in ipairs(balloons) do
   if rects_overlap(cull0,cull1,
       v2sub(b.pos,v2(b.r+2,b.r+2)),
       v2add(b.pos,v2(b.r+2,b.r+8))) then
    elli(b.pos.x,b.pos.y+2,b.r,2,C_DARKGREEN)
    add(draws,{
     order=b.pos.y, order2=b.pos.x,
     f=draw_balloon, args={
      b.pos.x, b.pos.y,
      b.r, b.color, b.t, b.t1
     }
    })
   end
  end
  -- draw trees
  for _,t in ipairs(trees) do
   if rects_overlap(cull0,cull1,
       t.bounds0, t.bounds1) then
    elli(t.pos.x+4, t.pos.y+7,
     10,3,C_DARKGREEN)
    add(draws,{
     order=t.pos.y+1, order2=t.pos.x,
     f=function(t)
      spr(SID_TREE,t.pos.x-8,t.pos.y-24,
       C_TRANSPARENT, 1,t.flip,0, 3,4)
     end, args={t}
    })
   end
  end
  -- draw bushes
  for _,b in ipairs(bushes) do
   if rects_overlap(cull0,cull1,
       b.bounds0, b.bounds1) then
    elli(b.pos.x,b.pos.y+7,
         8,2,C_DARKGREEN)
    add(draws,{
     order=b.pos.y, order2=b.pos.x,
     f=function(b)
      spr(SID_BUSH, b.pos.x-8, b.pos.y-8,
       C_TRANSPARENT, 1,b.flip,0, 2,2)
     end, args={b}
    })
   end
  end
  -- draw monkey bars
  for _,m in ipairs(mbars) do
   if rects_overlap(cull0,cull1,
       m.bounds0, m.bounds1) then
    line(m.pos.x,m.pos.y+7,
         m.pos.x+23,m.pos.y+7,C_DARKGREEN)
    line(m.pos.x+6,m.pos.y+5,
         m.pos.x+17,m.pos.y+5,C_DARKGREEN)
    add(draws,{
     order=m.pos.y, order2=m.pos.x,
     f=function(m)
      spr(SID_MBARS, m.pos.x, m.pos.y-16,
       m.colorkey, 1,0,0, 3,3)
     end, args={m}
    })
   end
  end
  -- draw swings
  for _,s in ipairs(swings) do
   if rects_overlap(cull0,cull1,
       s.bounds0, s.bounds1) then
    line(s.pos.x+1,s.pos.y+5,
         s.pos.x+26,s.pos.y+5,C_DARKGREEN)
    elli(s.pos.x+10,s.pos.y+6,4,1,C_DARKGREEN)
    elli(s.pos.x+21,s.pos.y+6,4,1,C_DARKGREEN)
    add(draws,{
     order=s.pos.y, order2=s.pos.x,
     f=function(s)
      spr(SID_SWING, s.pos.x, s.pos.y-16,
       C_TRANSPARENT, 1,0,0, 4,3)
     end, args={s}
    })
   end
  end
  -- draw elephants
  for _,e in ipairs(elephants) do
   if rects_overlap(cull0,cull1,
       e.bounds0,e.bounds1) then
    elli(e.pos.x+4,e.pos.y+7,7,2,C_DARKGREEN)
    add(draws,{
     order=e.pos.y, order2=e.pos.x,
     f=function(e)
      spr(SID_ELEPHANT, e.pos.x-4, e.pos.y-8,
       C_TRANSPARENT, 1,0,0, 2,2)
     end, args={e}
    })
   end
  end
  -- draw refill station pings
  for _,rp in ipairs(refill_pings) do
   if rects_overlap(cull0,cull1,
       v2sub(rp.pos,v2(rp.radius,rp.radius)),
       v2add(rp.pos,v2(rp.radius,rp.radius))) then
    add(draws,{
     order=rp.pos.y, order2=rp.pos.x,
     f=function(rp)
      circb(rp.pos.x, rp.pos.y,
            rp.radius, rp.radius%16)
     end, args={rp}
    })
   end
  end
  -- draw refill stations
  for _,r in ipairs(refills) do
   if rects_overlap(cull0,cull1,
       r.bounds0,r.bounds1) then
    elli(r.pos.x+4,r.pos.y+7,6,2,C_DARKGREEN)
    add(draws,{
     order=r.pos.y, order2=r.pos.x,
     f=function(r,cooldown)
      spr(SID_REFILL, r.pos.x-4, r.pos.y,
       C_TRANSPARENT, 1,0,0, 2,1)
      if cooldown>0 then
       local h=8*p.refill_cooldown/K_REFILL_COOLDOWN
       rect(r.pos.x-1,r.pos.y+8-h,
        10,h,C_RED)
      end
     end, args={r,p.refill_cooldown}
    })
   end
   -- sort and emit draw calls.
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
  -- draw player energy and ammo bars
  rectb(pclip[1]+2,pclip[2]+2,
        32,4,K_WHITE)
  rect( pclip[1]+3,pclip[2]+3,
        30*p.energy/K_MAX_ENERGY,2,C_RED)
  for ib=1,p.ammo do
   circ(pclip[1]+34+ib*6,pclip[2]+4,2,p.color)
   circb(pclip[1]+34+ib*6,pclip[2]+4,2,C_BLACK)
  end
  -- for low-energy/ammo players, draw "refill" prompt
  if p.energy<K_ENERGY_WARNING
  or p.ammo==0 then
   dsprint("REFILL!",
         p.vpcenter.x-12,p.vpcenter.y+20,
         C_WHITE,C_DARKGREY)
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
  if p.eliminated then
   rect(p.vpcenter.x-38,p.vpcenter.y-20,75,9,C_BLACK)
   rectb(p.vpcenter.x-38,p.vpcenter.y-20,75,9,p.color)
   local w=print("ELIMINATED!",p.vpcenter.x-36,p.vpcenter.y-18,p.color,true)
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

---- victory

vt={}
function vt_enter(args)
 sync(1|2|32,0)
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  30)
 camera(0,0)
 clip()
 vt=obj({
  update=vt_update,
  draw=vt_draw,
  leave=vt_leave,
  player_count=args.player_count,
  player_teams=args.player_teams,
  winning_team=args.winning_team,
  players={},
  grnd_y=80,
  drop_spawns={},
  drops={},
 })
 -- create players evenly spaced
 local x0,x1=60,180
 local dx=(x1-x0)/(vt.player_count-1)
 for pid=1,vt.player_count do
  local p=create_player(pid,
           vt.player_teams[pid])
  p.pos=v2(flr(x0+(pid-1)*dx-4),
           vt.grnd_y)
  p.y0=vt.grnd_y
  add(vt.players,p)
  p.anims:nextv()
 end
 -- Make a list of all pixels in a
 -- sprite that are not transparent.
 local sprites={258,259,274,275}
 for _,s in ipairs(sprites) do
  local sx,sy=(s-sprites[1])%16,
              (s-sprites[1])//16
  local a=0x6000+32*(s-256)
  for y=0,7 do
   for x=0,7 do
    local c=peek4(2*a+y*8+x)
    if c~=C_TRANSPARENT then
     add(vt.drop_spawns,
      v2(sx*8+x-4,sy*8+y-8))
    end
   end
  end
 end
 return vt
end

function vt_leave(_ENV)
 clip()
 music()
end

function vt_update(_ENV)
 -- go back to main menu
 if btnp(0*8+4) or btnp(1*8+4)
 or btnp(2*8+4) or btnp(3*8+4) then
  set_next_mode("menu",{
   player_count=player_count,
  })
 end
 -- update water drops
 local drops2={}
 for _,d in ipairs(drops) do
  d.vel=v2add(d.vel,v2(0,0.1))
  d.pos=v2add(d.pos,d.vel)
  if d.pos.y<d.y1 then
   add(drops2,d)
  end
 end
 drops=drops2
 -- update players
 for _,p in ipairs(players) do
  if p.team==winning_team then
   -- bounce the winners
   p.pos.y=p.y0-
           10*abs(sin(mode_frames/60))
  else
   -- spawn water drops on the losers
   if mode_frames%6==0 then
    local dsp=drop_spawns[math.random(#drop_spawns)]
    add(drops,{
     pos=v2add(p.pos,dsp),
     y1=p.pos.y+7,
     vel=v2(0,0),
    })
   end
  end
 end
end

function vt_draw(_ENV)
 cls(C_DARKGREY)
 -- draw message
 local msg=(winning_team==0)
   and "It's a tie!"
    or ""..TEAM_NAMES[winning_team].." Team wins!"
 local msgw=print(msg,0,200)
 dsprint(msg,120-msgw/2,100,
  TEAM_COLORS[winning_team],C_BLACK)
 -- draw players
 for _,p in ipairs(players) do
  if p.team==winning_team then
   local srx=lerp(5,3,(p.y0-p.pos.y)/10)
   local sry=lerp(2,1,(p.y0-p.pos.y)/10)
   elli(p.pos.x+4,p.y0+7,srx,sry,C_DARKGREEN)
  else
   elli(p.pos.x+4,p.y0+7,6,3,C_LIGHTBLUE)
  end
  draw_player(p)
 end
 -- draw water drops
 for _,d in ipairs(drops) do
  pix(d.pos.x,d.pos.y,C_LIGHTBLUE)
 end
end
-- <TILES>
-- 002:111111111b1111b1111a111111111111111111b1111111111b111b1111111111
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
-- 160:b4444444b4444444b44444441b44444411bbb44411111a44111b1a441b1111a4
-- 161:8444444444444444444444444444444444444444444444444444444444444444
-- 162:4444444444444444444844444444444444444444844444484844444444444444
-- 163:444b1111444b1a11444b11118844bb11444444b1444444b14444431144444311
-- 166:1b111111b11111a1111a1111111111111111111111111111111111b111b11111
-- 167:111111111b1111b111b111111111b1111111a1111a11111111b1111111111111
-- 168:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 172:111111111111b11111111177111177b71b177777111777371171777717777777
-- 173:1111b11111111111b77777177777777777777737777777777737777777777777
-- 174:11111111711b11117711111171771111777771b1777771117737b71177777711
-- 176:1111111a11111111111b111111111b11111a11111b1111111111b11111111111
-- 177:44444444aa44444411b44444111bb4441b111bbb11111111b11a1b1111111111
-- 178:44444444444444444444444344333331bb111111111b111111111a1111111111
-- 179:444331113331111111111b11111a111111111111b11b11111111111111111111
-- 183:11b111111b1111b11b111b11a1111111111b11111a11b111111b1a1111111111
-- 188:117777771117377711777777b177777711777777117777371177777711b77777
-- 189:777377777b77777777777777777771777777777777777773177777777777b777
-- 190:77777b117777771173777711777777117777771b777777117773711177777711
-- 204:11777777117b7377111777771b17777711117717111111771111b11711111111
-- 205:77777777777773777777777773777777777777777177777b11111111111b1111
-- 206:777777717777171173777111777771b17b77111177111111111b111111111111
-- 208:0000000002222202022222020222220202200000022022220000222202202220
-- 209:0000000022220222222202222222022200000000222022222220222200000000
-- 210:0000000020222220202222202022222000002220222022202220000002202220
-- 211:000000000fffff0f0fffff0f0fffff0f0ff000000ff0ffff0000ffff0ff0fff0
-- 212:00000000ffff0fffffff0fffffff0fff00000000fff0fffffff0ffff00000000
-- 213:00000000f0fffff0f0fffff0f0fffff00000fff0fff0fff0fff000000ff0fff0
-- 214:000000000ccccc0c0ccccc0c0ccccc0c0cc000000cc0cccc0000cccc0cc0ccc0
-- 215:00000000cccc0ccccccc0ccccccc0ccc00000000ccc0ccccccc0cccc00000000
-- 216:00000000c0ccccc0c0ccccc0c0ccccc00000ccc0ccc0ccc0ccc000000cc0ccc0
-- 217:0000000004444404044444040444440404400000044044440000444404404440
-- 218:0000000044440444444404444444044400000000444044444440444400000000
-- 219:0000000040444440404444404044444000004440444044404440000004404440
-- 220:111111111b1177b711777777177737171b777777177777771137777717777771
-- 221:1b11111177777177777777777737777777777777777b777717777377111111a1
-- 222:11111111717b71b173777711777777117777377177777771777717b117777771
-- 224:0220222002202220022022200000222002202220022000000220222002202220
-- 225:3333333333333333333333333333333333333333333333333333333333333333
-- 226:0220222002202220022022200220000002202220000022200220222002202220
-- 227:0ff0fff00ff0fff00ff0fff00000fff00ff0fff00ff000000ff0fff00ff0fff0
-- 228:3333333333333333333333333333333333333333333333333333333333333333
-- 229:0ff0fff00ff0fff00ff0fff00ff000000ff0fff00000fff00ff0fff00ff0fff0
-- 230:0cc0ccc00cc0ccc00cc0ccc00000ccc00cc0ccc00cc000000cc0ccc00cc0ccc0
-- 231:3333333333333333333333333333333333333333333333333333333333333333
-- 232:0cc0ccc00cc0ccc00cc0ccc00cc000000cc0ccc00000ccc00cc0ccc00cc0ccc0
-- 233:0440444004404440044044400000444004404440044000000440444004404440
-- 234:3333333333333333333333333333333333333333333333333333333333333333
-- 235:0440444004404440044044400440000004404440000044400440444004404440
-- 236:177777711777777a117777311777777117777b7117737771b777777117777711
-- 238:17777711777777b777777777777377777777717717b777777777737717777771
-- 240:0220222000002222022022220220222202200000022222020222220200000000
-- 241:0000000022220222222202222222022200000000222022222220222200000000
-- 242:0220222022200000222022202220222000002220202222202022222000000000
-- 243:0ff0fff00000ffff0ff0ffff0ff0ffff0ff000000fffff0f0fffff0f00000000
-- 244:00000000ffff0fffffff0fffffff0fff00000000fff0fffffff0ffff00000000
-- 245:0ff0fff0fff00000fff0fff0fff0fff00000fff0f0fffff0f0fffff000000000
-- 246:0cc0ccc00000cccc0cc0cccc0cc0cccc0cc000000ccccc0c0ccccc0c00000000
-- 247:00000000cccc0ccccccc0ccccccc0ccc00000000ccc0ccccccc0cccc00000000
-- 248:0cc0ccc0ccc00000ccc0ccc0ccc0ccc00000ccc0c0ccccc0c0ccccc000000000
-- 249:0440444000004444044044440440444404400000044444040444440400000000
-- 250:0000000044440444444404444444044400000000444044444440444400000000
-- 251:0440444044400000444044404440444000004440404444404044444000000000
-- 252:177777711b717777177777771773777711777777117777371b17b71711111111
-- 254:177777717777731177777771777777b171737771777777117b7711b111111111
-- </TILES>

-- <TILES1>
-- 001:3333373333333733333337333333377333333773333337733333377333333773
-- 002:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfffff
-- 003:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccfffffccc
-- 004:ccccccccccccccccccccccccccccccccccccccccccccccc4ccff4c4ffff44c4f
-- 005:cccccccccccccccccccccccccccccccccccccccc4444ccccf4444cccf44444cc
-- 006:1b1b1bbbbbbbb1bbbbb1bbbbbbb11b1b1bbbbb11111bbbbb11b1bbb1bbbbbbbb
-- 007:bbbbbbbbb1bbbbbbb1bbbbbbbbbbbb11bbbbbbb11bbbbbb1bbbbbb11bbbbbbbb
-- 008:bb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbb
-- 009:bbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 010:3733337337333373373333733733337337333373373333733733337337333773
-- 011:33ee777733ee7777337e7777333e7777333ee777333ee777333ee7773333e777
-- 012:ccccccccccccccccccccccccccccccc5ccccccc5ccccc555ccccc555ccccc555
-- 013:c555555555555555555555555555555555555555555555555555555555555555
-- 014:5555555555555555555555555555555555555555555555555555555555555555
-- 015:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 017:3333337333333373333333733333337333333773333337733333377333333773
-- 018:ccff4444cff44444cff44444cf444444cf444444c4444447c4443777cc437777
-- 019:4444ffff44444ffc44444ffc4444444c444444cc777eeccc7777eccc7777eccc
-- 020:f44cc444ccccc444ccccc444ccccc444ccccc744ccccce77ccccce77ccccce77
-- 021:444444cc444444cc444444cc444444cc44444ccc444ccccccccccccccccccccc
-- 026:373337333733373337333733b73337337733773333377b333777733337333333
-- 027:3333ee773333ee773333be773333bbe733333be733333bbe33333bbb33333bbb
-- 028:cccccccccccccbbbcccccbb1cccccbb1cccccbbbcccccbbbcccccccbccccccce
-- 029:bbbbccccbb1bbcccbbbbbccc11bbbcccbbbbbcccbbbbbccc7bbbcccc7b77cccc
-- 030:ccccbbbbccbbbbbbcbb33bbbcbb3bbbbcbbbbbbbcbb33333c7333777c7737777
-- 031:111cccccbb11ccccbbb111ccbbbb1111bbbbbbbb37eecccc777ecccc777ecccc
-- 032:3333377333333773333337733333377333333773333337733333377333333773
-- 033:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccf
-- 034:cc337777cc337777cc337777cc377777ccc77777ccc7777ef4444444f4444444
-- 035:777eeccc777ecccc777ecccc77eecccceeeecccceecccccc444fffff44444444
-- 036:ccccce77ccccce77ccccce77ccccce77ccccee77cccce777fccce777ffcee777
-- 037:3333333333333333333333333333333333333333bbbbb333bbbbbbbbbb1bbbbb
-- 038:333337333333373333333733333337333333333333333333bbbbb733bbbbb733
-- 039:3337333333373333333733333337333333373333333733333337333333373333
-- 040:3333377333333773333337733333377b3333377b333337773333337733333377
-- 042:bbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 043:3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 044:ccccccceccccccceccccccceccccccceccccccceccccccceccccccceccccccce
-- 045:777ccccc777ccccc777ccccc777ccccc777ccccc777fffff777f111be7711bbb
-- 046:cc777777cc777777cc777777cc777777cc777777ff7777eebbbbbbbbbbbbbbbb
-- 047:77eecccc77eccccc7eeccccc7eeccccceecccccceccccccc8bccccccbb1ccccc
-- 048:3333373333333733333337333333373333333733333337333333373333333733
-- 049:ccccccffcccccff4cccccf44cccccf44cccccf44cccccf44ccccff44ccccf444
-- 050:4444444444444444444444444444444444444444444444444444444444444444
-- 051:4444444444444444444444444444444444444444444444444444444f4444444f
-- 052:4f4e7777444777774447777744477777444777774447777cfccccccccccccccc
-- 053:b11bbbbbb11bbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbb
-- 054:bbbbb7771bbbb7771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb
-- 055:7737333377777777bbb7777bbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbbbbb1bbbb
-- 056:3333333777733337b777bbbbbbbbbbbbbbbbbb1bbbbb11bbbbbbb1bbbbbbb1bb
-- 058:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 060:cccccccecccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 061:e711bbbbe11bb11be111111111111111c1111111cccc1111ccccccc1ccccccc1
-- 062:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 063:bbb8ccccbbbb8cccbbbb18ccbbbbb18cbbbbb18cbbbbbb18bbbbbb11bbbb1bb1
-- 064:3333333333333333337333333373333333773333333733333337333333377333
-- 065:ccccf444ccccf444ccccf444ccccf444ccccf444ccccf444cccc4444cccc4444
-- 067:4444444f4444444f4444444f444444fc444444fc444444fc444444cc444444cc
-- 068:333333333333333333333333bbbbbbbbbbbbbbbb1bbbbb1b1bbbbbbb1bbbbbb1
-- 069:333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbb
-- 070:333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbbbbb
-- 071:333333333333333333333333bbbbbbbbbbbbbbbbb11bbbbb111bbbbb11bbbbbb
-- 072:333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 073:333333333333333333333333bbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 074:333333333333333333333333bbbbbbbbbbb1bbbbbbbbbb11bbbbb111bbbbbbbb
-- 075:333333333333333333333333bbbbbbb3bbbbbb77bbbbb773bbbbb73311111b33
-- 077:ccccccc1ccccccc1ccccccc1cccccc11cccccc11cccccc11cccccc11cccccc11
-- 079:bbbb1bb1bbbb1bb1bbbb1bb1bbbb1bb1bbbb1bbebbbb11bebbbbb1eebbbbb1e7
-- 080:3337333333377333333373333337733333377333333773333337733333373333
-- 081:cccc4444cccc4444cccc4444cccc4444cccc4444cccc4444cccc4444cccc4444
-- 083:444444cc444444cc444444cc444444cc444444cc444444cc444444cc444444cc
-- 084:bbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbb1bbbbbbbbbbbbbbbbbbbbbbb
-- 085:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111bbbbbbbbbb1bb1bbbbb1b1bbbbb1b
-- 086:bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbb1b1bb1bb11bbbbbbbbbbbbbbbbbb
-- 087:1bbbbbbbbb11bbbbbb1bbbbbbbbbbbbb1bbbbbbbb1bbbbbb1111bbbbbbb1bbbb
-- 088:bbbb1bbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbb
-- 089:bbbbb1bbb1bbbbb1b11bbbbbbbbbbbbbbbbbbbb1bbb1bbbbbbbbbbbbbbbbbb11
-- 090:bbbbbb1bbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11bb1bbbb
-- 091:11bbbbb31bbbbbbbbbbbb111b1bbbbbbbb1bbbbbbbbb11bbbbbbbbbbb11bbbbb
-- 092:cccccccccccccccccccccccccccccccccccccccc333333333333333333333333
-- 093:cccccc11cccccc11cccccc11cccccc11cccccc11333333113333333133333331
-- 095:bbbbbee7bbbbbe77bbbbbe77bbbbee77bbbbee77bbeee777bbe7e777bbe7e777
-- 096:cccccccccccccccccccccccccccccccccccccccc3ccccccc3333333333333333
-- 097:cccc4444cccc4444cccc4444cccc4444cccc4444cccc44443333444433334444
-- 099:444444cc444444cc444444cc444444cc444444cc444444334444443344444433
-- 100:bbbbbbbb11bbbbbbb1bbbbbbbbbbbbbbbbbb1111bbbb1bbbbbbbbbbbbbbbbbbb
-- 101:bbbbbbbbbbb11bbbbbbb1b11bbbbbbb1bbbbbbbbbbbbb1bbbbbbbb1bbbbbbbbb
-- 102:11bbbbb1bb111bb1bbbbbbbbbbbbbbbbbbb1bbbbbb1bbb111bbbbbbbbbbbbbbb
-- 103:1bbbbbbbbbbbb1bbbbbbb1bb1bbbbbbbb1bb1b1bb1bbbbb11bbbbbbbbbbbbbbb
-- 104:11bbbbbb111bbbbbbbbbbbbbb1bbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbb
-- 105:bbbbb111bbbbb111bbb1bbbbbbb1b1bbbbbb1b1bbbbbbbbbbbbbb1bbbbbbbbbb
-- 106:bbbbbb1bb11bbbbbb1bbbbbbbb1bbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 107:bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbb1bbbbbb
-- 109:3333333133333331333333313333333333333333333333333333333333333333
-- 110:1bbbbbbb1bbbbbbb1bbbbbbb11bbbbbb77333333733333337333333373333333
-- 111:bbe7e777bbe7e777bbe7e777bbe7ee7733e77e7733e77e7733e77e7733e77e77
-- 113:3334444433344444333444443333444433334444333344333333373333333733
-- 114:4444444444444444444444444433333333333333333333333333333333333333
-- 115:4444443344333733333377333333773333333733333337333333373333333733
-- 125:3333333333333333333333333333333333333333333333333333333333333333
-- 126:7333333373333333733333337333333373333333733333737333337373333373
-- 127:33e77e7733e77ee733e7777733e7777733e7777733e7777733e7777733e77777
-- 128:5555555555555555555555555555555555550000555500005555000055550000
-- 129:5555555555555555555555555555555555555555555555550555555505555555
-- 130:5555555555555555555555555555555555555555555555555555555555555555
-- 131:5555555555555555555555555555555555555555555555555555555555555555
-- 132:5555555555555555555555555555555555555555555555555555555555000055
-- 133:5555555555555555555555555555000055550000555500005555000055550000
-- 134:5555555555555555555555550000000500000000000000000000000055550000
-- 135:5555555555555555555555555555555505555555005555550055555500555555
-- 136:5555555555555555555555555555555555555555555555555555555555555555
-- 137:5555555555555555555555555555555555555555500000000000000000000000
-- 138:5555555555555555555555555555555555555555555555550555555500005555
-- 139:5555555555555555555555555555555555555555555555555555555555555555
-- 140:5555555555555555555555555555555555555000555550005555500055555000
-- 141:5555555555555555555555555555555500055555000000550000000000000000
-- 142:5555555555555555555555555555555555555555555555550555555500055555
-- 143:5555555555555555555555555555555555555555555555555555555555555555
-- 144:5555000055555000555550005555500055555000555550005555500055555000
-- 145:0555555505555555055555550555555505555555055555550055555500555555
-- 146:5555555555555555555555555555555555555555555555555555555555555555
-- 147:5555555555555555555555555555555555555555555555555555555055555550
-- 148:5500005550000055500000555000005500000555000005550000055500005555
-- 149:5555000055550000555500005555000055550000555500005555000055550000
-- 150:5555550055555500555555005555550055555000555500005555000055000000
-- 151:0055555500555555005555550055555500555555005555550055555500555555
-- 152:5555555555555555555555555555555555555555555555555555555555555555
-- 153:0000000000005000000055000000555500005555000055550000555500005555
-- 154:0000055500000055000000555000000550000005550000005550000055500000
-- 155:5555555555555555555555555555555555555555555555555555555505555555
-- 156:5555500055555000555550005555500055555000555550005555500055555000
-- 157:0000000005500000055555000555555005555555055555550555555505555555
-- 158:0000555500000055000000050000000050000000555000005555000055555000
-- 159:5555555555555555555555555555555505555555055555550555555500555555
-- 160:5555500055555500555555005555550055555500555555005555550055555500
-- 161:0055555500555555005555550055555500555555000555550005555000055550
-- 162:5555555555555555555555555555555500005555000005550000055500000055
-- 163:5555550055555500555555005555500055550000555500005550000055500000
-- 164:0000555500055555000555550055555500555555005555550555555555555555
-- 165:5555000055550000555500005555000055550000555500005555000055550000
-- 166:0000000000000000000000000000000055555500555555555555555555555555
-- 167:0555555500055555000055550000555500000555000005550000055550000555
-- 168:5555555555555550555555505555555055555550555555505555550055555500
-- 169:0000555500005555000055550000555500055555000000000000000000000000
-- 170:5555000055550000555550005555550055555500000000000000000000000000
-- 171:0055555500555555000555550005555500055555000055550000555500000555
-- 172:5555500055555000555550005555500055555000555550005555500055555000
-- 173:0555555505555555055555550555555505555555055555550555555505555555
-- 174:5555500055555000555555005555550055555500555555005555550055555500
-- 175:0055555500555555005555550055555500555555005555550055555500555555
-- 176:5555555055555550555555505555555555555555555555555555555555555555
-- 177:0000555000005500000000000000000000000000500000005000000055000000
-- 178:0000005500000055000000050000000500000000055000000550000005550000
-- 179:5500000055000005500000055000005550000055000005550000055500000555
-- 180:5555555555555555555555555555555555555555555555555555555555555555
-- 181:5555000055500000555000005550000055500005555000055550000555500005
-- 182:5555555555555555555555555555555555555550555555005555000055500000
-- 183:5000055550000555000005550000055500000555000055550000555500055555
-- 184:5555550055555500555555005555500055555000555500005555000055550000
-- 185:0000000000555555005555550055555500555555005555550555555505555555
-- 186:0000000055555555555555555555555555555555555555555555555555555555
-- 187:0000055500000555500005555000005550000055500000555500005555000055
-- 188:5555500055555000555550005555500055555000555550005555500055555000
-- 189:0555555505555555055555550555555505555555055555550550000000000000
-- 190:5555500055555000555550005550000055500000000000000000000000000005
-- 191:0055555500555555005555550555555505555555055555555555555550000555
-- 192:5555555555555555555555555555555555555555555555555555555555555555
-- 193:5500000055500000555000005550000555555555555555555555555555555555
-- 194:0555000055555000555550005555550055555555555555555555555555555555
-- 195:0000555500005555000555550005555555555555555555555555555555555555
-- 196:5500005555000055550000555500005555555555555555555555555555555555
-- 197:5550000555500000555000005550000055500000555550005555555555555555
-- 198:0000000000000000000000050000005500005555005555555555555555555555
-- 199:0005555505555555555500005555000055550000555500005555555555555555
-- 200:5555000055555555555555555555555555555555555555555555555555555555
-- 201:5555555555555555555555555555555555555555555555555555555555555555
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5500005555000050555555505555555055555550555555555555555555555555
-- 204:5555500000055000000550000005500000055555555555555555555555555555
-- 205:0000000000000000000000550555555555555555555555555555555555555555
-- 206:0000005500055555555555555555555555555555555555555555555555555555
-- 207:5000055550000555500005555555555555555555555555555555555555555555
-- </TILES1>

-- <SPRITES>
-- 000:555550005555033455503344555000005550ccee5550ecee5550eeee55550eee
-- 001:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 002:555550005555033455503344555000005550ccee5550ecee5550eeee55550eee
-- 003:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 004:555550005555033455503344555000005550ccee5550ecee5550eeee55550eee
-- 005:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 006:003322330033223344556677445566778899aacc8899aaccccddeeffccddeeff
-- 007:555000055550a9905500a99950a00ab9509a09ab509ab9ab5009abba0a099a33
-- 008:005555559a050055ba009905ab099a05a9b9a055ab9a99a039a999a0aab99a05
-- 009:5000055050a9905050a9990b000abb9a0a09aaba0ab9aaba09abbba30099a33a
-- 010:05555555a0500555a0099055b099a0559b9a0555b9a99a059a999a05ab99a055
-- 011:5555555555555555555555555555555555555555555555555555555555555555
-- 012:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 013:55555555555555505555500155550111555011115550111155011bb15501bbbb
-- 014:500000050111bbb0111bbbbb11bbb5bb1bbbc5bb1bbbbcc1bbbbbb51bbbbbbbb
-- 015:5555555555555555b0055555bbb05555bbbb05551bbb0555111bb0551111b055
-- 016:555550005555034455503444555e3444555ee444555500005550f0555550ff05
-- 017:0005555544405555444405554444e555444ee55500005555550f0555550ff055
-- 018:55555000555503445550344455503444555e0444555ee00055550f0555550ff0
-- 019:000555554440555544440555444405554440e555000ee55550f0555550ff0555
-- 020:555550005555034455503444555e3444555ee44455555000555550f0555550ff
-- 021:0005555544405555444405554444e555444ee555000555550f0555550ff05555
-- 022:5555555555555555555555555555555555555555555555555555555555555555
-- 023:09ab93a350ab9ba3503abb3b5003a33a0a333aba50aa3bba550333b355500333
-- 024:3b99aba0b99aba90ba99ab9039bab905b9ba3a05b333a30533aa3b903a33b005
-- 025:0ab93a330ab9ba3b03abb3bb003a33a30333abab0aa3bbab50333b3355000333
-- 026:b99aba0599aba905a99ab9059bab90559ba3a055333a30553aa3b9053a33b005
-- 027:555555005555504455550a4255504ccc55033333550377775550377755550333
-- 028:00555555420555552aa055552cc2055533333055777730557773055533305555
-- 029:5011b11b50b1111b50b111bb50b1115b50b11ccb50bb1bbb550b11bb550bbbbb
-- 030:bbbbbbbbbbbbbbbbbbbbbbb1bbbbbbb1bbbbbb11bbbbb1bbbbbbbbbbbbbbbbbb
-- 031:b111bb05bbb1bb05bcb1bb05c5bbbb05bbbbbb05bbbbbb051bbbb05511bbb055
-- 032:555550005555033455503344555000005550ce3e5550ce3e5550eeee55550eee
-- 033:00055555444055554444055500000555e3ec0555e3ec0555eeee0555eee05555
-- 034:555550005555033455503344555000005550ce3e5550ce3e5550eeee55550eee
-- 035:00055555444055554444055500000555e3ec0555e3ec0555eeee0555eee05555
-- 036:555550005555033455503344555000005550ce3e5550ce3e5550eeee55550eee
-- 037:00055555444055554444055500000555e3ec0555e3ec0555eeee0555eee05555
-- 038:5555555555555555555555555555555555555555555555555555555555555555
-- 039:5555555555555555555555555555555555555555555555555555555555555555
-- 040:5555555555555555555555555555555555555555555555555555555555555555
-- 041:5555555555555555555555555555555555555555555555555555555555555555
-- 042:5555555555555555555555555555555555555555555555555555555555555555
-- 043:5555555555555555555555505555555055555555555555505550000855087788
-- 044:5055555507055555870055558777055508777055087777058777770587770705
-- 045:5550bbbb5550bbb155550bbb5555500b55555550555555555555555555555555
-- 046:11bbbbb1111bbb1111bbb111bbbbbbbb0bbbbbb050099005550c9055550c9055
-- 047:11bb055511bb05551bb05555b005555505555555555555555555555555555555
-- 048:55555000555503445550344455503444555e0444555e000055550f0555555555
-- 049:0005555544405555444405554444e5554440e5550005555550f0555550f05555
-- 050:55555000555503445550344455503444555e0444555e500055550f0555550f05
-- 051:000555554440555544440555444405554440e5550005e55550f0555550f05555
-- 052:555550005555034455503444555e3444555e04445555500055550f0555550f05
-- 053:000555554440555544440555444405554440e5550000e55550f0555555555555
-- 054:5555555555555555555555555555555555555555555555555555555555555555
-- 055:5555555555555555555555555555555555555555555555555555555555555555
-- 056:5555555555555555555555555555555555555555555555555555555555555555
-- 057:5555555555555555555555555555555555555555555555555555555555555555
-- 058:5555555555555555555555555555555555555555555555555555555555555555
-- 059:5087777807073778070737775050033055555000555503335550300055550333
-- 060:7770070577730705777307050000077003055005305555550055555533055555
-- 061:5555555555555555555555555555555055555550555555505555555055555550
-- 062:550cc055550cc055050cc050300cc00333333333373773733737737337377373
-- 063:5555555555555555555555550555555505555555055555550555555505555555
-- 064:555550005555044455504444555000005550cccc5550cccc5550eccc55550ecc
-- 065:00055555433055554433055500000555cccc0555cccc0555ccce0555cce05555
-- 066:555550005555044455504444555000005550cccc5550cccc5550eccc55550ecc
-- 067:00055555433055554433055500000555cccc0555cccc0555ccce0555cce05555
-- 068:555550005555044455504444555000005550cccc5550cccc5550eccc55550ecc
-- 069:00055555433055554433055500000555cccc0555cccc0555ccce0555cce05555
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
-- 080:55555000555504445550444455504444555e0444555e000055550f0555555555
-- 081:0005555544305555444305554443e5554440e5550005555550f0555550f05555
-- 082:55555000555504445550444455504444555e0444555e500055550f0555550f05
-- 083:000555554430555544430555444305554440e5550005e55550f0555550f05555
-- 084:555550005555044455504444555e4444555e04445555500055550f0555550f05
-- 085:000555554430555544430555444305554440e5550000e55550f0555555555555
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
-- 096:555550005555033455503344555000005550ccee5550ecee5550eeee55550eee
-- 097:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 098:555550005555033455503344555000005550ccee5550ecde5550eedd55550eee
-- 099:000555554440555544440555000000003e3d05553e3d0555eeee0555eee05555
-- 100:555550005555033455503344555000005550ccee5550ecde5550eedd55550eee
-- 101:000555554440555544440555000000003e3d05553e3d0555eeee0555eee05555
-- 102:5555550055555033555503345555000055550ce355550ce355550eee555550ee
-- 103:00005555444405554444405500000055ee3ec055ee3ec055eeeee055eeee0555
-- 104:5555555555555555555555555555555555555555555555555555555555555555
-- 105:5555555555555555555555555555555555555555555555555555555555555555
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:5555555555555555555555555555555555555555555555555555555555555555
-- 109:5555555555555555555555555555555555555555555555555555555555555555
-- 110:5555555555555555555555555555555555555555555555555555555555555555
-- 111:5555555555555555555555555555555555555555555555555555555555555555
-- 112:55555000555503045555034e5555034e555550045555500055550f055550ff05
-- 113:0005555544405555e4405555e4405555444055550005555550f0555550ff0555
-- 114:555550005555034d55e0344455e034dd5555044d55555000555550f055550ff0
-- 115:00055555d440555544d40e5544dd0e5544405555000555550f0555550ff05555
-- 116:555550005555034d5555044455e034dd55e0534d55555000555550f055550ff0
-- 117:00055555d440555544d0555544dd0e5544450e55000555550f0555550ff05555
-- 118:555e55005555e03455550344555503445555504455555500555550f055555555
-- 119:000055e544440e5544444055444440554444055500005555550f055555555555
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
-- 144:ff0000fff055550f055555500555555005555550f0555550ff05550ffff000ff
-- 145:ffffffffffffffffff00000ff055555005555550f055550fff0550fffff00fff
-- 146:fff00fffff05500ff0555550055555500555550ff005550ffff050ffffff0fff
-- 147:ffff00fffff0550ff0055550055555500555550ff05550ffff000fffffffffff
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
-- 160:5555555550555555040000000777777703333337043000000430555004305550
-- 161:5555555555555555000000007777777773337733700070007050705570507055
-- 162:5555555555555555000000007777777733773337000700075507050755070507
-- 163:5555555555555505000000407777773073333340000003400555034005550340
-- 164:fffffffffff00000ff0cccccf0500000f050f070f0500000f05cccccf0500000
-- 165:ffffffff00000000cccccccc00000000ffffffff00000000cccccccc00000000
-- 166:ffffffff00000fffccccc0ff0000050f070f050f0000050fccccc50f0000050f
-- 167:5555555555555555555555555555555555555555555555555555555555555555
-- 168:5555555555555555555555555555555555555555555555555555555555555555
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:5555555555555555555555555555555555555555555555555555555555555555
-- 171:5555555555555555555555555555555555555555555555555555555555555555
-- 172:5555555555555555555555555555555555555555555555555555555555555555
-- 173:5555555555555555555555555555555555555555555555555555555555555555
-- 174:5555555555555555555555555555555555555555555555555555555555555555
-- 175:5555555555555555555555555555555555555555555555555555555555555555
-- 176:0430555004305550040305500403055004030550040305500403055004030550
-- 177:7050705570507055705070557050705570507055705070557050705570507055
-- 178:5507050755070507550705075507050755070507550705075507050755070507
-- 179:0555034005550340055030400550304005503040055030400550304005503040
-- 180:f050f070f0500003f05ccccc05000000050ff070050ff070050ff070050ff070
-- 181:ffffffff00000000cccccccc00000000ffffffffffffffffffffffffffffffff
-- 182:070f050f0000050fccccc50f00000050070ff050070ff050070ff050070ff050
-- 183:5555555555555555555555555555555555555555555555555555555555555555
-- 184:5555555555555555555555555555555555555555555555555555555555555555
-- 185:5555555555555555555555555555555555555555555555555555555555555555
-- 186:5555555555555555555555555555555555555555555555555555555555555555
-- 187:5555555555555555555555555555555555555555555555555555555555555555
-- 188:5555555555555555555555555555555555555555555555555555555555555555
-- 189:5555555555555555555555555555555555555555555555555555555555555555
-- 190:5555555555555555555555555555555555555555555555555555555555555555
-- 191:5555555555555555555555555555555555555555555555555555555555555555
-- 192:040305500403055004003050040030500400300c040030500405555504055555
-- 193:70507055705070557050705570007055cccccc05000000555555555555555555
-- 194:5507050755070507550705075507000750cccccc550000005555555555555555
-- 195:05503040055030400503004005030040c0030040050300405555504055555040
-- 196:050ff070050ff070050ff070050ff070050ff070050ff070050fffff050fffff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:070ff050070ff050070ff050070ff050070ff050070ff050fffff050fffff050
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

-- <SPRITES1>
-- 000:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 001:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 002:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 003:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 004:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 005:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 006:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 007:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 008:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 009:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 010:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 011:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 012:cccc5555cccc5555cccc5555cccc5555cccc5555cccc5555cccc5555ccc55555
-- 013:5555555555555555555555555555555555555555555555555555555555555555
-- 014:5555555555555555555555555555555555555555555555555555555555555555
-- 015:5555555555555555555555555555555555555555555555555555555555555555
-- 016:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 017:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 018:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 019:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 020:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 021:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 022:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 023:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 024:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 025:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 026:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 027:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 028:ccc55555ccc55555ccc55555ccc55555ccc55555ccc55555ccc55555c5555555
-- 029:5555555555555555555555555555555555555555555555555555555555555555
-- 030:5555555555555555555555555555555555555555555555555555555555555555
-- 031:5555555555555555555555555555555555555555555555555555555555555555
-- 032:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 033:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 034:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 035:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 036:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 037:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 038:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 039:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 040:ccccccccccccccc5ccccccc5ccccccc5cccccccccccccccccccccccccccccccc
-- 041:55555555555555555555555555555555cccccccccccccccccccccccccccccccc
-- 042:55555555555555555555555555555555cccccccccccccccccccccccccccccccc
-- 043:55555555555555555555555555555555cccccccccccccccccccccccccccccccc
-- 044:55555555555555555555555555555555ccccccc3ccccccc7ccccccc7ccccccc7
-- 045:5555555555555555555555555555555533333333777333337777733377777733
-- 046:5555555555555555555555555555555533333333333333333333333333333333
-- 047:5555555555555555555555555555555533333333333333333333333333333333
-- 048:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 049:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 050:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 051:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 052:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 053:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 054:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 055:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 056:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 057:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 058:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 059:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 060:ccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 061:77777773ee777773eee7e773ceeee777ceeeee77ceeeeee7ceeeeee7ceeeeee7
-- 062:3333333333333333333333333333333373333333733333337733333377333333
-- 063:3333333333333333333333333333333333333333333333333333333333333333
-- 064:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 065:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 067:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 068:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 069:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 070:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 071:cccccccccccccccccccccccccccccccccccccccccccccccccccccc66cccc2222
-- 072:ccccccccccccccccccccccccccccc662cccc6622ccc662226666622222222222
-- 073:cccccccccccccccccccccccc2222222c22222222222222222222222222222222
-- 074:cccccccccccccccccccccccccccccccc2ccccccc2ccccccc2ccccccc2ccccccc
-- 075:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 076:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 077:ceeeeee7ceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeecceeeeeecceeeeee
-- 078:77333333773333337777333377773333e7777333ee777733ee777777eee77777
-- 079:3333333333333333333333333333333333333333333333333333333373733333
-- 080:cccccccccccccccccccccccc1cccccccbccccccccccccccccccccccccccccccc
-- 081:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 082:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 083:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 084:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 085:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 086:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 087:cccccccccccccccccccccccccccc62cccc266222cc222222cc266222c2222222
-- 088:cccce733cccce777cccce777ccccee77ccccce77ccccce77cccccee7cccccce7
-- 089:3333332277777333777773337777777777777777777777777777777777777722
-- 090:2ccccccc2ccccccccccccccccccccccccccccccccccccccccccccccc2ccccccc
-- 091:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 092:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 093:cceeeeeeccceeeeeccceeeeecccceeeecccceeeeccccceeeccccceeeccccccee
-- 094:eee77777eee77777ee777777ee777777ee777777ee777777ee777777ee777777
-- 095:7777733377777733777777337777777377777777777777777777777777777777
-- 096:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 097:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 098:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 099:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 100:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 101:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 102:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 103:cc222222cc22222ccccee777cccee777cccee77cccce777cccce777cccce777f
-- 104:cccccceecccccc62ccccc662ccccc662cccc6622ccc66222ccc62222cc622662
-- 105:7777222222222222222222222222222222222226222222262222222222222222
-- 106:222ccccc222ccccc2222cccc2222cccc22227ccc62222ccc662222cc6622222c
-- 107:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 108:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 109:cccccceecccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 110:ee777777eee77777eee77777ceee7777ceee7777ccee7777ccee7777cccee777
-- 111:7777777777777777777777777777777777777777777777777777777777777777
-- 112:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5
-- 113:cccccccccccccccccccccccccccccccccccccccccccc5555c555555555555555
-- 114:cccccccccccccccccccccccccccccccccccccccc555ccccc555555cc55555555
-- 115:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 116:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 117:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 118:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 119:cccee777cccce777cccce777cccce777ccccee77ccccce77cccccee7cccccee7
-- 120:ff6226227f626622726266227762622277766222777662227777622277776222
-- 121:22222222222222222222222222222226222222ee22222ee72222ee7722eee777
-- 122:2622222226622222266222226677b22ce7777ccc77777ccc7777cccc777ccccc
-- 123:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 124:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 125:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 126:cccce777ccccce77ccccceeecccccceecccccccccccccccccccccccccccccccc
-- 127:777777777777777777777777e7777777ee777777cee77777cceee777ccccee77
-- 128:cccc5555ccc55555cc555555cc555555ee555555ee555555ee75555577775555
-- 129:5555555555555555555555555555555555555555555555555555555555555555
-- 130:5555555555555555555555555555555555555555555555555555555555555555
-- 131:55cccccc555ccccc555ccccc5555cccc5555cccc5555cccc55555ccc55555ccc
-- 132:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 133:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 134:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 135:cccccceecccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 136:77776222eee76222ccee7eeeccceee77ccceee77ccce7777ccce7772ccce7722
-- 137:eee77777ee777777777772227777222277772222772222222222222222222222
-- 138:722ccccc222ccccc222ccccc222ccccc222ccccc222ccccc222ccccc2222cccc
-- 139:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 140:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 141:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 142:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 143:ccccee77ccccee77ccccee77ccccee77ccceee70ccceee70cccee777ccee7777
-- 144:777755ee77777ee777777e777777ee777777e7777777e777777ee777777e7777
-- 145:e775555577775555777755557777555577775555777755557575555555555555
-- 146:5555555555555555555555555555555555555555555555555555555555555555
-- 147:55555ccc55555ccc55555ccc55555ccc55555533555555335555553355555533
-- 148:cccccccccccccccccccccccccccccccc33333333333333333333333333333333
-- 149:cccccccccccccccccccccccccccccccc33333333333333333333333333333333
-- 150:cccccccccccccccccccccccccccccccc33333333333333333333333333333333
-- 151:cccccccccccccccccccccccccccccccc33333333333333333333333333333333
-- 152:ccc77722ccc72222ccc22222ccc2222233322222333222223332222233322222
-- 153:2222222222222222222222222222222222222222222222222222222222222222
-- 154:2222cccc2222cccc2222cccc2222cccc22223333222233332222333322223333
-- 155:cccccccccccccccccccccccccccccccc33333333333333333333333333333355
-- 156:cccccccccccccccccccccccccccccccc33333333333333333333333555555555
-- 157:cccccccccccccccccccccccccccccccc33333333333333335555555e55555555
-- 158:ccccccccccccccccccccceeecccce77733ee7777eee77777ee77777755555555
-- 159:cee77777c7777777777777777777777777777777777777777777775555555555
-- 160:777e7777777e7775777e7775777e777777777777777777777777777777777777
-- 161:5555555555555555555555555555555555555555555555555555555575555555
-- 162:5555555555555555555555555555555555555555555555555555555555555555
-- 163:5555553355555333555553335555533355555333555553335555533355553333
-- 164:3333333333333333333333333333333333333333333333333333333333333333
-- 165:3333333333333333333333333333333333333333333333333333333333333333
-- 166:3333333333333333333333333333333333333333333333333333333333333333
-- 167:3333333333333333333333333333333333333333333333333333333333333333
-- 168:3333222233332222333322223333222233332222333322233332273333333733
-- 169:2222222222222222222222222222233322233333333333333333333333333333
-- 170:2222333322222333222233333373333533735555337555553375555533555555
-- 171:3333555533555555355555555555555555555555555555555555555555555555
-- 172:5555555555555555555555555555555555555555555555555555555555555555
-- 173:5555555555555555555555555555555555555555555555555555555555555555
-- 174:5555555555555555555555555555555555555555555555555555555533335555
-- 175:5555555555555555555555555555555555555555555555555555555555555555
-- 176:7777777777777777777777777777777777777777777777777777777777777777
-- 177:7555555577555555777555557777555577777555777777557777777777777777
-- 178:5555555555555555555555555555777757777777777777777777777e777777ee
-- 179:555533335553333355333333e3333333e3333333e3333333e333333333333333
-- 180:3333333333333333333333333333333333333333333333333333333333333333
-- 181:3333333333333333333333333333333333333333333333333333333333333333
-- 182:3333333333333333333333333333333333333333333333333333333333333333
-- 183:3333333333333333333333333333333333333333333333333333333333333333
-- 184:3333373333333733333337333333373333333733333337333333373333333733
-- 185:3333333333373333333733353337335533373555333755553335555533755555
-- 186:5555555555555555555555555555555555555555555555555555555555555555
-- 187:5555555555555555555555555555555555555555555555555555555555555553
-- 188:5555555555555555555555535555533355553333553333335333333333333333
-- 189:5555333353333333333333333333333333333333333333333333333333333333
-- 190:3333333333333333333333333333333333333333333333333333333333333333
-- 191:3333333333333333333333333333333333333333333333333333333333333333
-- 192:7777777777777777777777777777777777777777777777777777777777777777
-- 193:7777777777777777777777777777777777777777777777777777777777777777
-- 194:7777eee3777ee3337eee33337ee3333373333333733333337333333373333333
-- 195:3333333333333333333333333333333333333333333333333333333333333333
-- 196:3333333333333333333333333333333333333333333333333333333333333333
-- 197:3333333333333333333333333333333333333333333333333333333333333333
-- 198:3333333333333333333333333333333333333333333333333333333333333333
-- 199:3333333333333333333333333333333333333333333333333333333333333333
-- 200:3333373333333733333337333333373333337775333377353333773533337335
-- 201:3355555535555555355555555555555555555555555555555555555555555555
-- 202:5555555555555555555555555555555555555555555555535555553355555533
-- 203:5555353355333333533333333333333333333333333333333333333333333333
-- 204:3333333333333333333333333333333333333333333333333333333333333333
-- 205:3333333333333333333333333333333333333333333333333333333333333333
-- 206:3333333333333333333333333333333333333333333333333333333333333333
-- 207:3333333333333333333333333333333333333333333333333333333333333333
-- 208:7777777777777777777777777777777777777777e7777777ee777777be777777
-- 209:7777777777777777777777777777777777777777777777777777777777777777
-- 210:73333333733333337bbbbbbb7bbbbbbb7bbbbbbb7bbbbbbb777bbbbb777bbbbb
-- 211:3333333333333333bbbb1bbbbb1bbbbbbb1b1bbbb1bbbb1bbbbbbb11bbbbbbbb
-- 212:3333333333333333bbb1b1bbbbbbbbbbb1bbb1bbb1bbbbb1bbbbbb1bbbbbbbbb
-- 213:3333333333333333bbbb11b1bb11bbbbbbbbbbbbbbb11b1bbbbbbbbbbbbb1bbb
-- 214:3333333333333333bbbbbbbbbbbbbbbb1bbbbbbbbbbbbbb1bbbbbbbbbb1bbbbb
-- 215:3333333333333333bbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 216:3333773533337355bbb77355bb777355b7733355377335553733355537355555
-- 217:5555555555555555555555555555555555555555555555555555555355555553
-- 218:5555553355533333553333335533333353333333333333333333333333333333
-- 219:3333333333333333333333333333333333333333333333333333333333333333
-- 220:3333333333333333333333333333333333333333333333333333333333333333
-- 221:3333333333333333333333333333333333333333333333333333333333333333
-- 222:3333333333333333333333333333333333333333333333333333333333333333
-- 223:3333333333333333333333333333333333333333333333333333333333333333
-- 224:bee77777bbee7777bbbe7777bbbee777bbbbe777bbbbee77bbbbbe77bbbbbee7
-- 225:7777777777777777777777777777777777777777777777777777777777777777
-- 226:777bbb1b7777bbb17777bb1b7777bbbb77777bbb77777bbb77777bbb777777bb
-- 227:bbbbbbbbbb11bb1bbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbb11bbbbbbb1bbbb
-- 228:bbbbbbbbbb1bbbb1bbbbbbbbbbbb1b1bbbb1bbbbbbbbb1bbbbbbbbbb11bbbbbb
-- 229:bbbbbbbbbb1bbbbbb1b1bbb1bbbbbb1bbbbbbbbbbbbbbbbbbbb1b1bbb1111b1b
-- 230:bbb1bbbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 231:bbbbbbbbb1bbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 232:33355555b3555555bb555555b5555555b5555555555555555555555555555555
-- 233:5555553355555533555553335555333355553333555333335533333355333333
-- 234:3333333333333333333333333333333333333333333333333333333333333333
-- 235:3333333333333333333333333333333333333333333333333333333333333333
-- 236:3333333333333333333333333333333333333333333333333333333333333333
-- 237:3333333333333333333333333333333333333333333333333333333333333333
-- 238:3333333333333333333333333333333333333333333333333333333333333333
-- 239:3333333333333333333333333333333333333333333333333333333333333333
-- 240:bbbbbbe7bbbbbbeebbbbbbeebbbbbbbebbbbbbbebbbbbbbebbbbbbbbbbbbbbbb
-- 241:77777777777777777777777777777777b7777777e7777777ee777777ee777777
-- 242:777777bb777777bb7777777b7777777b77777777777777777777777777777777
-- 243:bb1bbbb111bb11bbbbbbbb1bbbbb11bbbbb1bbbb7bbb1bbb1bbbbb1b71bbbbb1
-- 244:b1bbbb1b1bbbbb11bbb1bb1bbbbbb11111bb1bb1b1bbb1bb1b1bb1bbbb1bbbbb
-- 245:11bb1b1bbbbbbbbbb1bbbbbbbb1bbb1bb1bb11bbbb1bbbbb1bbbbbb11bbbb1b1
-- 246:bb1bbbbb11bbbb11bb1bbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 247:bbbbbbbbbbbbbbb5bbbb1bb5b1bbbb55bbbbbb55bbbbbb55bbbbb555bbbbb555
-- 248:5555555555555555555555555555555555555555555555555555555555555555
-- 249:5533333355333333533333335333333353333333533333335533333355333333
-- 250:3333333333333333333333333333333333333333333333333333333333333333
-- 251:3333333333333333333333333333333333333333333333333333333333333333
-- 252:3333333333333333333333333333333333333333333333333333333333333333
-- 253:3333333333333333333333333333333333333333333333333333333333333333
-- 254:3333333333333333333333333333333333333333333333333333333333333333
-- 255:3333333333333333333333333333333333333333333333333333333333333333
-- </SPRITES1>

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
-- 030:000000000000000000000000000000000000000000000000000000000000be464646464646cadaea4646464646464646464646464646464646464646464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:000000000000000000000000000000000000000000000000000000000000be464646464646cbdbdbdddddddddddd4646464646074646464646464646464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:000000000000000000000000000000000000000000000000000000000000be462727272746cbdbeb4646464646464646464646464646464646467746464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:000000000000000000000000000000000000000000000000000000000000be464646464646ccdbec4646464646464657464646464646464646464677464646464646464646469e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:0000000000000000000000000000000000000000000000000000000000009fafafafafaf5d46ce46464646464746464646464646464646464646464646464646464646463dafbf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000000000000000000000000000000000000000000000000000000000000000000000005e46ce46464646464646465746464646464646464646464646464646464646463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:0000000000000000000000000000000000000000000000000000000000000000000000005e46ce46460746464646464646464646464646464646464646464646464646463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:0000000000000000000000000000000000000000000000000000000000000000000000005e46ce46464646464646464646464646464646464646465746574627272727463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:0000000000000000000000000000000000000000000d1d1d1d1d1d1d1d1d2d00000000005ecdeedded4646464646464646464646091929394646464646464646464646463e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:00000000000000000000000000000000000d1f1f1f2f46464646464646460e00000000005ece7777ce46464646464646464646460a1a2a3a46463d4f4f4f4f4f4f4f4f4f5f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:000000000000000000000000000000000d2f4646464646464646464646460e00000000005ece7777ce46464646464646464646460b1b2b3b46463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000d2f464646464607460746074607460e00000000005ecfeeddef46464646464646464646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000000000000000000000d2f46464646464646464646374646460e00000000005e46ce464646464646464646464646464646464646463e003d4d4d4d4d4d4d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000d2f4646464646464646464646464646460e00000000005e46ce464646464646774646464646464646464646463e003e4646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000000000000000000e464646464746464646460919293946460e00000000005e46ce464646774646464677464646464646464646463f4f5f4646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000e465746464646464677770a1a2a3a46460e00000000005e07ce074646464646464646464646464646464646464646464646464746465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:000000000000000000000000000e464646464646464677770b1b2b3b46460e00000000005e46ce464646464677464646464646462727272746464646464646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:000000000000000000000000000e464646464646464646464646464646460e00000000005e46ce171717464646464646464657464646464646463d4d5d4646463746465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:000000000000000000000000000e464646464646464646464646464646460e00000000005e46ce464646464646464646464646464646464646463e003e4646464646465e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000e464646464646464646464646464646460e00000000005e46ce4646464646463d4d4d4d4d4d5d4646464646463e003f4f4f4f4f4f4f5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000e464646464646464646464646464646460e00000000005e46eedddddddded463e46464646465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:000000000000000000000000000e464646464646464646464646464646460e00000000005e46ce09192939ce463e46464646465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:000000000000000000000000000e464646460d1d1d1d1d1d2d46464646460e00000000005e46ce0a1a2a3ace463e46464646465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:000000000000000000000000000e464646070e00000000002e46464646460e00000000005e46ce771a1a3ace463e46074607465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:000000000000000000000000000e464646460e00000000002e46464646460e00000000005e46ce092a1a3ace463e46463746465e4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:000000000000000000000000000e464607460e00000d1f1f2f46464646460e00000000005e46ce0a1a2a3ace467777773d4f4f5f4646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:000000000000000000000000000e464646460e00000e46464646464646460e00000000005e46ce0b1b2b07ce467777773e7777464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:000000000000000000000000000e464646070f1f1f2f46574646464646463f4f4f4f4f4f5f46eeddddddddef463e77773e4646464646464646463e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

-- <MAP1>
-- 000:f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0c0d0e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:f0f020304050f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:f0f021314151f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:f012223242f0f0f0f0f0c1d1e1f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:f013233343f0f0f0f0f0c2d2e2f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:f0142334f0f0f0f0f0f0c3d3e3f300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:f0152335f0f0f0f0f0f0f0d4e3f400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:06162336c5c5c5c5c5c5c5d5e3f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:d7172737d7d7d7d7d7d7d7d6e6f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d7020410d7d7d7d7d7d7d7d7e7f700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d7030511d7d7d7d7d7d7d7d7a0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:52627282445464748494a4b4a1b100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:53637383455565758595a5b5a2b200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:60708090465666768696a6b6a3e300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP1>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0023456789abcdffffdcba9876543200
-- 002:0123456789abcdef0123456789abcdef
-- 004:02469a96786777890b6c861204a257e9
-- </WAVES>

-- <SFX>
-- 016:d303e302f301f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300500000000000
-- 017:a007600620050004000300010000000d000b00085008a008f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000b60000000000
-- 048:01000100210041006100a100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100300000000000
-- 049:040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400300000000000
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
-- 000:00003000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101000000000000000001010001000000000000000000000000010101000000000000000000000000000101000100000000000000000000000000010100000000000000000000000000000000000001010100010000000000000303030303030303030303030000000003000303000303000303000300000000030303030303030303030303000000000
-- </FLAGS>

-- <SCREEN>
-- 000:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc55555555555555555555555
-- 001:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc555555555555555555555555
-- 002:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc555555555555555555555555
-- 003:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555
-- 004:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555
-- 005:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc555555555555555555555555555
-- 006:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc555555555555555555555555555
-- 007:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc555555555555555555555555555
-- 008:cccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccccccccccccccccccc0000000000000cccccccccccccccccccccccccccccccccccccccccccc000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 009:cccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccccccccccccccccccc00000000000000ccccccccccccccc0000000ccccccccccccccccccccc000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 010:cccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccccccccccccccccc00000000000000cccccccccccccc000000000cccccccccccccccccccc000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 011:cccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccccccc0000cccccc0000cccc000000cccccccccccccc000000000000ccccccccccccccccc00000000000000ccccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 012:cccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccccccc0000cccccc0000cccccc0000cccccccccccccc0000000000000cccccccccccccccc000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 013:ccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccccccc00000cccccc0000cccccc0000cccccccccccccc0000c000000000ccccccccccccccc0000cc00000000000cccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 014:ccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccccccc00000cccccc0000cccccc0000cccccccccccccc0000cc00000000ccccccccccccccc0000ccccc000000000ccccccccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555
-- 015:ccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccccccc00000cccccc0000cccccc0000cccccccccccccc0000ccccc000000cccccccccccccc0000cccccc000000000ccccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 016:ccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccccccccccccccccccccc00000ccccccc0000ccccc00000cccccccccccccc0000ccccc000000cccccccccccccc0000cccccccc00000000cccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 017:ccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccccccccccccccccccccc00000ccccccc0000cccc000000cccccccccccccc0000cccccc000000ccccccccccccc0000cccccccccc000000cccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 018:ccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccc000000ccccccc0000cccc000000cccccccccccccc0000ccccccc00000ccccccccccccc0000ccccccccccc00000cccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 019:ccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccc00000cccccccc0000cc00000000cccccccccccccc0000ccccccc000000cccccccccccc0000cccccccccccc00000ccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 020:ccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cccccccccccccccccccc000000cccccccc0000000000000ccccccccccccccc0000cccccccc000000ccccccccccc0000cccccccccccc00000ccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 021:cccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccc00000ccccccccc000000000000000cccccccccccc00000cccccccc000000ccccccccccc0000cccccccccccc00000ccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 022:cccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccccccccc00000ccccccccc0000000000000000ccccccccccc00000ccccccccc000000cccccccccc0000ccccccccccccc0000ccccccccccccccccccccccccccccccccccccccccc55555555555555555555555555555
-- 023:cccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccccccccccccccccc00000cccccccccc0000000000000000ccccccccccc00000cccccccccc00000cccccccccc0000ccccccccccccc0000ccccccccccccccccccccccccccccccccccccccc5555555555555555555555555555555
-- 024:cccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccc0000cccccccc000000cccccccccc0000cccccc0000000cccccccccc0000ccccccccccc00000cccccccccc0000ccccccccccccc0000cccccccccccccc55555555555555555555555555555555555555555555555555555555
-- 025:cccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccc00000ccccccc000000cccccccccc0000cccccccc00000cccccccccc000000000000000000000ccccccccc0000ccccccccccccc0000ccccccccccccc555555555555555555555555555555555555555555555555555555555
-- 026:cccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cccc000000cccccc000000ccccccccccc0000cccccccc00000ccccccccc0000000000000000000000ccccccccc0000ccccccccccccc0000ccccccccccccc555555555555555555555555555555555555555555555555555555555
-- 027:cccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cccc0000000ccccc00000cccccccccccc0000ccccccccc0000ccccccccc00000000000000000000000cccccccc0000ccccccccccccc0000ccccccccccccc555555555555555555555555555555555555555555555555555555555
-- 028:ccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccc0000000cccc000000cccccccccccc0000ccccccccc0000ccccccccc00000000000000000000000cccccccc0000cccccccccccc00000ccccccccccccccccccccccccccccccccccccccccccccc3333333333333333333333333
-- 029:ccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cc00000000cccc00000cccccccccccc00000ccccccccc0000ccccccccc0000cccccccccccccc00000cccccccc0000cccccccccccc00000ccccccccccccccccccccccccccccccccccccccccccccc7777333333333333333333333
-- 030:ccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000cc000000cccccccccccc00000cccccccc00000ccccccccc0000ccccccccccccccc0000cccccccc0000cccccccccccc00000ccccccccccccccccccccccccccccccccccccccccccccc7777773333333333333333333
-- 031:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000cc00000ccccccccccccc00000cccccccc00000cccccccc00000ccccccccccccccc00000ccccccc0000cccccccccc000000cccccccccccccccccccccccccccccccccccccccccccccc7777777333333333333333333
-- 032:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000c00000ccccccccccccc0000cccccccc000000cccccccc00000ccccccccccccccc00000ccccccc0000cccccccccc000000cccccccccccccccccccccccccccccccccccccccccccccc7777777733333333333333333
-- 033:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cc0000000000cccccccccccccc0000ccccccc000000cccccccc000000ccccccccccccccc00000ccccccc0000ccccccc000000000cccccccccccccccccccccccccccccccccccccccccccccccee7777733333333333333333
-- 034:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cc0000000000cccccccccccccc0000ccccc00000000cccccccc00000ccccccccccccccccc0000ccccccc0000cc0000000000000cccccccccccccccccccccccccccccccccccccccccccccccceee7e7733333333333333333
-- 035:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000ccc000000000cccccccccccccc0000cccc00000000ccccccccc00000ccccccccccccccccc0000ccccccc000000000000000000cc0000cccccccccccccccccccccccccccccccccccccccccccceeee7773333333333333333
-- 036:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000ccc00000000cccccc0000ccccc0000c00000000000ccccccccc0000cccccccccccccccccc0000ccccccc00000000000000000ccc0000cccccccccccccccccccccccccccccccccccccccccccceeeee777333333333333333
-- 037:ccccccccccccccccccccccccccccccccccccccc44444ccccccccccccccc00000ccccc0000000cccccc0000ccccc00000000000000ccccccccccccccccccccccccccccccccc0000c0000cc00000000000000cccccc0000cccccccccccccccccccccccccccccccccccccccccccceeeeee77333333333333333
-- 038:ccccccccccccccccccccccccccccccccccff4c4ff4444cccccccccccccc00000ccccc000000ccccccc0000ccccc000000000000ccccc0000ccccccccccccccccccccccccccccccc0000cc000000000ccccccccccc0000cccccccccccccccccccccccccccccccccccccccccccceeeeee77733333333333333
-- 039:cccccccccccccccccccffffffffffcccfff44c4ff44444ccccccccccccc0000ccccccc00000ccccccc0000ccccc00000000000cccccc0000ccccccccccccccccccccccccccccccc0000cc0000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccceeeeee77733333333333333
-- 040:ccccccccccccccccccff44444444fffff44cc444444444ccccccccccccccccccccccccccccccccccccccccccccc000000000cccccccc0000ccccccccccccccccccccccccccccccc0000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccceeeeee77733333333333333
-- 041:cccccccccccccccccff4444444444ffcccccc444444444ccccccccccccccccccccccccccccccccccccccccccccccc00000cccccccccc0000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccceeeeeee7733333333333333
-- 042:cccccccccccccccccff4444444444ffcccccc444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccceeeeeee7777333333333333
-- 043:cccccccccccccccccf4444444444444cccccc444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6622222222cccccccccccccccccccccccccceeeeeee7777333333333333
-- 044:cccccccccccccccccf444444444444ccccccc74444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6622222222222cccccccccccccccccccccccceeeeeeee777733333333333
-- 045:ccccccccccccccccc4444447777eecccccccce77444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66222222222222cccccccccccccccccccccccceeeeeeeee77773333333333
-- 046:ccccccccccccccccc44437777777ecccccccce77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6666666222222222222ccccccccccccccccccccccccceeeeeeee77777733333333
-- 047:cccccccccccccccccc4377777777ecccccccce77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc222222222222222222222ccccccccccccccccccccccccceeeeeeeee7777773733333
-- 048:cccccccccccccccccc337777777eecccccccce77ccccccccccccccccccccccccccccccccccccccccccccccccbbbbccccccccbbbb111ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce733333333222ccccccccccccccccccccccccceeeeeeeee7777777777333
-- 049:cccccccccccccccccc337777777eccccccccce77cccccccccccccccccccccccccccccccccccccccccccccbbbbb1bbcccccbbbbbbbb11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce777777773332cccccccccccccccccccccccccceeeeeeee7777777777733
-- 050:cccccccccccccccccc337777777eccccccccce77cccccccccccccccccccccccccccccccccccccccccccccbb1bbbbbccccbb33bbbbbb111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce77777777333ccccccccccccccccccccccccccceeeeeee77777777777733
-- 051:cccccccccccccccccc37777777eeccccccccce77cccccccccccccccccccccccccccccccccccccccccccccbb111bbbccccbb3bbbbbbbb11111ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc62ccccccee7777777777cccccccccccccccccccccccccccceeeeee77777777777773
-- 052:ccccccccccccccccccc77777eeeeccccccccee77cccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbccccbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccc266222ccccce7777777777cccccccccccccccccccccccccccceeeeee77777777777777
-- 053:ccccccccccccccccccc7777eeecccccccccce777cccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbccccbb3333337eecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc222222ccccce7777777777ccccccccccccccccccccccccccccceeeee77777777777777
-- 054:ccccccccccccccccf4444444444ffffffccce777cccccccccccccccccccccccccccccccccccccccccccccccb7bbbccccc7333777777ecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc266222cccccee777777777ccccccccccccccccccccccccccccceeeee77777777777777
-- 055:cccccccccccccccff444444444444444ffcee777ccccccccccccccccccccccccccccccccccccccccccccccce7b77ccccc7737777777eccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222cccccce7777777222ccccccccccccccccccccccccccccceeee77777777777777
-- 056:ccccccccccccccff44444444444444444f4e7777ccccccccccccccccccccccccccccccccccccccccccccccce777ccccccc77777777eecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc222222ccccccee77772222222ccccccccccccccccccccccccccceeee77777777777777
-- 057:cccccccccccccff4444444444444444444477777ccccccccccccccccccccccccccccccccccccccccccccccce777ccccccc77777777eccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc22222ccccccc6222222222222ccccccccccccccccccccccccccccceee7777777777777
-- 058:cccccccccccccf44444444444444444444477777ccccccccccccccccccccccccccccccccccccccccccccccce777ccccccc7777777eeccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccee777ccccc662222222222222cccccccccccccccccccccccccccceee7777777777777
-- 059:cccccccccccccf44444444444444444444477777ccccccccccccccccccccccccccccccccccccccccccccccce777ccccccc7777777eeccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccee777ccccc662222222222222ccccccccccccccccccccccccccccceee777777777777
-- 060:cccccccccccccf44444444444444444444477777ccccccccccccccccccccccccccccccccccccccccccccccce777ccccccc777777eecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccee77ccccc66222222222622227cccccccccccccccccccccccccccceee777777777777
-- 061:cccccccccccccf4444444444444444444447777cccccccccccccccccccccccccccccccccccccccccccccccce777fffffff7777eeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce777cccc662222222222662222cccccccccccccccccccccccccccccee777777777777
-- 062:ccccccccccccff44444444444444444ffcccccccccccccccccccccccccccccccccccccccccccccccccccccce777f111bbbbbbbbb8bccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce777cccc6222222222222662222ccccccccccccccccccccccccccccee777777777777
-- 063:ccccccccccccf444444444444444444fcccccccccccccccccccccccccccccccccccccccccccccccccccccccee7711bbbbbbbbbbbbb1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce777fcc622662222222226622222ccccccccccccccccccccccccccccee77777777777
-- 064:ccccccccccccf444444444444444444fcccccccccccccccccccccccccccccccccccccccccccccccccccccccee711bbbbbbbbbbbbbbb8cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccee777ff6226222222222226222222cccccccccccccccccccccccccccce77777777777
-- 065:ccccccccccccf444444444444444444fcccccccccccccccccccccccccccccccccccccccccccccccccccccccce11bb11bbbbbbbbbbbbb8ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce7777f6266222222222226622222ccccccccccccccccccccccccccccce7777777777
-- 066:ccccccccccccf444444444444444444fcccccccccccccccccccccccccccccccccccccccccccccccccccccccce1111111bbbbbbbbbbbb18cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce777726266222222222226622222ccccccccccccccccccccccccccccceee77777777
-- 067:ccccccccccccf44444444444444444fccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111bbbbbbbbbbbbb18ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccce77777626222222222266677b22ccccccccccccccccccccccccccccccceee7777777
-- 068:ccccccccccccf44444444444444444fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111bbbbbbbbbbbbb18cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccee7777766222222222eee7777cccccccccccccccccccccccccccccccccccee777777
-- 069:ccccccccccccf44444444444444444fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111bbbbbbbbbbbbbb18cccccccccccc5555555cccccccccccccccccccccccccccccccccccccccccce777776622222222ee777777ccccccccccccccccccccccccccccccccccccee77777
-- 070:cccccccccccc444444444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1bbbbbbbbbbbbbb11ccccccccc5555555555555cccccccccccccccccccccccccccccccccccccccee7777762222222ee777777cccccccccccccccccccccccccccccccccccccceee777
-- 071:cccccccccccc444444444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1bbbbbbbbbbbb1bb1ccccccc55555555555555555cccccccccccccccccccccccccccccccccccccee77777622222eee777777cccccccccccccccccccccccccccccccccccccccccee77
-- 072:cccccccccccc444444444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1bbbbbbbbbbbb1bb1cccc5555555555555555555555ccccccccccccccccccccccccccccccccccccee77776222eee77777722cccccccccccccccccccccccccccccccccccccccccee77
-- 073:cccccccccccc444444444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1bbbbbbbbbbbb1bb1ccc555555555555555555555555ccccccccccccccccccccccccccccccccccccceee76222ee777777222cccccccccccccccccccccccccccccccccccccccccee77
-- 074:cccccccccccc444444444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1bbbbbbbbbbbb1bb1cc5555555555555555555555555cccccccccccccccccccccccccccccccccccccccee7eee77777222222cccccccccccccccccccccccccccccccccccccccccee77
-- 075:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbb1bb1cc55555555555555555555555555ccccccccccccccccccccccccccccccccccccccceee7777772222222cccccccccccccccccccccccccccccccccccccccccee77
-- 076:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbb1bbeee55555555555555555555555555ccccccccccccccccccccccccccccccccccccccceee7777772222222cccccccccccccccccccccccccccccccccccccccceee70
-- 077:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbb11beee55555555555555555555555555ccccccccccccccccccccccccccccccccccccccce777777222222222cccccccccccccccccccccccccccccccccccccccceee70
-- 078:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbb1eeee755555555555555555555555555cccccccccccccccccccccccccccccccccccccce777222222222222ccccccccccccccccccccccccccccccccccccccccee777
-- 079:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbb1e777775555555555555555555555555cccccccccccccccccccccccccccccccccccccce7722222222222222ccccccccccccccccccccccccccccccccccccccee7777
-- 080:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbbee7777755eee77555555555555555555cccccccccccccccccccccccccccccccccccccc77722222222222222cccccccccccccccccccccccccccccccccccccee77777
-- 081:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbbe7777777ee7777755555555555555555cccccccccccccccccccccccccccccccccccccc72222222222222222ccccccccccccccccccccccccccccccccccccc7777777
-- 082:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbbe7777777e77777755555555555555555cccccccccccccccccccccccccccccccccccccc22222222222222222ccccccccccccccccccccccccccccccccceee77777777
-- 083:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbee777777ee77777755555555555555555cccccccccccccccccccccccccccccccccccccc22222222222222222cccccccccccccccccccccccccccccccce77777777777
-- 084:cccccccccccc444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11bbbbbbbbbbbbee777777e7777777555555555555555555333333333333333333333333333333333333322222222222222222333333333333333333333333333333ee777777777777
-- 085:3ccccccccccc444444444444444444333333333333333333333333333333333333333333333333333333333333333311bbbbbbbbbbeee7777777e77777775555555555555555553333333333333333333333333333333333333222222222222222223333333333333333333333333333eee7777777777777
-- 086:333333333333444444444444444444333333333333333333333333333333333333333333333333333333333333333331bbbbbbbbbbe7e777777ee7777575555555555555555555333333333333333333333333333333333333322222222222222222333333333333333333355555555eee77777777777755
-- 087:333333333333444444444444444444333333333333333333333333333333333333333333333333333333333333333331bbbbbbbbbbe7e777777e7777555555555555555555555533333333333333333333333333333333333332222222222222222233333333335555555555555555555555555555555555
-- 088:3333333333344444444444444444443333333333333333333333333333333333333333333333333333333333333333311bbbbbbbbbe7e777777e7777555555555555555555555533333333333333333333333333333333333333222222222222222233333333555555555555555555555555555555555555
-- 089:3333333333344444444444444433373333333333333333333333333333333333333333333333333333333333333333311bbbbbbbbbe7e777777e7775555555555555555555555333333333333333333333333333333333333333222222222222222223333355555555555555555555555555555555555555
-- 090:3333333333344444444444443333773333333333333333333333333333333333333333333333333333333333333333311bbbbbbbbbe7e777777e7775555555555555555555555333333333333333333333333333333333333333222222222222222233333555555555555555555555555555555555555555
-- 091:33333333333344444433333333337733333333333333333333333333333333333333333333333333333333333333333311bbbbbbbbe7ee77777e7777555555555555555555555333333333333333333333333333333333333333222222222333337333355555555555555555555555555555555555555555
-- 092:3333333333334444333333333333373333333333333333333333333333333333333333333333333333333333333333337733333333e77e7777777777555555555555555555555333333333333333333333333333333333333333222222233333337355555555555555555555555555555555555555555555
-- 093:3333333333334433333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e7777777777555555555555555555555333333333333333333333333333333333333333222333333333337555555555555555555555555555555555555555555555
-- 094:3333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e7777777777555555555555555555555333333333333333333333333333333333333332273333333333337555555555555555555555555555555555555555555555
-- 095:3333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e7777777777755555555555555555553333333333333333333333333333333333333333373333333333335555555555555555555555555555553333555555555555
-- 096:3333333333333773333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e7777777777755555555555555555553333333333333333333333333333333333333333373333333333555555555555555555555555555533333333333333333333
-- 097:3333333333333773333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77ee777777777775555555555555555533333333333333333333333333333333333333333373333373333555555555555555555555555533333333333333333333333
-- 098:3333333333333773337333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e7777777777777777555555555555555333333333333333333333333333333333333333333373333373335555555555555555555555553333333333333333333333333
-- 099:3333333333333773337333333333377333333333333333333333333333333333333333333333333333333333333333337333333333e77777777777777777555555557777e3333333333333333333333333333333333333333333373333373355555555555555555555555333333333333333333333333333
-- 100:3333333333333773337733333333377333333333333333333333333333333333333333333333333333333333333333337333333333e77777777777777777755557777777e3333333333333333333333333333333333333333333373333373555555555555555555555553333333333333333333333333333
-- 101:3333333333333773333733333333377333333333333333333333333333333333333333333333333333333333333333337333337333e77777777777777777775577777777e3333333333333333333333333333333333333333333373333375555555555555555555555333333333333333333333333333333
-- 102:3333333333333773333733333333377333333333333333333333333333333333333333333333333333333333333333337333337333e7777777777777777777777777777ee3333333333333333333333333333333333333333333373333355555555555555555555553333333333333333333333333333333
-- 103:3333333333333773333773333333377333333333333333333333333333333333333333333333333333333333333333337333337333e777777777777777777777777777ee33333333333333333333333333333333333333333333373333755555555555555555555333333333333333333333333333333333
-- 104:3333333333333733333733333333337333333333333333333333333333333333333333333333333333333333333333333733337333ee777777777777777777777777eee333333333333333333333333333333333333333333333373333555555555555555555353333333333333333333333333333333333
-- 105:3333333333333733333773333333337333333333333333333333333333333333333333333333333333333333333333333733337333ee77777777777777777777777ee33333333333333333333333333333333333333333333333373335555555555555555533333333333333333333333333333333333333
-- 106:33333333333337333333733333333373333333333333333333333333333333333333333333333333333333333333333337333373337e777777777777777777777eee333333333333333333333333333333333333333333333333373335555555555555555333333333333333333333333333333333333333
-- 107:33333333333337333337733333333373333333333333333333333333333333333333333333333333333333333333333337333373333e777777777777777777777ee3333333333333333333333333333333333333333333333333373355555555555555553333333333333333333333333333333333333333
-- 108:33333333333337333337733333333773333333333333333333333333333333333333333333333333333333333333333337333373333ee77777777777777777777333333333333333333333333333333333333333333333333333777555555555555555553333333333333333333333333333333333333333
-- 109:33333333333337333337733333333773333333333333333333333333333333333333333333333333333333333333333337333373333ee77777777777777777777333333333333333333333333333333333333333333333333333773555555555555555533333333333333333333333333333333333333333
-- 110:33333333333337333337733333333773333333333333333333333333333333333333333333333333333333333333333337333373333ee77777777777777777777333333333333333333333333333333333333333333333333333773555555555555555333333333333333333333333333333333333333333
-- 111:333333333333373333373333333337733333333333333333333333333333333333333333333333333333333333333333373337733333e77777777777777777777333333333333333333333333333333333333333333333333333733555555555555555333333333333333333333333333333333333333333
-- 112:333333333333373333373333333337733333333333333333333333333333333333333333333333333333333333333333373337333333ee7777777777777777777333333333333333333333333333333333333333333333333333773555555555555555333333333333333333333333333333333333333333
-- 113:333333333333373333373333333337733333333333333333333333333333333333333333333333333333333333333333373337333333ee7777777777777777777333333333333333333333333333333333333333333333333333735555555555555333333333333333333333333333333333333333333333
-- 114:333333333333373333373333333337733333333333333333333333333333333333333333333333333333333333333333373337333333be7777777777777777777bbbbbbbbbbb1bbbbbb1b1bbbbbb11b1bbbbbbbbbbbbbbbbbbb7735555555555553333333333333333333333333333333333333333333333
-- 115:3333333333333733333733333333377bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b73337333333bbe777777777777777777bbbbbbbbb1bbbbbbbbbbbbbbb11bbbbbbbbbbbbb1bbbbbbbb77735555555555553333333333333333333333333333333333333333333333
-- 116:3333333333333333333733333333377bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbb777733773333333be777777777777777777bbbbbbbbb1b1bbbb1bbb1bbbbbbbbbb1bbbbbbbbbbbbbbbb773335555555555533333333333333333333333333333333333333333333333
-- 117:bbbbb3333333333333373333333337771bbbbb1bbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbb77333377b3333333bbee7777777777777777bbbbbbbb1bbbb1bb1bbbbb1bbb11b1bbbbbbbb1bbbbbbbb3773355555555555333333333333333333333333333333333333333333333333
-- 118:bbbbbbbbbbbbb73333373333333333771bbbbbbbbbbbbbbbbbbbb111111bbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbb7333777733333333bbbee77777777777777777bbbbbbbbbbb11bbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbb3733355555555553333333333333333333333333333333333333333333333333
-- 119:bb1bbbbbbbbbb73333373333333333771bbbbbb1111bbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111b333733333333333bbbbe77777777777777777bbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbbb3735555555555553333333333333333333333333333333333333333333333333
-- 120:b11bbbbbbbbbb7777737333333333337bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbb1bbbbbbbb1bbbbbbbb1b11bbbbb3bbbbbbbb3bbbbbbbbee7777777777777777bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbb3335555555555533333333333333333333333333333333333333333333333333
-- 121:b11bbbbb1bbbb77777777777777333371bbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbb1bbbbb1bbbbbbbb1bbbbbbb7bbbbbbbbbbbbbbbbbee7777777777777777bbb1bb11bb1bbb1bbbb1bb1bbbbbbbbbbbbbb1bbbbbbb355555555555533333333333333333333333333333333333333333333333333
-- 122:bb1bbbbb1bbbbbbbbbb7777bb777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbb11bbbbbbbbbb1bbbbbbb111bbbbbbbbbbbbbbbbbbbe7777777777777777bb1bbbbbbbbbbbbbbbbbb1b1bbb1bb1bbbbbbbbbb1bbbb55555555555333333333333333333333333333333333333333333333333333
-- 123:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbee777777777777777bbbbbbbbbbbbbbbb1b1bbbbbbb1b1bbbbbbbbbbbbbbbb555555555553333333333333333333333333333333333333333333333333333
-- 124:bbbbbbbbbbbbbbbbbbb1bbbbbbbbbb1bb1bbbbbb111bbbbbbbbb1b1b1bbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbe7777777777777777bbb1bbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbb555555555553333333333333333333333333333333333333333333333333333
-- 125:bbb1bbbbbbbbbbbbbbbbb1bbbbbb11bb1bbbbbbbbbbbb1bbb1bb11bbb1bbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbee777777777777777bbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbb5555555555533333333333333333333333333333333333333333333333333333
-- 126:bbbbbbbbbbbbb1bbbbbbbbbbbbbbb1bbbbbbbbbb1bbbbb1bbbbbbbbb1111bbbbbbbb1bbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbe777777777777777bbbbb11bbbbbbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbb5555555555333333333333333333333333333333333333333333333333333333
-- 127:bbbbbbbbbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbb1bbbbb1bbbbbbbbbbbb1bbbbbbbbbbbbbbbbbb111bb1bbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbee777777777777777bbbbb1bbbb11bbbbbbb1111b1bbbbbbbbbbbbbbbbb5555555555333333333333333333333333333333333333333333333333333333
-- 128:1b1b1bbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbb11bbbbbbb11bbbbbbbbbbb111bbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbe777777777777777bbbb1bbbb1b1bbbb1b11bb1b1bbb1bbbbbbbbbbbbb5555555555333333333333333333333333333333333333333333333333333333
-- 129:bbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbb11bbbbb111bb1bbbbb1bb111bbbbbbbbbb111b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbee77777777777777bb11bb11bb1bbbbb11bbbbbbbb11bbbb11bbbbbbb55555555555333333333333333333333333333333333333333333333333333333
-- 130:bbb1bbbbb1bbbbbbbbbbbbbbbbbbbb1bb1bbbbbbbbbb1b11bbbbbbbbbbbbb1bbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbee777777777777777bbbbbbb1bbbb1bb1bb1bbbbbbbb1bbbbbbbbb1bb55555555553333333333333333333333333333333333333333333333333333333
-- 131:bbb11b1bbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbb1bbbbbbbb1bbbbbbbbb1b1bbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbe777777777777777bbbbb11bbbbbbb111bb1bbb1bbbbbbbbbb1bbbb555555555553333333333333333333333333333333333333333333333333333333
-- 132:1bbbbb11bbbbbbb1bbbbbbbbbbbbbbbbbbbb1111bbbbbbbbbbb1bbbbb1bb1b1bbbbbb1bbbbbb1b1bb1bbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbeb777777777777777bbb1bbbb11bb1bb1b1bb11bb11bbbbbbbbbbbb555555555553333333333333333333333333333333333333333333333333333333
-- 133:111bbbbb1bbbbbb111bbbbbbbbbbbbbbbbbb1bbbbbbbb1bbbb1bbb11b1bbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbee7777777777777777bbb1bbbb1bbb1bbbb1bbbbbbbbbbbbbbbbbbb555555555553333333333333333333333333333333333333333333333333333333
-- 134:11b1bbb1bbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbbbbb1bbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbee777777777777771bbbbb1b1b1bb1bb1bbbbbb1bbbbbbbbbbbbb5555555555555333333333333333333333333333333333333333333333333333333
-- 135:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbee7777777777777771bbbbb1bb1bbbbb1bbbb1b1bbbbbbbbbbbbb5555555555555333333333333333333333333333333333333333333333333333333
-- </SCREEN>

-- <PALETTE>
-- 000:00000074b72ea858a82936403b5dc9ff0006ff79c2566c87f4f4f42571794cda85466d1ded820e41a6f6ffe5b4ffe761
-- </PALETTE>

-- <PALETTE1>
-- 000:00000074b72ea858a82936403b5dc9ff0006ff79c2566c87f4f4f42571794cda85466d1ded820e41a6f6ffe5b4ffe761
-- </PALETTE1>

