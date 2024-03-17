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
K_TRANSP_COLOR=5
PID_COLORS={2,10,4,12}
-- sounds
SFX_FOO=0
-- music patterns
MUS_MENU=0
-- sprite ids
SID_PLAYER=288
SID_REFILL=384
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
-- overloaded draw calls that support.
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
  nextv=function(_ENV)
   local v=s[1]:nextv()
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
 cls(0)
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
  players={}, -- see cb_init_players()
  live_player_count=args.player_count,
  balloons={},
  refills={},
  wparts={}, -- water particles
  refill_pings={},
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
 cb_init_players(cb)
 -- spawn refill stations
 -- TODO: parse locations out of map
 local refill_tiles={
  v2(10,7),v2(40,30),v2(47,3),v2(9,26),
 }
 for _,tp in ipairs(refill_tiles) do
  add(cb.refills,{
   pos=v2scl(tp,8),
  })
 end
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
 local spawn_tiles={
  v2( 3, 4), v2(56,20),
  v2( 4,30), v2(56, 4),
 }
 for pid=1,cb.all_player_count do
  local p=cb_create_player(pid)
  p.fpos=v2scl(v2cpy(spawn_tiles[pid]),8)
  -- todo: use fx,fy for movement
  -- and round afterwards
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
    p.health=max(0,p.health-25)
    goto end_balloon_update
   end
  end
  ::end_balloon_update::
  if pop then
   for i=1,50 do
    add(wparts,{
     pos=v2cpy(b.pos),
     vel=v2scl(v2rnd(),0.5+rnd(1)),
     ttl=15+rnd()*10,
     color=i<10 and PID_COLORS[b.pid] or 13,
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
   and max(0,p.speed-0.1)
   or min(1,p.speed+0.1)
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
  end
  -- Update player's camera focus.
  p.focus.x=approach(p.focus.x,p.pos.x+4,.2)//1
  p.focus.y=approach(p.focus.y,p.pos.y+4,.2)//1
  -- handle spawning new balloons
  if p.ammo>0 and btn(pb0+5) then
   p.windup=min(K_MAX_WINDUP,p.windup+1)
  elseif not btn(pb0+5)
  and p.windup>0 then
   p.ammo=max(p.ammo-1,0)
   local dist=lerp(K_MIN_THROW,
    K_MAX_THROW,p.windup/K_MAX_WINDUP)
   local diroff=balloon_origin_offset(p.dir)
   add(balloons,{
    pos0=v2add(p.pos,v2(4,4)),
    pos=v2add(p.pos,v2(4,4)),
    pos1=v2add(p.pos,v2scl(p.dir,dist)),
    t=0,
    t1=40*1,
    pid=p.pid,
    color=p.color,
    r=2, -- radius
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
 cls(0)
 -- draw each player's viewport
 for _,p in ipairs(players) do
  local pclip=clips[p.pid]
  clip(table.unpack(pclip))
  camera(-(p.vpcenter.x-p.focus.x),
         -(p.vpcenter.y-p.focus.y))
  -- draw map
  map(0,0,30*2,17*2,0,0)
  -- draw the players
  for _,p2 in ipairs(players) do -- draw corpses
   draw_player(p2)
  end
  -- draw water particles
  for _,wp in ipairs(wparts) do
   local c=wp.ttl<2 and 3 or wp.color
   pix(wp.pos.x,wp.pos.y,c)
  end
  -- draw balloons
  for _,b in ipairs(balloons) do
   draw_balloon(b.pos.x,b.pos.y,
    b.r,b.color,b.t,b.t1)
  end
  -- draw refill station pings
  for _,rp in ipairs(refill_pings) do
   circb(rp.pos.x,rp.pos.y,rp.radius,rp.radius%16)
  end
  -- draw refill stations
  for _,r in ipairs(refills) do
   spr(SID_REFILL,r.pos.x,r.pos.y,K_TRANSP_COLOR)
   if p.refill_cooldown>0 then
    local h=8*p.refill_cooldown/K_REFILL_COOLDOWN
    rect(r.pos.x,r.pos.y+8-h,8,h,5)
   end
  end
  -- restore screen-space camera
  camera(0,0)
  -- draw player health and ammo bars
  rectb(pclip[1]+2,pclip[2]+2,32,4,12)
  rect(pclip[1]+3,pclip[2]+3,30*p.health/K_MAX_HEALTH,2,2)
  for ib=1,p.ammo do
   circ(pclip[1]+34+ib*6,pclip[2]+4,2,p.color)
   circb(pclip[1]+34+ib*6,pclip[2]+4,2,12)
  end
  -- for low-health/ammo players, draw "refill" prompt
  if p.health<0.3*K_MAX_HEALTH
  or p.ammo==0 then
   print("REFILL!",
         p.vpcenter.x-12,p.vpcenter.y-4,
         15,true)
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
        1,15)
   end
  end
  -- draw "game over" message for eliminated players
  if p.dead then
   rect(p.vpcenter.x-38,p.vpcenter.y-20,75,9,0)
   rectb(p.vpcenter.x-38,p.vpcenter.y-20,75,9,p.color)
   local w=print("KILLED BY PX",p.vpcenter.x-36,p.vpcenter.y-18,p.color,true)
  end
  -- draw viewport border.
  rectb(pclip[1],pclip[2],pclip[3],pclip[4],p.color)
 end
end

function balloon_origin_offset(dir)
 if dir.y<0 then
  return v2(8,-2)
 elseif dir.y>0 then
  return v2(0,-2)
 elseif dir.x<0 then
  return v2(8,-2)
 else
  return v2(0,0)
 end
end

function draw_balloon(x,y,r,color,t,t1)
 local t=t or 0
 local t1=t1 or 1
 local yoff=6*sin(-0.5*t/t1)
 elli(x,y-yoff,
  1+r+sin(.03*t)/2,
  1+r+cos(1.5+.04*t)/2,
  0)
 elli(x,y-yoff,
  r+sin(.03*t)/2,
  r+cos(1.5+.04*t)/2,
  color)
end

function draw_player(player)
 local p=player
 -- draw player
 local prev=peek4(2*0x03FF0+4)
 poke4(2*0x03FF0+4,p.color)
 spr(p.anims:nextv(),
     p.pos.x-4,
     p.pos.y-8,
     K_TRANSP_COLOR,1,p.hflip,0,2,2)
 poke4(2*0x03FF0+4,prev)
 -- draw balloon if winding up
 if p.windup>0 then
  local diroff=balloon_origin_offset(p.dir)
  draw_balloon(
   p.pos.x+diroff.x,
   p.pos.y+diroff.y,
   2,p.color)
 end
end

-- <TILES>
-- 004:0000000000600605056556560066665606665666005666650056666506655666
-- 005:0000000050060050566566656566566666666566655666665566556566656665
-- 006:0000000050050060666566006566650066665500655666605566550066666650
-- 008:7555576666676666666657666676656775676666566777750550666600000666
-- 009:6675555766667666667566667656676666667657577776656666055066600000
-- 020:0655656600656665056666560566565600666666005666650566566506556666
-- 021:6656656665666656666666666655566665666666655666656666656566665666
-- 022:6666560066656600656566606566650066666560655656005566556066656000
-- 024:6675555766667666667566667656676666667657577776656666055066600000
-- 025:7555576666676666666657666676656775676666566777750550666600000666
-- 032:0000000000000000000000000000000000000022002222202220000000200000
-- 033:0000000000000000000000000000000020000000000000200000202020202020
-- 034:0000220002222000220000002000220020202020202020202020220020002020
-- 035:0000002000002002220022002020202020202202220020002020000020000000
-- 036:0555556600666666006656660666656505656666066655650050665600000000
-- 037:6556666666666666665556666666656665656666566566650550665000000000
-- 038:6555655065665600666566005656666066556650565556606566050000000000
-- 048:0020020000200220002002020020020000200200002002000020000000200022
-- 049:2020202020220020202000202000000000000022000020000222200020000000
-- 050:2200202002002200020000002000000000000000000000000000000000000000
-- 064:0020220022220000200000000000000000000000000000000000000000000000
-- 096:2222221122222221222222112222222122222211222222211212121111111111
-- 097:4444443344444443444444334444444344444433444444433434343333333333
-- 098:aaaaaa99aaaaaaa9aaaaaa99aaaaaaa9aaaaaa99aaaaaaa99a9a9a9999999999
-- 099:ccccccbbcccccccbccccccbbcccccccbccccccbbcccccccbbcbcbcbbbbbbbbbb
-- 100:339333a333333933933333333a3333333333a333333933333933339333339333
-- </TILES>

-- <SPRITES>
-- 000:555550005555033455503344555000005550bbee5550ebee5550eeee55550eee
-- 001:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 002:555550005555033455503344555000005550bbee5550ebee5550eeee55550eee
-- 003:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 004:555550005555033455503344555000005550bbee5550ebee5550eeee55550eee
-- 005:000555554440555544440555000000003e3e05553e3e0555eeee0555eee05555
-- 006:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 007:5555555555555555555555555555555555555555555555555555555555555555
-- 008:5555555555555555555555555555555555555555555555555555555555555555
-- 009:5555555555555555555555555555555555555555555555555555555555555555
-- 010:5555555555555555555555555555555555555555555555555555555555555555
-- 011:5555555555555555555555555555555555555555555555555555555555555555
-- 012:5555555555555555555555555555555555555555555555555555555555555555
-- 013:5555555555555555555555555555555555555555555555555555555555555555
-- 014:5555555555555555555555555555555555555555555555555555555555555555
-- 015:5555555555555555555555555555555555555555555555555555555555555555
-- 016:55555000555503445555344455503444555e4444555ee0005550f0005550ff00
-- 017:0005555544405555444405554444e555444ee55500005555000f0555000ff055
-- 018:555550005555034455503444555e3444555ee4445555500055550f0055550ff0
-- 019:0005555544405555444405554444e555444ee5550005555500f0555500ff0555
-- 020:555550005555034455503444555e3444555ee44455555000555550f0555550ff
-- 021:000555554440555544440555444405554444e555000ee5550f0555550ff05555
-- 022:5555555555555555555555555555555555555555555555555555555555555555
-- 023:5555555555555555555555555555555555555555555555555555555555555555
-- 024:5555555555555555555555555555555555555555555555555555555555555555
-- 025:5555555555555555555555555555555555555555555555555555555555555555
-- 026:5555555555555555555555555555555555555555555555555555555555555555
-- 027:5555555555555555555555555555555555555555555555555555555555555555
-- 028:5555555555555555555555555555555555555555555555555555555555555555
-- 029:5555555555555555555555555555555555555555555555555555555555555555
-- 030:5555555555555555555555555555555555555555555555555555555555555555
-- 031:5555555555555555555555555555555555555555555555555555555555555555
-- 032:555550005555033455503344555000005550be3e5550be3e5550eeee55550eee
-- 033:00055555444055554444055500000000e3eb0555e3eb0555eeee0555eee05555
-- 034:555550005555033455503344555000005550be3e5550be3e5550eeee55550eee
-- 035:00055555444055554444055500000000e3eb0555e3eb0555eeee0555eee05555
-- 036:555550005555033455503344555000005550be3e5550be3e5550eeee55550eee
-- 037:00055555444055554444055500000000e3eb0555e3eb0555eeee0555eee05555
-- 038:5555555555555555555555555555555555555555555555555555555555555555
-- 039:5555555555555555555555555555555555555555555555555555555555555555
-- 040:5555555555555555555555555555555555555555555555555555555555555555
-- 041:5555555555555555555555555555555555555555555555555555555555555555
-- 042:5555555555555555555555555555555555555555555555555555555555555555
-- 043:5555555555555555555555555555555555555555555555555555555555555555
-- 044:5555555555555555555555555555555555555555555555555555555555555555
-- 045:5555555555555555555555555555555555555555555555555555555555555555
-- 046:5555555555555555555555555555555555555555555555555555555555555555
-- 047:5555555555555555555555555555555555555555555555555555555555555555
-- 048:55555000555503445550344455503444555e0444555e000055550f0555555555
-- 049:0005555544405555444405554444e5554440e5550005555550f0555550f05555
-- 050:55555000555503445550344455503444555e0444555e000055550f0055550f00
-- 051:000555554440555544440555444405554440e5550000e55500f0555500f05555
-- 052:555550005555034455503444555e3444555e04445555500055550f0555550f05
-- 053:000555554440555544440555444405554440e5550000e55550f0555555555555
-- 054:5555555555555555555555555555555555555555555555555555555555555555
-- 055:5555555555555555555555555555555555555555555555555555555555555555
-- 056:5555555555555555555555555555555555555555555555555555555555555555
-- 057:5555555555555555555555555555555555555555555555555555555555555555
-- 058:5555555555555555555555555555555555555555555555555555555555555555
-- 059:5555555555555555555555555555555555555555555555555555555555555555
-- 060:5555555555555555555555555555555555555555555555555555555555555555
-- 061:5555555555555555555555555555555555555555555555555555555555555555
-- 062:5555555555555555555555555555555555555555555555555555555555555555
-- 063:5555555555555555555555555555555555555555555555555555555555555555
-- 064:555550005555033455503344555000005550bbbb5550bbbb5550eeee55550eee
-- 065:00055555444055554444055500000000bbbb0555bbbb0555eeee0555eee05555
-- 066:555550005555033455503344555000005550bbbb5550bbbb5550eeee55550eee
-- 067:00055555444055554444055500000000bbbb0555bbbb0555eeee0555eee05555
-- 068:555550005555033455503344555000005550bbbb5550bbbb5550eeee55550eee
-- 069:00055555444055554444055500000000bbbb0555bbbb0555eeee0555eee05555
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
-- 080:555550005555034455503444555e3444555e04445555500055550f0555550f05
-- 081:000555554440555544440555444405554440e5550000e55550f0555555555555
-- 082:55555000555503445550344455503444555e0444555e000055550f0055550f00
-- 083:000555554440555544440555444405554440e5550000e55500f0555500f05555
-- 084:55555000555503445550344455503444555e0444555e000055550f0555555555
-- 085:0005555544405555444405554444e5554440e5550005555550f0555550f05555
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
-- 096:555550005555033455503344555000005550bbee5550ebee5550eeee55550eee
-- 097:000555554440555544440555000000053e3e05553e3e0555eeee0555eee05555
-- 098:555550005555033455503344555000005550bbee5550ebde5550eedd55550eee
-- 099:000555554440555544440555000000003e3d05553e3d0555eeee0555eee05555
-- 100:555550005555033455503344555000005550bbee5550ebde5550eedd55550eee
-- 101:000555554440555544440555000000003e3d05553e3d0555eeee0555eee05555
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
-- 112:55555000555503045555034e5555034e555550045555500055550f055550ff05
-- 113:0005555544405555e4405555e4405555444055550005555550f0555550ff0555
-- 114:555550005555034d55e0344455e034dd5555044d55555000555550f055550ff0
-- 115:00055555d440555544d40e5544dd0e5544405555000555550f0555550ff05555
-- 116:555550005555034d5555044455e034dd55e0534d55555000555550f055550ff0
-- 117:00055555d440555544d0555544dd0e5544450e55000555550f0555550ff05555
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
-- 128:555555555555555555555555577777757dd4dd4774dd4dd73777777603777765
-- 129:5555555555577755557733755573537555735555557355555a73a55555999555
-- 130:5555555555577755557733755573537555735445557355555a73a55555999555
-- 131:5555555555577755557733755573537555735445557355455a73a55555999555
-- 132:5555555555577755557733755573537555735555557355455a73a54555999555
-- 133:5555555555577755557733755573537555735555557355555a73a55555999545
-- 134:5555555555555555555555555555555555555555555555555555555555555555
-- 135:5555555555555555555555555555555555555555555555555555555555555555
-- 136:5555555555555555555555555555555555555555555555555555555555555555
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
-- 160:5555555555555555555555555555555555555555555555555555555555555555
-- 161:5555555555555555555555555555555555555555555555555555555555555555
-- 162:5555555555555555555555555555555555555555555555555555555555555555
-- 163:5555555555555555555555555555555555555555555555555555555555555555
-- 164:5555555555555555555555555555555555555555555555555555555555555555
-- 165:5555555555555555555555555555555555555555555555555555555555555555
-- 166:5555555555555555555555555555555555555555555555555555555555555555
-- 167:5555555555555555555555555555555555555555555555555555555555555555
-- 168:5555555555555555555555555555555555555555555555555555555555555555
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:5555555555555555555555555555555555555555555555555555555555555555
-- 171:5555555555555555555555555555555555555555555555555555555555555555
-- 172:5555555555555555555555555555555555555555555555555555555555555555
-- 173:5555555555555555555555555555555555555555555555555555555555555555
-- 174:5555555555555555555555555555555555555555555555555555555555555555
-- 175:5555555555555555555555555555555555555555555555555555555555555555
-- 176:5555555555555555555555555555555555555555555555555555555555555555
-- 177:5555555555555555555555555555555555555555555555555555555555555555
-- 178:5555555555555555555555555555555555555555555555555555555555555555
-- 179:5555555555555555555555555555555555555555555555555555555555555555
-- 180:5555555555555555555555555555555555555555555555555555555555555555
-- 181:5555555555555555555555555555555555555555555555555555555555555555
-- 182:5555555555555555555555555555555555555555555555555555555555555555
-- 183:5555555555555555555555555555555555555555555555555555555555555555
-- 184:5555555555555555555555555555555555555555555555555555555555555555
-- 185:5555555555555555555555555555555555555555555555555555555555555555
-- 186:5555555555555555555555555555555555555555555555555555555555555555
-- 187:5555555555555555555555555555555555555555555555555555555555555555
-- 188:5555555555555555555555555555555555555555555555555555555555555555
-- 189:5555555555555555555555555555555555555555555555555555555555555555
-- 190:5555555555555555555555555555555555555555555555555555555555555555
-- 191:5555555555555555555555555555555555555555555555555555555555555555
-- 192:5555555555555555555555555555555555555555555555555555555555555555
-- 193:5555555555555555555555555555555555555555555555555555555555555555
-- 194:5555555555555555555555555555555555555555555555555555555555555555
-- 195:5555555555555555555555555555555555555555555555555555555555555555
-- 196:5555555555555555555555555555555555555555555555555555555555555555
-- 197:5555555555555555555555555555555555555555555555555555555555555555
-- 198:5555555555555555555555555555555555555555555555555555555555555555
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
-- 000:060606060606060606060606060606060606060606060606060606060606363636363636363636363636363636363636363636363636363636363636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:064646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464636364646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:064646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464636364646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:064646464646460606460606064646464646464646464646464646464646464646464646464646464646464646464646464636364646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:064646464646460606460606064646464646464646464646464646464646363636363646464646464646464646464646464636364646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:064646464646460606460606064646464646464646464646464646464646363636363646464646464646464646464636363636364646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:064646464646460606460606064646464646464646464646464646464646464646464646464646464646464646464636363636364646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:064646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:064646464646464646460606064646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:064646464646464646460606060646464646464646464646464646464646464646464646464636363646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:064646464646464646464646464646464646464646464646464646464646464646464646464636363646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:064646464646464646464646464646060606060646464646464646464646464646464646464636363646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:064646464646464646464646464646060606060646464646464646464646464646464646464636363646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:064646464646464646464646464646464646060646464646464646464646464646464646464646464646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:064646464646464646464646464646464646060646464646464646464646464646464646464646464646464646464646464646464646464646464636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:064646464646060606064646464646464646060646464646464646460606363646464646464646464646464646464646464646464636363636363636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:064646464646060606064646464646464646060646464646464646460606363646464646464646464646464646464646464646464636363636363636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:164646464646161616164646464646464646464646464646464646461616262646464646464646464646464646464646464646464626262626262626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:164646464646461616164646464646464646464646464646464646461616262646464646464646464646464646464646464646464626264646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:164646464646461616164646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:164646464646461616164646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:164646464646461616164646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:164646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:164646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646462626262626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:164646464646464646464646464646464646461616464646464646464646464646464646464646464646464646464646464646464646462626262626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:164646464646464646464646464646464646461616464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:161616161616164646464646464646464646461616464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:161616161616164646464646464646464646461616464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:161646464646464646464646464646464646461616464646464646464646464646464646464646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:164646464646464646464646464646464646464646464646464646464646464646464626264646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:164646464646464646464646464646464646464646464646464646464646464646462626264646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:164646464646464646464646464646464646464646464646464646464646464646262626264646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:164646464646464646464646464646464646464646464646464646464646464626262626264646464646464646464646464646464646464646464626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:161616161616161616161616161616161616161616161616161616161616262626262626262626262626262626262626262626262626262626262626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:00000000101010001010000000000000000000001010100010100000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:0000005d275da858a82936403b5dc9ff0006ff79c2566c87f4f4f42571794cda85be5504ed820e41a6f6ffe5b4ffe761
-- </PALETTE>

