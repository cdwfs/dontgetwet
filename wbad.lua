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
TEAM_COLORS={6,12,13,10}
TEAM_COLORS2={2,9,4,11}
TEAM_NAMES={"Pink","Orange","Blue","Green"}
C_WHITE=8
C_BLACK=0
C_DARKGREY=3
C_LIGHTGREY=7
C_DARKGREEN=11
C_LIGHTBLUE=13
C_RED=5
C_TRANSPARENT=5 -- by default
C_YELLOW=15
-- sounds
SFX_STEP=1
SFX_MENU_CONFIRM=18
SFX_MENU_MOVE=19
SFX_MENU_CANCEL=20
SFX_WINDUP=21
SFX_THROW=22
SFX_BALLOONPOP=23
SFX_PLAYERHIT=24
SFX_REFILL=25
SFX_ELIMINATED=26
-- music tracks
MUS_MENU=0
-- map tile ids
TID_GRASS0=100
TID_GRASS_POOL={64,65,66,67,80,81,82,83,96,97,98,99}
TID_GRASS_NOMOVE=2
TID_SPAWN_TREE=112
TID_SPAWN_MBARS=113
TID_SPAWN_SWING=114
TID_SPAWN_REFILL=115
TID_SPAWN_PLAYER=116
TID_SPAWN_ELEPHANT=117
TID_SPAWN_XXX=118
TID_SPAWN_BUSH=119
TID_SPAWN_SIGN=128
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
tic80elli=elli
elli=function(x,y,a,b,color)
 tic80elli(x-camera_x,y-camera_y,a,b,color)
end
tic80ellib=ellib
ellib=function(x,y,a,b,color)
 tic80ellib(x-camera_x,y-camera_y,a,b,color)
end
tic80print=print
print=function(text,x,y,...)
 return tic80print(text,
  x-camera_x,y-camera_y,...)
end
tic80pix=pix
pix=function(x,y,color)
 return tic80pix(x-camera_x,y-camera_y,color)
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
  help=help_enter,
  credits=cred_enter,
  teams=team_enter,
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
 --music(MUS_MENU)
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
  selected=0,
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
  if selected==0 and btnp(2) then
   sfx(SFX_MENU_MOVE,"D-5",-1,1)
   player_count=(player_count-2+2)%3+2
  elseif selected==0 and btnp(3) then
   sfx(SFX_MENU_MOVE,"D-5",-1,1)
   player_count=(player_count-2+1)%3+2
  elseif btnp(0) then
   selected=(selected+2)%3
  elseif btnp(1) then
   selected=(selected+1)%3
  end
  if btnp(4) then
   sfx(SFX_MENU_CONFIRM,"D-5",-1,1)
   ignore_input=true
   -- fade to black & advance to next mode
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     if selected==0 then
      set_next_mode("combat",{
       player_count=player_count,
      })
     elseif selected==1 then
      set_next_mode("help",{})
     elseif selected==2 then
      set_next_mode("credits",{})
     end
    end,
    30)
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
         34,90,
         selected==0 and C_WHITE or C_LIGHTGREY,
         C_BLACK,true)
 dsprint("  Help",34,98,
         selected==1 and C_WHITE or C_LIGHTGREY,
         C_BLACK,true)
 dsprint("  Credits",34,106,
         selected==2 and C_WHITE or C_LIGHTGREY,
         C_BLACK,true)
end

------ HELP

help={}

function help_enter(args)
 sync(1|2|4|32,1)
 camera(0,0)
 cls(0)
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  30)
 help=obj({
  update=help_update,
  draw=help_draw,
  leave=help_leave,
  ignore_input=false,
 })
 return help
end

function help_leave(_ENV)
 clip()
 music()
end

function help_update(_ENV)
 -- input
 if not ignore_input then
  if btnp(5) then
   sfx(SFX_MENU_CONFIRM,"D-5",-1,1)
   ignore_input=true
   -- fade to black & advance to next mode
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     set_next_mode("menu",{
     })
    end,
    30)
  end
 end
end

function help_draw(_ENV)
 cls(C_DARKGREY)
 print("Help goes here!",50,50,C_WHITE)
 print("(B) Back", 40,124,C_WHITE)
end

------ CREDITS

cred={}

function cred_enter(args)
 sync(1|2|4|32,1)
 camera(0,0)
 cls(0)
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  30)
 cred=obj({
  update=cred_update,
  draw=cred_draw,
  leave=cred_leave,
  ignore_input=false,
 })
 return cred
end

function cred_leave(_ENV)
 clip()
 music()
end

function cred_update(_ENV)
 -- input
 if not ignore_input then
  if btnp(5) then
   sfx(SFX_MENU_CONFIRM,"D-5",-1,1)
   ignore_input=true
   -- fade to black & advance to next mode
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     set_next_mode("menu",{
     })
    end,
    30)
  end
 end
end

function cred_draw(_ENV)
 cls(C_DARKGREY)
 print("Credits go here!",50,50,C_WHITE)
 print("(B) Back", 40,124,C_WHITE)
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
  signs={},
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
 local function rnd_grass()
  return TID_GRASS_POOL[
   math.random(#TID_GRASS_POOL)]
 end
 for my=0,135 do
  for mx=0,239 do
   local tid=mget(mx,my)
   if tid==TID_GRASS0 then
    mset(mx,my,rnd_grass())
   elseif tid==TID_SPAWN_TREE then
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
    mset(mx+1,my,rnd_grass())
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
    mset(mx,my,rnd_grass())
   elseif tid==TID_SPAWN_PLAYER then
    add(cb.player_spawns,v2(mx,my))
    mset(mx,my,rnd_grass())
   elseif tid==TID_SPAWN_BUSH then
    local dx,dy=rnd(4)//1,rnd(7)//1
    add(cb.bushes,{
     pos=v2(mx*8+dx,my*8+dy),
     flip=flr(rnd(2)),
     bounds0=v2(mx*8+dx-8,my*8+dy-8),
     bounds1=v2(mx*8+dx+7,my*8+dy+7),
    })
    mset(mx,my,rnd_grass())
   elseif tid==TID_SPAWN_SIGN then
    add(cb.signs,{
     pos=v2(mx*8,my*8),
     bounds0=v2(mx*8, my*8-16),
     bounds1=v2(mx*8+39, my*8+7),
    })
    for x=mx,mx+5 do
     mset(x,my,TID_GRASS_NOMOVE)
    end
   end
  end
 end
 -- spawn players
 cb_init_players(cb)
 return cb
end

function create_player(pid,team)
 p={
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
  color2=TEAM_COLORS2[team],
  pid=pid,
  team=team,
  running=false,
  speed=0, -- how far to move in current dir per frame
  energy=K_MAX_ENERGY,
  ammo=K_MAX_AMMO,
  refill_cooldown=0,
  eliminated=false,
  windup=0,
  facelr=464,
  faced=480,
  faceu=496,
  skinc=14,
  hairc=12,
  anims=animgraph({
   idlelr={anim({428},8),"idlelr"},
   idled={anim({444},8),"idled"},
   idleu={anim({460},8),"idleu"},
   walklr={anim({426,428,430,428},8),"walklr"},
   walkd={anim({442,444,446,444},8),"walkd"},
   walku={anim({458,460,462,460},8),"walku"},
  },"idlelr"),
  hflip=0,
 }
 -- randomize face
 local iface=2*math.random(0,5)
 p.facelr=p.facelr+iface
 p.faced=p.faced+iface
 p.faceu=p.faceu+iface
 -- randomize skin/hair
 local skinhairs={
  {14,12}, -- fair/orange
  {14,9},  -- fair/brown
  {14,3},  -- fair/black
  {14,15}, -- fair/blonde
  {9,3},   -- dark/black
 }
 p.skinc,p.hairc=table.unpack(
  skinhairs[math.random(#skinhairs)]
 )
 return p
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
    goto end_balloon_update
   end
  end
  ::end_balloon_update::
  if pop then
   sfx(SFX_BALLOONPOP,6*12+math.random(0,4),
    -1,2)
   -- check for nearby players and
   -- assign splash damage
   local max_dst2=K_SPLASH_DIST*K_SPLASH_DIST
   for _,p in ipairs(players) do
    local pc=v2add(p.pos,v2(4,4))
    local dst2=v2dstsq(pc,b.pos)
    if b.pid~=p.pid and dst2<max_dst2 then
     local dmg=lerp(K_ENERGY_HIT,
                    K_ENERGY_SPLASH,
                    dst2/max_dst2)
     p.energy=max(0,p.energy-dmg)
     -- don't play "hit" sound on the
     -- same frame as "eliminated"
     if p.energy>0 then
      sfx(SFX_PLAYERHIT,3*12+math.random(10,22),
       -1,1)
     end
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
   sfx(SFX_ELIMINATED,4*12+math.random(0,4),
    -1,0)
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
  -- update animation state &
  -- trigger footstep sounds
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
   if mode_frames%15==p.pid then
    sfx(SFX_STEP,6*12+math.random(-4,4),
     -1,3)
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
   if p.windup==0 then
    sfx(SFX_WINDUP,2*12+math.random(5,9),
     -1,1)
   end
   p.windup=min(K_MAX_WINDUP,p.windup+1)
  elseif not btn(pb0+5)
  and p.windup>0 then
   sfx(SFX_THROW,3*12+math.random(7,11),
    -1,1)
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
    sfx(SFX_REFILL,4*12+2,-1,1)
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
      players=players,
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
         5,2,C_DARKGREY)
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
    elli(b.pos.x,b.pos.y+2,b.r,2,C_DARKGREY)
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
     10,3,C_DARKGREY)
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
         8,2,C_DARKGREY)
    add(draws,{
     order=b.pos.y, order2=b.pos.x,
     f=function(b)
      spr(SID_BUSH, b.pos.x-8, b.pos.y-8,
       C_TRANSPARENT, 1,b.flip,0, 2,2)
     end, args={b}
    })
   end
  end
  -- draw signs
  for _,s in ipairs(signs) do
   if rects_overlap(cull0,cull1,
       s.bounds0, s.bounds1) then
    rect(s.pos.x-1,s.pos.y+5,
         42,3,C_DARKGREY)
    add(draws,{
     order=s.pos.y, order2=s.pos.x,
     f=function(s)
      local signw,sx,sy=4,s.pos.x,
                        s.pos.y-16
      spr(331, sx,sy,
          C_TRANSPARENT, 1,0,0, 1,3)
      for i=1,signw do
       spr(332, sx+i*8,sy,
           C_TRANSPARENT, 1,0,0, 1,3)
      end
      spr(333, sx+8+signw*8,sy,
          C_TRANSPARENT, 1,0,0, 1,3)
      print("NO CAMPING\n  ALLOWED!",
            sx+6,s.pos.y-16+5,
            C_BLACK,false,1,true)
     end, args={s}
    })
   end
  end
  -- draw monkey bars
  for _,m in ipairs(mbars) do
   if rects_overlap(cull0,cull1,
       m.bounds0, m.bounds1) then
    line(m.pos.x,m.pos.y+7,
         m.pos.x+23,m.pos.y+7,C_DARKGREY)
    line(m.pos.x+6,m.pos.y+5,
         m.pos.x+17,m.pos.y+5,C_DARKGREY)
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
         s.pos.x+26,s.pos.y+5,C_DARKGREY)
    elli(s.pos.x+10,s.pos.y+6,4,1,C_DARKGREY)
    elli(s.pos.x+21,s.pos.y+6,4,1,C_DARKGREY)
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
    elli(e.pos.x+4,e.pos.y+7,7,2,C_DARKGREY)
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
    elli(r.pos.x+4,r.pos.y+7,6,2,C_DARKGREY)
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
 local face=p.facelr
 if p.dir.y<0 then face=p.faceu
 elseif p.dir.y>0 then face=p.faced
 end
 -- head-bob?
 --local facey=(not v2eq(p.move,v2zero)
 --             and p.anims.s[1].i==1)
 --  and p.pos.y-7 or p.pos.y-8
 local PAL_C1=13
 local PAL_C2=4
 local PAL_H=12
 local PAL_S=14
 local prevc1=peek4(2*0x03FF0+PAL_C1)
 local prevc2=peek4(2*0x03FF0+PAL_C2)
 local prevh= peek4(2*0x03FF0+PAL_H)
 local prevs= peek4(2*0x03FF0+PAL_S)
 poke4(2*0x03FF0+PAL_C1,p.color)
 poke4(2*0x03FF0+PAL_C2,p.color2)
 poke4(2*0x03FF0+PAL_H,p.hairc)
 poke4(2*0x03FF0+PAL_S,p.skinc)
 spr(p.anims.v,p.pos.x-4,p.pos.y,
     C_TRANSPARENT, 1,p.hflip,0, 2,1)
 spr(face,p.pos.x-4,p.pos.y-8,
     C_TRANSPARENT, 1,p.hflip,0, 2,1)
 poke4(2*0x03FF0+PAL_C1,prevc1)
 poke4(2*0x03FF0+PAL_C2,prevc2)
 poke4(2*0x03FF0+PAL_H,prevh)
 poke4(2*0x03FF0+PAL_S,prevs)
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
  players=args.players,
  winning_team=args.winning_team,
  grnd_y=80,
  drop_spawns={},
  drops={},
 })
 -- place players
 local x0,x1=60,180
 local dx=(x1-x0)/(#vt.players-1)
 for _,p in ipairs(vt.players) do
  p.pos=v2(flr(x0+(p.pid-1)*dx-4),
           vt.grnd_y)
  p.y0=vt.grnd_y
  p.anims:to("idlelr")
 end
 -- Make a list of all pixels in a
 -- sprite that are not transparent.
 local sprites={464,465,}
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
 if btnp(0*8+5) or btnp(1*8+5)
 or btnp(2*8+5) or btnp(3*8+5) then
  sfx(SFX_MENU_CONFIRM,"D-5",-1,1)
  set_next_mode("menu",{
   player_count=#players,
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
 cls(C_BLACK)
 -- draw message
 local msgc=(winning_team>0)
   and TEAM_COLORS[winning_team]
    or C_WHITE
 local msg=(winning_team>0)
   and ""..TEAM_NAMES[winning_team].." Team wins!"
    or "It's a tie!"
 local msgw=print(msg,0,200)
 dsprint(msg,120-msgw/2,100,msgc,C_BLACK)
 -- draw players
 for _,p in ipairs(players) do
  if p.team==winning_team then
   local srx=lerp(5,3,(p.y0-p.pos.y)/10)
   local sry=lerp(2,1,(p.y0-p.pos.y)/10)
   elli(p.pos.x+4,p.y0+7,srx,sry,C_DARKGREY)
  else
   elli(p.pos.x+4,p.y0+7,6,3,C_LIGHTBLUE)
  end
  draw_player(p)
 end
 -- draw water drops
 for _,d in ipairs(drops) do
  pix(d.pos.x,d.pos.y,C_LIGHTBLUE)
 end
 print("(B) Main Menu",40,124,C_WHITE)
end
-- <TILES>
-- 000:3333333333333333333333333333333333333333333333333333333333333333
-- 002:9bbbbbb1bbbbbbb1bbbbbbbbbbbbbbfbb1bb1b1bb1bb1bbbb1bbb37bbbbbbbbb
-- 019:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 064:bbbbbbbbb9bbbbbbbbbb7bbbbbbbbb1bb1bbfb1bbbbb1bbbb1bbbbb1b1bbbbbb
-- 065:bb9bbbbbbbabbb7bbbabbbbbbbbbbb1bbbbb7b1bbbbbbbbb71bbbbbbb1bbbbbb
-- 066:bbbbbbbbfbb9bbbbbabbbb9bbabb1bbbbbb1bbbbbbb1bbbbb9bbbb1bbbbbbbab
-- 067:bbabbbbbbbabbbbbbbbb1bbbbbbb1bbbbbbb1bbbbbbb1b5bb1bbbbab1bbbbbbb
-- 080:bbbbbb37b1bbb377b1bbabbbb9bbb1bbbb1bbbbbabbbbb2babbbbbabbbbbbbbb
-- 081:bbbbbbbbb1b9bbbbb1bbbbbabbbbbbbabbbbbbbb19bb137b1bb1b37bbbb1bbbb
-- 082:bbbbbb1bbbbbbbb1bbb1bbb1bbbbbbbbbbbbbbbbbb1bfbbbb1bbab7bb1bbbb7b
-- 083:bbbb7bbbbbbbbbbb9bbbbbbbbbbbbbbbbfbbbbbbbbabbbabbbabbabb9bbbbabb
-- 096:bbbfbbbbbbbabbbb1bbbbbbb1bbbbbb11bb9bbb1b1bbbbb1b1bb9b1bb1bbbbbb
-- 097:bbbbbbbbbbbbbb3bb7bb1bbb1bbb1bbbbbbb1bb1bbab1b91bbab1bbbbbabbbbb
-- 098:bbbbbbbbb3bbbbbb1bbbbbbbbb1bb1babbbbb11bb1bbba3bbb1bba7bbb1bbbbb
-- 099:bbb9bbbbbbbbbbbbbbbbbbb1bbbbbb1bb1bbbb1b1bbfbbbb1bbabb9b17bbbbbb
-- 100:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 112:110000111001100100b11b0000b11b000b1111b0000cc000100cc00111000011
-- 113:1100001117777771070c0c7007cccc7007000070070000701700007111000011
-- 114:1100001117777771070400700704007007040070070cc0701700007111000011
-- 115:1100001110aa000100acc0000055c20007552270074444701077770111000011
-- 116:1108881110888801008800000088800000088800000088001088880111888011
-- 117:11000711100887710078877007777707077777070000c007100c00011100c011
-- 118:110000111044000104dddd4004ddddd004ddddd0004444401000000111000011
-- 119:110b0011100b70010b070b700b7a07000ababab000a0ab0010b0b00111000011
-- 128:11000011100000010999999009eeee9009999990090000901000000111000011
-- 129:1100001110000001044000000004700000007440000070001000000111000011
-- 130:1100001110000001000000000007700000777000000000001000000111000011
-- 131:1100001110000001000700000007700000077700000000001000000111000011
-- 132:1100001110000001000000000077770007777770000000001000000111000011
-- 133:1100001110007001007777000777777007777770007777701077770111000011
-- 134:1100001110088001008dd80000d88d0000d88d0000dddd0010dddd0111000011
-- 144:bbbbb1b1bfb17bb11bb11bb9bb9bb9941b999444b9444444b944d44494444444
-- 145:b1b99bbbbb9449b599444491444d444944444444444444444444444444444444
-- 146:bbb137b1fbbbbbbb19999bbb44444999444444444444444444d444d444d44444
-- 147:1bbbbbbb1bbbb11bbbb1bbbbbb77bbfb9bbbbbb149bbbbb1449b1bbb4449bbbb
-- 157:0000000000000000000000000000000000000000000000000000000000000001
-- 160:94d4444494444d4494444444b9444444bb199444b11bb944bbbb1944bbbb1b94
-- 161:44444444444444d44444444444444444444444444d4444444444d4444444d444
-- 162:4444444444444444444444444444444444d44444444444444444444444444444
-- 163:4449b1114449bbb14449bb1b444499bb4444449b44d4449b444449bb444441bb
-- 164:4449bb2b444499194444449444444444444444444444444444444495444449b1
-- 165:1bbbfbbb999b1b994499999444444444444444444444414494449199b999bbbb
-- 166:1999999194444449444444444444444444494444449119449951bb19bbbbbb1b
-- 167:b999999194444499444444494444444944444412444444919444449bb9444449
-- 168:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 172:bbb1bbb1bbb1bbb11bb1bb7711bb77b7bbb77777bbb77797bb117777b1177777
-- 173:bbbb1bb1bbbb1bb1b77777b77777777777777737777777777737777777777777
-- 174:bbb1bbbb7bb1bb1b77bbb1bb7177b1bb777771bb77777b117797b71b7777771b
-- 176:b1bbbbb9b1b1bbbbbbb1bb1bbbbbbbbbbbbbbbb2b1bfb11bb1b1bbbbb1bbbbbb
-- 177:44444d4491444444b1944444b1b99444bbbb1919bbfb131bbb1bb7bbbb1bbbbb
-- 178:444dd444444d4444444444494499999519bfbbb11b11bb9b1bbbb1bbbb7bb1bb
-- 179:44499b1b999bbb1bbbb1b91bbb1bbbbb1bfbbbb71bbbb2bbbbb1b1bbb9b1bbbb
-- 182:9444449b9444449b9444491b9444491b294449bb1944449bb944449b94444491
-- 183:b9444449b9444449b5944449b1944449bb94449fb9444491b944449b19444449
-- 188:b1777777b1b737771b7777771b7777771b777777bb777797bb777777bb177777
-- 189:777977777b77777777777777777771777777777777777779177777777777b777
-- 190:77777bb1777777b1737777b1777777bb777777b1777777b177737b1b7777771b
-- 198:944444919444449bb9444491b144445b1944491b944449bb944449b19444449b
-- 199:19444449b94444491944449bb144441bb1944491bb9444491b944449b9444449
-- 204:b1777777b1797377bbb77777bb177777b11b7717b1bb1b77b1bb1bb7bbbbbbbb
-- 205:77777777777779777777777779777777777777171b7777711bb11bb1bbbbbbbb
-- 206:7777777b777717bb79777bbb7777711b7b77b1b17711bbb1bb1bbbb1bbbbbbbb
-- 208:0000000007333307073333070733330707300000073073330000733307307330
-- 209:0000000033330733333307333333073300000000333073333330733300000000
-- 210:0000000030733330307333303073333000003330333033303330000007307330
-- 214:b944449b94444449944444449444444494444444944444449944f9941999b1b9
-- 215:b944449b9444444944444449444444494444444944444449499144999b1b9991
-- 220:bbbbbbbbbbbb77b7bb77777717779717bb777777b7777777bb3777771777777b
-- 221:bbbbbbbb77777b77777777777737777777777777777b7777b7777977bbbbbbab
-- 222:bbbbbb117b7b7b1b7977771b777777bb7777377b7777777b777717bbb777777b
-- 224:0730733007307330073073300000733007307330073000000730733007307330
-- 226:0730733007307330073073300730000007307330000073300730733007307330
-- 236:b777777bb777777a1b77773b1777777bb7777b1bb779771bb7777771b77777bb
-- 238:b77777bb777777b777777777777977777777717717b77777777773771777777b
-- 240:0730733000007333073073330730733307300000073333070733330700000000
-- 241:0000000033330733333307333333073300000000333073333330733300000000
-- 242:0730733033300000333073303330733000007330307333303073333000000000
-- 252:b777777bbb717777b7777777177377771b7717771b711797bbb1b7b7bbbbbbbb
-- 254:1777777b777779bb77777771777777b17173777b771717bb7b17b1bbbbbbbbbb
-- </TILES>

-- <TILES1>
-- 001:3333373333333733333337333333377333333773333337733333377333333773
-- 002:55555555555555555555555555555555555555555555555555555555555ddddd
-- 003:55555555555555555555555555555555555555555555555555555555ddddd555
-- 004:55555555555555555555555555555555555555555555555d55dd45dfddd445df
-- 005:5555555555555555555555555555555555555555dddd5555f4444555f4444455
-- 006:1b1b1bbbbbbbb1bbbbb1bbbbbbb11b1b1bbbbb11111bbbbb11b1bbb1bbbbbbbb
-- 007:bbbbbbbbb1bbbbbbb1bbbbbbbbbbbb11bbbbbbb11bbbbbb1bbbbbb11bbbbbbbb
-- 008:bb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbb
-- 009:bbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 010:3733337337333373373333733733337337333373373333733733337337333773
-- 011:33ee777733ee7777337e7777333e7777333ee777333ee777333ee7773333e777
-- 012:5555555555555555555555555555555f5555555f55555fff55555ffc55555ffc
-- 013:5fffccccfffcccccffccccccfcccccccfccccccccccccccccccccccccccccccc
-- 014:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 015:5555555555555555555555555555555555555555555555555555555555555555
-- 017:3333337333333373333333733333337333333773333337733333377333333773
-- 018:55dd44445dd444445dd444445d4444445d444444544444475444377755437777
-- 019:4444dddd44444dd544444dd54444444544444455777ee5557777e5557777e555
-- 020:d4455d4455555d4455555444555554445555574455555e7755555e7755555e77
-- 021:44444d5544444d5544444d5544444d55444445554dd555555555555555555555
-- 026:373337333733373337333733b73337337733773333377b333777733337333333
-- 027:3333ee773333ee773333be773333bbe733333be733333bbe33333bbb33333bbb
-- 028:5555555555555abb55555ab155555ab155555bbb55555bbb5555555a5555555e
-- 029:abbb5555bb1ba555bbbba55511bba555bbbba555bbbba5557bba55557b775555
-- 030:5555bbbb55bbbbbb5bb33bbb5bb3bbbb5bbbbbbb5bb333335733377757737777
-- 031:aaa55555bbaa5555bbbaaa55bbbbaaaabbbbbbbb37ee5555777e5555777e5555
-- 032:3333377333333773333337733333377333333773333337733333377333333773
-- 033:555555555555555555555555555555555555555555555555555555555555555d
-- 034:55337777553377775533777755377777555777775557777ed4444444d4444444
-- 035:777ee555777e5555777e555577ee5555eeee5555ee555555444ddddd44444444
-- 036:55555e7755555e7755555e7755555e775555ee775555e777d555e777dd5ee777
-- 037:3333333333333333333333333333333333333333bbbbb333bbbbbbbbbb1bbbbb
-- 038:333337333333373333333733333337333333333333333333bbbbb733bbbbb733
-- 039:3337333333373333333733333337333333373333333733333337333333373333
-- 040:3333377333333773333337733333377b3333377b333337773333337733333377
-- 042:bbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 043:3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 044:5555555e5555555e5555555e5555555e5555555e5555555e5555555e5555555e
-- 045:7775555577755555777555557775555577755555777fffff777faaabe77aabbb
-- 046:5577777755777777557777775577777755777777ff7777eebbbbbbbbbbbbbbbb
-- 047:77ee555577e555557ee555557ee55555ee555555e55555558b555555bba55555
-- 048:3333373333333733333337333333373333333733333337333333373333333733
-- 049:555555dd55555dd455555d4455555d4455555d4455555d445555dd445555d444
-- 050:4444444444444444444444444444444444444444444444444444444444444444
-- 051:4444444444444444444444444444444444444444444444444444444d4444444d
-- 052:4d4e77774447777744477777444777774447777744477775d555555555555555
-- 053:b11bbbbbb11bbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbb
-- 054:bbbbb7771bbbb7771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb
-- 055:7737333377777777bbb7777bbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbbbbb1bbbb
-- 056:3333333777733337b777bbbbbbbbbbbbbbbbbb1bbbbb11bbbbbbb1bbbbbbb1bb
-- 058:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 060:5555555e55555555555555555555555555555555555555555555555555555555
-- 061:e7aabbbbeaabbaabeaaaaaaaaaaaaaaa5aaaaaaa5555aaaa5555555a5555555a
-- 062:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 063:bbb85555bbbb8555bbbba855bbbbba85bbbbba85bbbbbba8bbbbbbaabbbbabba
-- 064:3333333333333333337333333373333333773333333733333337333333377333
-- 065:5555d4445555d4445555d4445555d4445555d4445555d4445555444455554444
-- 067:4444444d4444444d4444444d444444d5444444d5444444d54444445544444455
-- 068:333333333333333333333333bbbbbbbbbbbbbbbb1bbbbb1b1bbbbbbb1bbbbbb1
-- 069:333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbb
-- 070:333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbbbbb
-- 071:333333333333333333333333bbbbbbbbbbbbbbbbb11bbbbb111bbbbb11bbbbbb
-- 072:333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 073:333333333333333333333333bbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 074:333333333333333333333333bbbbbbbbbbb1bbbbbbbbbb11bbbbb111bbbbbbbb
-- 075:333333333333333333333333bbbbbbb3bbbbbb77bbbbb773bbbbb73311111b33
-- 077:5555555a5555555a5555555a555555aa555555aa555555aa555555aa555555aa
-- 079:bbbbabbabbbbabbabbbbabbabbbbabbabbbbabbebbbbaabebbbbbaeebbbbbae7
-- 080:3337333333377333333373333337733333377333333773333337733333373333
-- 081:5555444455554444555544445555444455554444555544445555444455554444
-- 083:4444445544444455444444554444445544444455444444554444445544444455
-- 084:bbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbb1bbbbbbbbbbbbbbbbbbbbbbb
-- 085:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111bbbbbbbbbb1bb1bbbbb1b1bbbbb1b
-- 086:bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b1bbbb1b1bb1bb11bbbbbbbbbbbbbbbbbb
-- 087:1bbbbbbbbb11bbbbbb1bbbbbbbbbbbbb1bbbbbbbb1bbbbbb1111bbbbbbb1bbbb
-- 088:bbbb1bbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbb
-- 089:bbbbb1bbb1bbbbb1b11bbbbbbbbbbbbbbbbbbbb1bbb1bbbbbbbbbbbbbbbbbb11
-- 090:bbbbbb1bbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11bb1bbbb
-- 091:11bbbbb31bbbbbbbbbbbb111b1bbbbbbbb1bbbbbbbbb11bbbbbbbbbbb11bbbbb
-- 092:5555555555555555555555555555555555555555333333333333333333333333
-- 093:555555aa555555aa555555aa555555aa555555aa333333aa3333333a3333333a
-- 095:bbbbbee7bbbbbe77bbbbbe77bbbbee77bbbbee77bbeee777bbe7e777bbe7e777
-- 096:5555555555555555555555555555555555555555355555553333333333333333
-- 097:5555444455554444555544445555444455554444555544443333444433334444
-- 099:4444445544444455444444554444445544444455444444334444443344444433
-- 100:bbbbbbbb11bbbbbbb1bbbbbbbbbbbbbbbbbb1111bbbb1bbbbbbbbbbbbbbbbbbb
-- 101:bbbbbbbbbbb11bbbbbbb1b11bbbbbbb1bbbbbbbbbbbbb1bbbbbbbb1bbbbbbbbb
-- 102:11bbbbb1bb111bb1bbbbbbbbbbbbbbbbbbb1bbbbbb1bbb111bbbbbbbbbbbbbbb
-- 103:1bbbbbbbbbbbb1bbbbbbb1bb1bbbbbbbb1bb1b1bb1bbbbb11bbbbbbbbbbbbbbb
-- 104:11bbbbbb111bbbbbbbbbbbbbb1bbbbbbbbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbb
-- 105:bbbbb111bbbbb111bbb1bbbbbbb1b1bbbbbb1b1bbbbbbbbbbbbbb1bbbbbbbbbb
-- 106:bbbbbb1bb11bbbbbb1bbbbbbbb1bbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 107:bbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbb1bbbbbb
-- 109:3333333a3333333a3333333a3333333333333333333333333333333333333333
-- 110:abbbbbbbabbbbbbbabbbbbbbaabbbbbb77333333733333337333333373333333
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
-- 000:555500005550888855088888508ddddd50ddd00050dd044450d04ddd50d04ddd
-- 001:000055558888055588888055ddddd805000ddd054440dd05dddd0d05dddd0d05
-- 002:5555555555555555555005555555055550000555504400055000ddd055550004
-- 003:5555555555555555555555555555555555555555555555550005555544400005
-- 004:5555555555555555555555555555555555555555555555555555555555000555
-- 005:5555555555555555555555555555555555555555555555555555555555555555
-- 006:5555555555555555555555555555555555555555555555555555555555555555
-- 007:555000055550a7705500a77750a00ab7507a07ab507ab7ab5007abba0a077a33
-- 008:005555557a050055ba007705ab077a05a7b7a055ab7a77a037a777a0aab77a05
-- 009:5000055050a7705050a7770b000abb7a0a07aaba0ab7aaba07abbba30077a33a
-- 010:05555555a0500555a0077055b077a0557b7a0555b7a77a057a777a05ab77a055
-- 011:5555555555555555555555555555555555555555555555555555555555555555
-- 012:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 013:55555555555555505555500155550111555011115550111155011bb15501bbbb
-- 014:500000050111bbb0111bbbbb11bbb5bb1bbbc5bb1bbbbcc1bbbbbb51bbbbbbbb
-- 015:5555555555555555b0055555bbb05555bbbb05551bbb0555111bb0551111b055
-- 016:50d04ddd50d0488850d0488850d0488850d04ddd50d04ddd50d04ddd50d04ddd
-- 017:dddd0d05888d0d05888d0d05888d0d05dddd0d05dd770d05dd470d05ddd40d05
-- 018:5555555055555555555555555555555555555555555555555555555555555555
-- 019:000dddd055500004555555505555555555555555555555555555555555555555
-- 020:0073305540733005007330405500000d550d0550550d0555550d0555550d0555
-- 021:555555555555555500055555ddd00005000444405550000d5555555055555555
-- 022:5555555555555555550055555505555500055555ddd000550004405555500055
-- 023:07ab73a350ab7ba3503abb3b5003a33a0a333aba50aa3bba550333b355500333
-- 024:3b77aba0b77aba70ba77ab7037bab705b7ba3a05b333a30533aa3b703a33b005
-- 025:0ab73a330ab7ba3b03abb3bb003a33a30333abab0aa3bbab50333b3355000333
-- 026:b77aba0577aba705a77ab7057bab70557ba3a055333a30553aa3b7053a33b005
-- 027:555555005555504455550a4255504ccc55033333550377775550377755550333
-- 028:00555555420555552aa055552cc2055533333055777730557773055533305555
-- 029:5011b11b50b1111b50b111bb50b1115b50b11ccb50bb1bbb550b11bb550bbbbb
-- 030:bbbbbbbbbbbbbbbbbbbbbbb1bbbbbbb1bbbbbb11bbbbb1bbbbbbbbbbbbbbbbbb
-- 031:b111bb05bbb1bb05bcb1bb05c5bbbb05bbbbbb05bbbbbb051bbbb05511bbb055
-- 032:50d04ddd50d04ddd50d04ddd50d04ddd50d04ddd50d04ddd50d04ddd50d04ddd
-- 033:dddd0d05dddd0d05dddd0d05dddd0d05dddd0d05dddd0d05dddd0d05dddd0d05
-- 034:5555555555555555555555555555555555555555555555555555555555555555
-- 035:5555555555555555555555555555555555555555555555555555555555555555
-- 036:5555555555555555555555555555555555555555555555555555555555555555
-- 037:5555555555555555555555555555555555555555555555555555555555555555
-- 038:5555555555555555555555555555555555555555555555555555555555555555
-- 039:5555555555555555555555555555555555555555555555555555555555555555
-- 040:5555555555555555555555555555555555555555555555555555555555555555
-- 041:55555555555555005555504455500a4255033333550377775550377755550333
-- 042:5555555500555555420555552aa0055533333055777730557773055533305555
-- 043:5555555555555555555555505555555055555555555555505550000955099999
-- 044:5055555509055555970055559779055509739055097079059777790579770705
-- 045:5550bbbb5550bbb155550bbb5555500b55555550555555555555555555555555
-- 046:11bbbbb1111bbb1111bbb111bbbbbbbb0bbbbbb0500cc005550cc055550cc055
-- 047:11bb055511bb05551bb05555b005555505555555555555555555555555555555
-- 048:5555555555555555555555555555555555555555555555555555555555555555
-- 049:5555555555555555555555555555555555555555555555555555555555555555
-- 050:5555555555555555555555555555555555555555555555555555555555555555
-- 051:5555555555555555555555555555555555555555555555555555555555555555
-- 052:5555555555555555555555555555555555555555555555555555555555555555
-- 053:5555555555555555555555555555555555555555555555555555555555555555
-- 054:5555555555555555555555555555555555555555555555555555555555555555
-- 055:5555555555555555555555555555555555555555555555555555555555555555
-- 056:5555555555555555555555555555555555555555555555555555555555555555
-- 057:5555555555555555555555005550004455033333550377775550377755550333
-- 058:5555555555555555005555554200055533333055777730557773055533305555
-- 059:5097979709093797030737775050033055555000555505555550500055550555
-- 060:7790070577930705773307350000037005055005505555550055555555055555
-- 061:5555555555555555555555555555555055555550555555505555555055555550
-- 062:550cc055550cc055050cc050300cc00333333333373773733737737337377373
-- 063:5555555555555555555555550555555505555555055555550555555505555555
-- 064:5555555555555555555555555555555555555555555555555555555555555555
-- 065:5555555555555555555555555555555555555555555555555555555555555555
-- 066:5555555555555555555555555555555555555555555555555555555555555555
-- 067:5555555555555555555555555555555555555555555555555555555555555555
-- 068:5555555555555555555555555555555555555555555555555555555555555555
-- 069:5555555555555555555555555555555555555555555555555555555555555555
-- 070:5555555555555555555555555555555555555555555555555555555555555555
-- 071:5555555555555555555555555555555555555555555555555555555555555555
-- 072:5555555555555555555555555555555555555555555555555555555555555555
-- 073:5555555555555555555555555550000055033333550377775550377755550333
-- 074:5555555555555555555555550000055533333055777730557773055533305555
-- 075:000000000cc5555c0c9955c90c9c95ce0c9e9c9e0c9eeeee0c9eeeee0c9eeeee
-- 076:00000000cccccccc99999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 077:00000000c5cccc90c5999c90c55cec90e9ccec90eeeeec90eeeeec90eeeeec90
-- 078:5555555555555555555500055550733055077370507337305073333007333330
-- 079:5555555555555555555055555507055550737055507333050737333007333330
-- 080:5555555555555555555555555555555555555555555555555555555555555555
-- 081:5555555555555555555555555555555555555555555555555555555555555555
-- 082:5555555555555555555555555555555555555555555555555555555555555555
-- 083:5555555555555555555555555555555555555555555555555555555555555555
-- 084:5555555555555555555555555555555555555555555555555555555555555555
-- 085:5555555555555555555555555555555555555555555555555555555555555555
-- 086:5555555555555555555555555555555555555555555555555555555555555555
-- 087:5555555555555555555555555555555555555555555555555555555555555555
-- 088:5555555555555555555555555555555555555555555555555555555555555555
-- 089:5555555555555555555555555555555555555555555555555555555555555555
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:0c9eeeee0c9eeeee0c9eeeee0c9eeeee0c9eeeee0c9eeeee0c9eeeee0c9eeeee
-- 092:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 093:eeeeec90eeeeec90eeeeec90eeeeec90eeeeec90eeeeec90eeeeec90eeeeec90
-- 094:5555555555555500555500735550773355073333507333335073373750737333
-- 095:5555555500055555337005553733305537733305733333053333333033333330
-- 096:5555555555555555555555555555555555555555555555555555555555555555
-- 097:5555555555555555555555555555555555555555555555555555555555555555
-- 098:5555555555555555555555555555555555555555555555555555555555555555
-- 099:5555555555555555555555555555555555555555555555555555555555555555
-- 100:5555555555555555555555555555555555555555555555555555555555555555
-- 101:5555555555555555555555555555555555555555555555555555555555555555
-- 102:5555555555555555555555555555555555555555555555555555555555555555
-- 103:5555555555555555555555555555555555555555555555555555555555555555
-- 104:5555555555555555555555555555555555555555555555555555555555555555
-- 105:5555555555555555555555555555555555555555555555555555555555555555
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:0c99eeee05559eee0ccceeee0c9999990c9000000c9055550c9055550c905555
-- 108:eeeeeeeeeeeeeeeeeeeeeeee9999999900000000555555555555555555555555
-- 109:eeeeec90eeeccc90eec99c9099900c9000050c9055550c9055550c9055550c90
-- 110:5555555555555555555555505555550755550073555077075507307350733333
-- 111:5555555555555555005555553305555533055555333055553333055533330555
-- 112:5555555555555555555555555555555555555555555555555555555555555555
-- 113:5555555555555555555555555555555555555555555555555555555555555555
-- 114:5555555555555555555555555555555555555555555555555555555555555555
-- 115:5555555555555555555555555555555555555555555555555555555555555555
-- 116:5555555555555555555555555555555555555555555555555555555555555555
-- 117:5555555555555555555555555555555555555555555555555555555555555555
-- 118:5555555555555555555555555555555555555555555555555555555555555555
-- 119:5555555555555555555555555555555555555555555555555555555555555555
-- 120:5555555555555555555555555555555555555555555555555555555555555555
-- 121:5555555555555555555555555555555555555555555555555555555555555555
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:5555555555555555555555555555555555555555555555555555555555555555
-- 125:5555555555555555555555555555555555555555555555555555555555555555
-- 126:5073333350700033500777330773333307333333073333775073373355073733
-- 127:3333305533333305337333303733330537333305333333053333305533333055
-- 128:5555555555555555555555555555555555555555555555555555555555555555
-- 129:5555555555555555555555555555555555555555555555555555555555555555
-- 130:5555555555555555555555555555555555555555555555555555555555555555
-- 131:5555555555555555555555555555555555555555555555555555555555555555
-- 132:5555555555555555555555555555555555555555555555555555555555555555
-- 133:5555555555555555555555555555555555555555555555555555555555555555
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
-- 170:55555000555504dd55504ddd555e4ddd555ee4dd555500005550f0555550ff05
-- 171:00055555dd405555ddd40555ddd4e555dd4ee55500005555550f0555550ff055
-- 172:55555000555504dd55504ddd55504ddd555e04dd555ee00055550f0555550ff0
-- 173:00055555dd405555ddd40555ddd40555dd40e555000ee55550f0555550ff0555
-- 174:55555000555504dd55504ddd555e4ddd555ee4dd55555000555550f0555550ff
-- 175:00055555dd405555ddd40555ddd4e555dd4ee555000555550f0555550ff05555
-- 176:0430555004305550040305500403055004030550040305500403055004030550
-- 177:7050705570507055705070557050705570507055705070557050705570507055
-- 178:5507050755070507550705075507050755070507550705075507050755070507
-- 179:0555034005550340055030400550304005503040055030400550304005503040
-- 180:f050f070f0500003f05ccccc05000000050ff070050ff070050ff070050ff070
-- 181:ffffffff00000000cccccccc00000000ffffffffffffffffffffffffffffffff
-- 182:070f050f0000050fccccc50f00000050070ff050070ff050070ff050070ff050
-- 183:5555555555555555555555555555555555555555555555555555555555555555
-- 184:555550005555040d555504de555504de5555500d5555500055550f055550ff05
-- 185:00055555dd405555edd05555edd05555dd4055550005555550f0555550ff0555
-- 186:55555000555504dd55504ddd55504ddd555e04dd555e000055550f0555555555
-- 187:00055555dd405555ddd40555ddd4e555dd40e5550005555550f0555550f05555
-- 188:55555000555504dd55504ddd55504ddd555e04dd555e500055550f0555550f05
-- 189:00055555dd405555ddd40555ddd40555dd40e5550005e55550f0555550f05555
-- 190:55555000555504dd55504ddd555e4ddd555e04dd5555500055550f0555550f05
-- 191:00055555dd405555ddd40555ddd40555dd40e5550000e55550f0555555555555
-- 192:040305500403055004003050040030500400300c040030500405555504055555
-- 193:70507055705070557050705570007055cccccc05000000555555555555555555
-- 194:5507050755070507550705075507000750cccccc550000005555555555555555
-- 195:05503040055030400503004005030040c0030040050300405555504055555040
-- 196:050ff070050ff070050ff070050ff070050ff070050ff070050fffff050fffff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:070ff050070ff050070ff050070ff050070ff050070ff050fffff050fffff050
-- 199:5555555555555555555555555555555555555555555555555555555555555555
-- 200:55e55000555e04dd55504ddd55504ddd555504dd5555500055550f0555555005
-- 201:00055e55dd40e555ddd40555ddd40555ddd055550005555550f0555550055555
-- 202:55555000555504dd55504ddd55504ddd555e04dd555e000055550f0555555555
-- 203:00055555dd405555ddd40555ddd4e555dd40e5550005555550f0555550f05555
-- 204:55555000555504dd55504ddd55504ddd555e04dd555e500055550f0555550f05
-- 205:00055555dd405555ddd40555ddd40555dd40e5550005e55550f0555550f05555
-- 206:55555000555504dd55504ddd555e4ddd555e04dd5555500055550f0555550f05
-- 207:00055555dd405555ddd40555ddd40555dd40e5550000e55550f0555555555555
-- 208:555550005555044d555044dd555000005550ccee5550ecee5550eeee55550eee
-- 209:00055555dd405555ddd40555000000008e8e05553e3e0555eeee0555eee05555
-- 210:5500500050cc044d50c044dd50c0000000c0ccee0cc0ecee0000eeee55550eee
-- 211:00055555dd405555ddd40555000000008e8e05553e3e0555eeee0555eee05555
-- 212:555550005555044d555044dd55500000550cccee50ccecee50cceeee50000eee
-- 213:00055555dd405555ddd40555000000008e8ec0553e3ecc05eeeecc05eee00055
-- 214:555500005550cccc550ccccc50cccccc50ccccce504cdcee5504ddee5550ddee
-- 215:00005555cccc0555ccccc055cccccc058e8ecc053e3ecd05eeeed055eee00555
-- 216:555550005555044d555044dd555000005550eeee5550eeee5550eeee55550eee
-- 217:00055555dd405555ddd40555000000008e8e05553e3e0555eeee0555eee05555
-- 218:555550005555044d555044dd000000005550ccee5550ecee5550eeee55550eee
-- 219:00055555d4405555dee40555000005558e8e05553e3e0555eeee0555eee05555
-- 220:555550005555044d555040d0555000005550cccc5550eccc5550eecc55550eee
-- 221:00055555dd405555d0d0055500000555cc8e0555ce3e0555eeee0555eee05555
-- 222:5555500055550ccc5550cccc5550cccc5550cccc5550ccce5550ceed55550eee
-- 223:00055555ccc05555cccc0555cccc05558e8c05553e3c05554e4d0555eee05555
-- 224:555550005555044d555044dd555000005550ce8e5550ce3e5550eeee55550eee
-- 225:00055555dd405555ddd4055500000555e8ec0555e3ec0555eeee0555eee05555
-- 226:555550005555044d555044dd555000005550ce8e5550ce3e5550eeee55550eee
-- 227:00055555dd405555ddd4055500000555e8ec0555e3ec0555eeee0555eee05555
-- 228:555550005555044d555044dd55500000550cce8e50ccce3e50cceeee55000eee
-- 229:00055555dd405555ddd4055500000555e8ecc055e3eccc05eeeecc05eee00005
-- 230:555500005550cccc550ccccc50cccccc50ccce8e50dcde3e550ddeee5550deee
-- 231:00005555cccc0555ccccc055cccccc05e8eccc05e3edcd05eeedd055eeed0555
-- 232:555550005555044d555044dd555000005550ee8e5550ee3e5550eeee55550eee
-- 233:00055555dd405555ddd4055500000555e8ee0555e3ee0555eeee0555eee05555
-- 234:555550005555044d555044de555000005550ce8e5550ce3e5550eeee55550eee
-- 235:00055555dd405555edd4055500000555e8ec0555e3ec0555eeee0555eee05555
-- 236:555550005555044d555040d0555000005550cccc5550ccce5550ccee55550eee
-- 237:00055555dd405555d0d0055500000555e8ec0555e3ec0555eeee0555eee05555
-- 238:5555500055550ccc5550cccc555ccccc5550ccce5550ee3e5550ed4e55550eee
-- 239:00055555ccc05555cecc0555eecc0555e8ee0555e3ee0555e4de0555eee05555
-- 240:555550005555044d555044dd555000005550cccc5550cccc5550eccc55550ecc
-- 241:00055555dd405555ddd4055500000555cccc0555cccc0555ccce0555cce05555
-- 242:55555000555504405550440c5550000c5550cc0c5550cc0c5550ec0c55550ec0
-- 243:000555550d405555c0d40555c0000555c0cc05550ccc05550cce0555cce05555
-- 244:555550005555044d555044dd55500000550ccccc50cccccc50cccccc55000ccc
-- 245:00055555dd405555ddd4055500000555ccccc055cccccc05cccccc05ccc00055
-- 246:555500005550cccc550ccccc50cccccc50cdcdcd50dddddd55044d4d55500444
-- 247:00005555cccc0555ccccc055cccccc05cdcdcd05dddddd054d4d405544400555
-- 248:555550005555044d555044dd555000005550eeee5550eeee5550eeee55550eee
-- 249:00055555dd405555ddd4055500000555eeee0555eeee0555eeee0555eee05555
-- 250:555550005555044d555044dd555000005550cccc5550cccc5550eccc55550ecc
-- 251:00055555dd405555ddd4055500000555cccc0555cccc0555ccce0555cce05555
-- 252:555550005555044d555040d0555000005550cccc5550cccc5550cccc55550ccc
-- 253:00055555dd405555d0d0055500000555cccc0555cccc0555cccc0555ccc05555
-- 254:5555500055550ccc5550cccc5550cccc5550cccc5550cccc5550cccc55550ccc
-- 255:00055555ccc05555cccc0555cccc0555cccc0555cccc0555cccc0555ccc05555
-- </SPRITES>

-- <SPRITES1>
-- 000:5555555555555555555555555555555555555555555555555555555555555555
-- 001:5555555555555555555555555555555555555555555555555555555555555555
-- 002:5555555555555555555555555555555555555555555555555555555555555555
-- 003:5555555555555555555555555555555555555555555555555555555555555555
-- 004:5555555555555555555555555555555555555555555555555555555555555555
-- 005:5555555555555555555555555555555555555555555555555555555555555555
-- 006:5555555555555555555555555555555555555555555555555555555555555555
-- 007:5555555555555555555555555555555555555555555555555555555555555555
-- 008:5555555555555555555555555555555555555555555555555555555555555555
-- 009:5555555555555555555555555555555555555555555555555555555555555555
-- 010:5555555555555555555555555555555555555555555555555555555555555555
-- 011:5555555555555555555555555555555555555555555555555555555555555555
-- 012:5555ffcc5555ffcc5555ffcc5555ffcc5555ffcc5555ffcc5555ffcc555ffccc
-- 013:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 014:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 015:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 016:5555555555555555555555555555555555555555555555555555555555555555
-- 017:5555555555555555555555555555555555555555555555555555555555555555
-- 018:5555555555555555555555555555555555555555555555555555555555555555
-- 019:5555555555555555555555555555555555555555555555555555555555555555
-- 020:5555555555555555555555555555555555555555555555555555555555555555
-- 021:5555555555555555555555555555555555555555555555555555555555555555
-- 022:5555555555555555555555555555555555555555555555555555555555555555
-- 023:5555555555555555555555555555555555555555555555555555555555555555
-- 024:5555555555555555555555555555555555555555555555555555555555555555
-- 025:5555555555555555555555555555555555555555555555555555555555555555
-- 026:5555555555555555555555555555555555555555555555555555555555555555
-- 027:5555555555555555555555555555555555555555555555555555555555555555
-- 028:555ffccc555ffccc555ffccc555ffccc555ffccc555ffccc555ffccc5fffcccc
-- 029:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 030:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 031:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 032:5555555555555555555555555555555555555555555555555555555555555555
-- 033:5555555555555555555555555555555555555555555555555555555555555555
-- 034:5555555555555555555555555555555555555555555555555555555555555555
-- 035:5555555555555555555555555555555555555555555555555555555555555555
-- 036:5555555555555555555555555555555555555555555555555555555555555555
-- 037:5555555555555555555555555555555555555555555555555555555555555555
-- 038:5555555555555555555555555555555555555555555555555555555555555555
-- 039:5555555555555555555555555555555555555555555555555555555555555555
-- 040:555555555555555f5555555f5555555f55555555555555555555555555555555
-- 041:ffffffffcccccccccccccccccccccccc55555555555555555555555555555555
-- 042:ffffffffcccccccccccccccccccccccc55555555555555555555555555555555
-- 043:ffffffffcccccccccccccccccccccccc55555555555555555555555555555555
-- 044:fccccccccccccccccccccccccccccccc55555553555555575555555755555557
-- 045:cccccccccccccccccccccccccccccccc33333333777333337777733377777733
-- 046:cccccccccccccccccccccccccccccccc33333333333333333333333333333333
-- 047:cccccccccccccccccccccccccccccccc33333333333333333333333333333333
-- 048:5555555555555555555555555555555555555555555555555555555555555555
-- 049:5555555555555555555555555555555555555555555555555555555555555555
-- 050:5555555555555555555555555555555555555555555555555555555555555555
-- 051:5555555555555555555555555555555555555555555555555555555555555555
-- 052:5555555555555555555555555555555555555555555555555555555555555555
-- 053:5555555555555555555555555555555555555555555555555555555555555555
-- 054:5555555555555555555555555555555555555555555555555555555555555555
-- 055:5555555555555555555555555555555555555555555555555555555555555555
-- 056:5555555555555555555555555555555555555555555555555555555555555555
-- 057:5555555555555555555555555555555555555555555555555555555555555555
-- 058:5555555555555555555555555555555555555555555555555555555555555555
-- 059:5555555555555555555555555555555555555555555555555555555555555555
-- 060:5555555755555555555555555555555555555555555555555555555555555555
-- 061:77777773ee777773eee7e7735eeee7775eeeee775eeeeee75eeeeee75eeeeee7
-- 062:3333333333333333333333333333333373333333733333337733333377333333
-- 063:3333333333333333333333333333333333333333333333333333333333333333
-- 064:5555555555555555555555555555555555555555555555555555555555555555
-- 065:5555555555555555555555555555555555555555555555555555555555555555
-- 066:5555555555555555555555555555555555555555555555555555555555555555
-- 067:5555555555555555555555555555555555555555555555555555555555555555
-- 068:5555555555555555555555555555555555555555555555555555555555555555
-- 069:5555555555555555555555555555555555555555555555555555555555555555
-- 070:5555555555555555555555555555555555555555555555555555555555555555
-- 071:5555555555555555555555555555555555555555555555555555556655552222
-- 072:5555555555555555555555555555566255556622555662226666622222222222
-- 073:5555555555555555555555552222222522222222222222222222222222222222
-- 074:5555555555555555555555555555555525555555255555552555555525555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:5555555555555555555555555555555555555555555555555555555555555555
-- 077:5eeeeee75eeeeeee5eeeeeee5eeeeeee5eeeeeee5eeeeeee55eeeeee55eeeeee
-- 078:77333333773333337777333377773333e7777333ee777733ee777777eee77777
-- 079:3333333333333333333333333333333333333333333333333333333373733333
-- 080:555555555555555555555555a5555555b5555555555555555555555555555555
-- 081:5555555555555555555555555555555555555555555555555555555555555555
-- 082:5555555555555555555555555555555555555555555555555555555555555555
-- 083:5555555555555555555555555555555555555555555555555555555555555555
-- 084:5555555555555555555555555555555555555555555555555555555555555555
-- 085:5555555555555555555555555555555555555555555555555555555555555555
-- 086:5555555555555555555555555555555555555555555555555555555555555555
-- 087:5555555555555555555555555555625555266222552222225526622252222222
-- 088:5555e7335555e7775555e7775555ee7755555e7755555e7755555ee7555555e7
-- 089:3333332277777333777773337777777777777777777777777777777777777722
-- 090:2555555525555555555555555555555555555555555555555555555525555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:5555555555555555555555555555555555555555555555555555555555555555
-- 093:55eeeeee555eeeee555eeeee5555eeee5555eeee55555eee55555eee555555ee
-- 094:eee77777eee77777ee777777ee777777ee777777ee777777ee777777ee777777
-- 095:7777733377777733777777337777777377777777777777777777777777777777
-- 096:5555555555555555555555555555555555555555555555555555555555555555
-- 097:5555555555555555555555555555555555555555555555555555555555555555
-- 098:5555555555555555555555555555555555555555555555555555555555555555
-- 099:5555555555555555555555555555555555555555555555555555555555555555
-- 100:5555555555555555555555555555555555555555555555555555555555555555
-- 101:5555555555555555555555555555555555555555555555555555555555555555
-- 102:5555555555555555555555555555555555555555555555555555555555555555
-- 103:5522222255222225555ee777555ee777555ee775555e7775555e7775555e777f
-- 104:555555ee55555562555556625555566255556622555662225556222255622662
-- 105:7777222222222222222222222222222222222226222222262222222222222222
-- 106:2225555522255555222255552222555522227555622225556622225566222225
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:5555555555555555555555555555555555555555555555555555555555555555
-- 109:555555ee55555555555555555555555555555555555555555555555555555555
-- 110:ee777777eee77777eee777775eee77775eee777755ee777755ee7777555ee777
-- 111:7777777777777777777777777777777777777777777777777777777777777777
-- 112:555555555555555555555555555555555555555555555555555555555555555f
-- 113:55555555555555555555555555555555555555555555ffff5fffccccfccccccc
-- 114:5555555555555555555555555555555555555555ccc55555cccccc55cccccccc
-- 115:5555555555555555555555555555555555555555555555555555555555555555
-- 116:5555555555555555555555555555555555555555555555555555555555555555
-- 117:5555555555555555555555555555555555555555555555555555555555555555
-- 118:5555555555555555555555555555555555555555555555555555555555555555
-- 119:555ee7775555e7775555e7775555e7775555ee7755555e7755555ee755555ee7
-- 120:ff6226227f626622726266227762622277766222777662227777622277776222
-- 121:22222222222222222222222222222226222222ee22222ee72222ee7722eee777
-- 122:2622222226622222266222226677b225e7777555777775557777555577755555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:5555555555555555555555555555555555555555555555555555555555555555
-- 125:5555555555555555555555555555555555555555555555555555555555555555
-- 126:5555e77755555e7755555eee555555ee55555555555555555555555555555555
-- 127:777777777777777777777777e7777777ee7777775ee7777755eee7775555ee77
-- 128:5555fffc555fcccc55fccccc55fccccceecccccceeccccccee7ccccc7777cccc
-- 129:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 130:ccccccccccccccccccccccccccfffccccccffcccccccffccccccffcccccccffc
-- 131:cc555555ccc55555ccc55555cccc5555cccc5555cccc5555ccccc555ccccc555
-- 132:5555555555555555555555555555555555555555555555555555555555555555
-- 133:5555555555555555555555555555555555555555555555555555555555555555
-- 134:5555555555555555555555555555555555555555555555555555555555555555
-- 135:555555ee55555555555555555555555555555555555555555555555555555555
-- 136:77776222eee7622255ee7eee555eee77555eee77555e7777555e7772555e7722
-- 137:eee77777ee777777777772227777222277772222772222222222222222222222
-- 138:7225555522255555222555552225555522255555222555552225555522225555
-- 139:5555555555555555555555555555555555555555555555555555555555555555
-- 140:5555555555555555555555555555555555555555555555555555555555555555
-- 141:5555555555555555555555555555555555555555555555555555555555555555
-- 142:5555555555555555555555555555555555555555555555555555555555555555
-- 143:5555ee775555ee775555ee775555ee77555eee70555eee70555ee77755ee7777
-- 144:7777ccee77777ee777777e777777ee777777e7777777e777777ee777777e7777
-- 145:e77ccccc7777cccc7777cccc7777cccc7777cccc7777cccc7c7ccccccccccccc
-- 146:cccccffcccccccfcccccccfccccccccccccccccccccccccccccccccccccccccc
-- 147:ccccc555ccccc555ccccc555ccccc555cccccc33cccccc33cccccc33cccccc33
-- 148:5555555555555555555555555555555533333333333333333333333333333333
-- 149:5555555555555555555555555555555533333333333333333333333333333333
-- 150:5555555555555555555555555555555533333333333333333333333333333333
-- 151:5555555555555555555555555555555533333333333333333333333333333333
-- 152:5557772255572222555222225552222233322222333222223332222233322222
-- 153:2222222222222222222222222222222222222222222222222222222222222222
-- 154:2222555522225555222255552222555522223333222233332222333322223333
-- 155:55555555555555555555555555555555333333333333333333333333333333ff
-- 156:5555555555555555555555555555555533333333333333333333333fffffffff
-- 157:555555555555555555555555555555553333333333333333fffffffecccccccc
-- 158:555555555555555555555eee5555e77733ee7777eee77777ee777777cccccccc
-- 159:5ee777775777777777777777777777777777777777777777777777cccccccccc
-- 160:777e7777777e777c777e777c777e777777777777777777777777777777777777
-- 161:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccc
-- 162:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 163:cccccc33ccccc333ccccc333ccccc333ccccc333ccccc333ccccc333cccc3333
-- 164:3333333333333333333333333333333333333333333333333333333333333333
-- 165:3333333333333333333333333333333333333333333333333333333333333333
-- 166:3333333333333333333333333333333333333333333333333333333333333333
-- 167:3333333333333333333333333333333333333333333333333333333333333333
-- 168:3333222233332222333322223333222233332222333322233332273333333733
-- 169:2222222222222222222222222222233322233333333333333333333333333333
-- 170:2222333322222333222233333373333f3373ffff337fffcc337ffccc33ffcccc
-- 171:3333ffff33fffccc3ffcccccffcccccccccccccccccccccccccccccccccccccc
-- 172:fffffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 173:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 174:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc3333cccc
-- 175:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 176:7777777777777777777777777777777777777777777777777777777777777777
-- 177:7ccccccc77cccccc777ccccc7777cccc77777ccc777777cc7777777777777777
-- 178:cccccccccccccccccccccccccccc7777c7777777777777777777777e777777ee
-- 179:cccc3333ccc33333cc333333e3333333e3333333e3333333e333333333333333
-- 180:3333333333333333333333333333333333333333333333333333333333333333
-- 181:3333333333333333333333333333333333333333333333333333333333333333
-- 182:3333333333333333333333333333333333333333333333333333333333333333
-- 183:3333333333333333333333333333333333333333333333333333333333333333
-- 184:3333373333333733333337333333373333333733333337333333373333333733
-- 185:33333333333733333337333f333733ff33373ffc3337ffcc333ffccc337fcccc
-- 186:fffcccccffccccccfccccccccccccccccccccccccccccccccccccccccccccccc
-- 187:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3
-- 188:ccccccccccccccccccccccc3ccccc333cccc3333cc333333c333333333333333
-- 189:cccc3333c3333333333333333333333333333333333333333333333333333333
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
-- 200:333337333333373333333733333337333333777f3333773f3333773f3333733f
-- 201:33ffcccc3ffccccc3ffcccccffccccccfcccccccfcccccccfcccccccfccccccc
-- 202:ccccccccccccccccccccccccccccccccccccccccccccccc3cccccc33cccccc33
-- 203:cccc3c33cc333333c33333333333333333333333333333333333333333333333
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
-- 216:3333773f333373ffbbb773ffbb7773ffb77333ff37733ffc37333ffc373fffcc
-- 217:fcccccccccccccccccccccccccccccccccccccccccccccccccccccc3ccccccc3
-- 218:cccccc33ccc33333cc333333cc333333c3333333333333333333333333333333
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
-- 232:333ffcccb3ffccccbbffccccbffcccccbffcccccffccccccffccccccffcccccc
-- 233:cccccc33cccccc33ccccc333cccc3333cccc3333ccc33333cc333333cc333333
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
-- 247:bbbbbbbbbbbbbbbfbbbb1bbfb1bbbbffbbbbbbffbbbbbbffbbbbbffcbbbbbffc
-- 248:ffccccccfcccccccfccccccccccccccccccccccccccccccccccccccccccccccc
-- 249:cc333333cc333333c3333333c3333333c3333333c3333333cc333333cc333333
-- 250:3333333333333333333333333333333333333333333333333333333333333333
-- 251:3333333333333333333333333333333333333333333333333333333333333333
-- 252:3333333333333333333333333333333333333333333333333333333333333333
-- 253:3333333333333333333333333333333333333333333333333333333333333333
-- 254:3333333333333333333333333333333333333333333333333333333333333333
-- 255:3333333333333333333333333333333333333333333333333333333333333333
-- </SPRITES1>

-- <MAP>
-- 016:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646464646464646464646464646464646464646464646460f2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646464646464646464646464646464646464646464646460f2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e46464646464646464646464646464646464646464646464646462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d1d1d1d2f46464646460d1d1d1d1d1d1d1d1d1d1d1d1d1d2d4646464646462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646464646464646462e000000000000000000000000002e4646464646462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646091929394646462e000000000000000000000000002e4646464607462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646460a1a2a3a4677772e00000000000000000d1d1d2d002e4646464646462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646460b1b2b3b4677772e00000000000000000e46370e002e4646171717462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646464646464677772e00000000000000000e46460e002e4646464646462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646464646464677772e00000000000000000e07460e002e4646464646462e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646464646464646462e00000000000000000e46460e002e4646464677772e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:0000000000000000000000000000000000000000000000000000000000000d1d1d1d1d1d1d1d1d1d2f461717174646464646462e00000000000000000e46460e002e4646464677772e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:0000000000000000000000000000000000000000000000000000000000000e37777777774646464646464646464646464646460f1f1f1f1f1f1f1f1f2f77770f1f2f464646460d1f2f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:0000000000000000000000000000000000000000000000000000000000000e464646464646cadaea4646464646464646464646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:0000000000000000000000000000000000000000000000000000000000000e464646464646cbdbdbdddddddddddd4646464646074646464608080808084646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:0000000000000000000000000000000000000000000000000000000000000e462727272746cbdbeb4646464646464646464646464646464646467746464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:0000000000000000000000000000000000000000000000000000000000000e464646464646ccdbec4646464646464657464646464646464646464677464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:0000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f2d46ce46464646464746464646464646464646464646464646464646464646460d1f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000000000000000000000000000000000000000000000000000000000000000000000002e46ce46464646464646465746464646464646464646464646464646464646460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:0000000000000000000000000000000000000000000000000000000000000000000000002e46ce46460746464646464646464646464646464646464646464646464646460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:0000000000000000000000000000000000000000000000000000000000000000000000002e46ce46464646464646464646464646464646464646465746574627272727460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:0000000000000000000000000000000000000000000d1d1d1d1d1d1d1d1d2d00000000002ecdeedded4646464646464646464646091929394646464646464646464646460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:00000000000000000000000000000000000d1f1f1f2f46464646464646460e00000000002ece7777ce46464646464646464646460a1a2a3a46460d1f1f1f1f1f1f1f1f1f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:000000000000000000000000000000000d2f4646464646464646464646460e00000000002ece7777ce46464646464646464646460b1b2b3b46460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000d2f464646464607460746074607460e00000000002ecfeeddef46464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000000000000000000000d2f46464646464646464646374646460e00000000002e46ce464646464646464646464646464646464646460e000d1d1d1d1d1d1d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000d2f4646464646464646464646464646460e00000000002e46ce464646464646774646464646464646464646460e002e4646464646462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000000000000000000e464646464746464646460919293946460e00000000002e46ce464646774646464677464646464646464646460f1f2f4646464646462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000e465746464646464677770a1a2a3a46460e00000000002e07ce074646464646464646464646464646464646464646464646464746462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:000000000000000000000000000e464646464646464677770b1b2b3b46460e00000000002e46ce464646464677464646464646462727272746464646464646464646462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:000000000000000000000000000e464646464646464646464646464646460e00000000002e46ce171717464646464646464657464646464646460d1d2d4646463746462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:000000000000000000000000000e464646464646464646464646464646460e00000000002e46ce464646464646464646464646464646464646460e000e4646464646462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000e464646464646464646464646464646460e00000000002e46ce4646464646460d1d1d1d1d1d2d4646464646460e000f1f1f1f1f1f1f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000e464646464646464646464646464646460e00000000002e46eedddddddded460e46464646462e4646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:000000000000000000000000000e464646464646464646464646464646460e00000000002e46ce09192939ce460e46464646462e4646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:000000000000000000000000000e464646460d1d1d1d1d1d2d46464646460e00000000002e46ce0a1a2a3ace460e46464646462e4646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:000000000000000000000000000e464646070e00000000002e46464646460e00000000002e46ce771a1a3ace460e46074607462e4646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:000000000000000000000000000e464646460e00000000002e46464646460e00000000002e46ce092a1a3ace460e46463746462e4646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:000000000000000000000000000e464607460e00000d1f1f2f46464646460e00000000002e46ce0a1a2a3ace467777770d1d1d2f4646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:000000000000000000000000000e464646460e00000e46464646464646460e00000000002e46ce0b1b2b07ce467777772e7777464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:000000000000000000000000000e464646070f1f1f2f46574646464646460f1f1f1f1f1f2f46eeddddddddef460e77772e4646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 058:000000000000000000000000000e464646464646464646464646464646464646464646464646464646464646460f1f1f2f4646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:000000000000000000000000000e46464646464646464646464646464646464646464646464646464646464646464677774646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:000000000000000000000000000e46464646464646464646464646464646464646464646464646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:000000000000000000000000000f2d464646464646464646464646464646464646464646464646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:00000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:0000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:000000000000000000000000000000000f2d464677464646464646464646464646464646574646464646464646464677464646464646073746460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:00000000000000000000000000000000000f1f1f1f2d46464646464646460d1d1d1d1d1d2e4646464646464646464646774646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:0000000000000000000000000000000000000000002e46464646464646460e00000000002e4646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:0000000000000000000000000000000000000000002e46464646464646460f2d000000002e4646464646464646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:0000000000000000000000000000000000000000002e4646464646464677770f2d0000002e4646464646464646464646464646460d1f1f1f1f1f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 069:0000000000000000000000000000000000000000002e464646464646467777370f2d00002e4646464646464646464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:0000000000000000000000000000000000000000002e46464646464646464677770f1f1f2f4646464646464646464646464646460f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:0000000000000000000000000000000000000000002e464646464646464646777746464646464646464646464646464646464646464646464646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:0000000000000000000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646467777464657464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:000000000000000000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646460919293946464646460746462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:00000000000000000000000000000000000000000000000f2d464646464646464646464646464646465746464646464646464646272727274646464646460a1a2a3a46464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000000000000000000000000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646464646464646460b1b2b3b46464646474646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:000000000000000000000000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 077:00000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1d1d1d2d464646464646464646464646464646460d1d2d464646460d1d1d2d4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 078:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000e464646460e00002e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 079:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000e464646460e00002e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 080:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646460919293946464646460e000e464646460e00002e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 081:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646460a1a2a3a46464646460e000e464646460f1f1f2f4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 082:000000000000000000000000000000000000000000000000000000000000000000000000000000000e461717174646460b1b2b3b46464646460e000e46464646777746464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 083:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000e46464646777777774646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 084:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000e46464646464677774646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000e464646460d1d1d2d4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000e464646460e00000e4646465746462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000f1f1f1f1f2f00000e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e0000000000000000000e4646463746462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e0000000000000000000e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 090:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646272727274646464646460e0000000000000000000e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 091:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e0000000000000000000f1f1f1f1f1f1f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646463746464646464646460e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646074607460e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:000000000000000000000000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 005:0000ffffffffffff0000ffffffffffff
-- 006:024689abcddeffffffeedcba99876420
-- </WAVES>

-- <SFX>
-- 001:d300e300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300600000000000
-- 016:d303e302f301f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300500000000000
-- 017:a007600620050004000300010000000d000b00085008a008f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000b60000000000
-- 018:05006505a500f500f5006500b505f500f500c500e505f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c72000000000
-- 019:05096500a500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c72000000000
-- 020:0500650a9508f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c62000000000
-- 021:660d960da60dc60da60f86006602460336041605060606060606f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600a17000000000
-- 022:0107010701070107110711071107110621052104210331033102410141015100510f610e610e710d710c810b810b910a9109a109b108c108e108f108b29000000000
-- 023:6300d300c300e300c300e300d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300672000000000
-- 024:1407240644046400a40de40af408f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400b79000000000
-- 025:42098209a209e209f200f200320b720bc20be20bf200f200120d620da20de20df200f200220f520f920fe20ff200f200020032007200e200f200f200c12000000000
-- 026:040704070406040604050405040514041404140424032403340244014401540f640f740e840d940da40cb40cc40bd40ad409f408f400f400f400f400402000000000
-- 048:01000100210041006100a100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100200000000000
-- 049:040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400401000000000
-- 050:80007000700070007000800090009000a000b000d000e000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000300000000000
-- 051:b10041004100410051006100710081009100a100a100b100c100d100d100d100e100e100f100f100f100f100f100f100f100f100f100f100f100f100202000000000
-- 056:23008300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300400000000000
-- 057:23008300a300c300d300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300600000000000
-- 058:4300a301b301b302c302c302c303c303d304d304e305e305f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300600000000000
-- </SFX>

-- <PATTERNS>
-- 000:400807100811b00807100811400807100811b00807100811400807100811b00807100811400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801400807100801b00807100801
-- 001:00000080088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000060088b00000040088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000040088b60088b80088b00000000000040088b00000000000000000000000040088b00000000000060088b00000000000000000000000040088b00000000000040088b00000000000000000000000070088b00000000000040088bd0088900000050088b
-- 002:002c110fc911800817100811b00817d00817b00817100811400817100811000000000000100811000000400819100811000000000000e00817d00817e00817100811b00817100811000000000000000000000000000000000000900817800817900817100811800817100811b00817d00817b00817100811800817100811400817e00815100811000811600817100811800817100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:002c110cf91140081b100811e00819d00819e0081910081180081910081100000000000080081b10081140081b100811000000000000800819600819800819100811900819100811000000000000000000000000000000000000e00819d00819b0081910081140081b100811e00819b00819d00819100811e00819100811d00819b00819100811000811e00819100811b00819100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:6ff925100000dff9256339256ff927d339258ff927633927100000833927dff925100000bff927d33925aff927b339276ff927a33927dff9256339276ff925d33925dff9256339256ff927d339258ff927633927100000833927dff925100000bff927d33925dff927b33927aff927d339271ff100a339276ff927100000100000633927000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:600835000831600837000831d00835000831b00835000831000831000000f00835000831b00835000831a00835000831b00835000831d00835000831600835000831600837000831b00835000831d00835000831000831000000600837000831600835000831600837000831b00835000831d00835000831600837000831800837000831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:00000000000040089d00000000000000000000000000000090089d00000000000000000000000000000040089d00000090089d0000008008ad00000000000000000060089d00000000000000000000000000000090089d00000000000000000000000000000090089d00000090089d00000090089d0000009008ad000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:5817000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f4100
-- </TRACKS>

-- <FLAGS>
-- 000:00003000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101000000000000000001010001000000000000000000000000010101000000000000000000000000000101000101010101000000000000000000010100000000010000000000000000000000000001010000010000000000000303030000000000000000000000000003000300000000000000000000000000030303000000000000000000000000000
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
-- 000:00000074b72ea858a82936403b5dc9ff0006ff79c2566c87f4f4f46d40144cda85466d1ded820e41a6f6ffe5b4ffe761
-- </PALETTE>

-- <PALETTE1>
-- 000:00000074b72ea858a82936403b5dc900fff9ff79c2566c87f4f4f42571794cda85466d1ded820d41a6f6ffe5b4ffe761
-- </PALETTE1>

