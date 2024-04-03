-- title:   Don't Get Wet
-- author:  Bitterly Indifferent Games
-- desc:    A playground water-balloon fight for 2-4 players.
-- site:    github.com/cdwfs/wbad
-- license: Creative Commons Zero v1.0 Universal
-- version: 0.8
-- script:  lua

------ GLOBALS

function vardump(value,depth,key)
 local line_prefix=""
 local spaces=""
 if key~=nil then
  line_prefix="["..key.."] = "
 end
 if depth==nil then
  depth=0
 else
  depth=depth+1
  for i=1,depth do
   spaces=spaces.." "
  end
 end
 local t=type(value)
 if t=="table" then
  local mtable=getmetatable(value)
  if mtable then
   trace(spaces.."(metatable) ")
   value=mtable
  else
   trace(spaces..line_prefix.."(table) ")
  end
  for k,v in pairs(value) do
   vardump(v,depth,k)
  end
 elseif t=="function" then
  trace(spaces..line_prefix..
         "(function)")
 elseif t=="thread"
     or t=="userdata"
     or value==nil then
  trace(spaces..tostring(value))
 else
  trace(spaces..line_prefix..
         "("..t..") "..
         tostring(value))
 end
end

-- constants
K_MAX_ENERGY=100
K_ENERGY_HIT=25
K_ENERGY_SPLASH=10
K_ENERGY_WALK=0.02 -- drain per frame
K_ENERGY_RUN=0.1 -- drain per frame
K_ENERGY_WARNING=0.3*K_MAX_ENERGY
K_MAX_RUN_SPEED=1.0
K_MAX_WALK_SPEED=0.6
K_MAX_WINDUP_SPEED=0.4
K_MAX_AMMO=5
K_MAX_PING_RADIUS=600
K_REFILL_COOLDOWN=60*10
K_HIT_COOLDOWN=120
K_HISTORY_MAX=10
K_GRAVITY=0.04
K_MAX_WINDUP=60
K_MIN_THROW=20
K_MAX_THROW=70
K_BALLOON_RADIUS=2
K_SPLASH_DIST=14
K_SCREEN_W=240
K_SCREEN_H=136
K_SUDDEN_DEATH_START=60*60*3
K_CHAN_NOISE=2
K_CHAN_SFX=3
-- palette color indices
TEAM_COLORS={6,12,13,10}
TEAM_COLORS2={2,9,4,11}
TEAM_NAMES={"Pink","Orange","Blue","Green"}
C_BLACK=0
C_DARKGREY=3
C_DARKBLUE=4
C_RED=5
C_TRANSPARENT=5 -- by default
C_LIGHTGREY=7
C_WHITE=8
C_BROWN=9
C_DARKGREEN=11
C_ORANGE=12
C_LIGHTBLUE=13
C_TAN=14
C_YELLOW=15
-- sounds
SFX_SHORT_POP=1
SFX_SPRINKLE=2
SFX_MENU_CONFIRM=18
SFX_MENU_MOVE=19
SFX_MENU_CANCEL=20
SFX_WINDUP=21
SFX_THROW=22
SFX_BALLOONPOP=23
SFX_PLAYERHIT=24
SFX_REFILL=25
SFX_ELIMINATED=26
SFX_SUDDEN_DEATH=27
-- music tracks
MUS_MENU=0
MUS_COMBAT=1
MUS_SUDDEN_DEATH=2
MUS_VICTORY=3
-- tile ids
TID_BTN0=228
TID_BTN1=229
TID_BTN2=230
TID_BTN3=231
TID_BTN4=232
TID_BTN5=233
TID_BTN6=234
TID_BTN7=235
TID_GRASS0=100
TID_GRASS_POOL={64,65,66,67,80,81,82,83,96,97,98,99}
TID_WATER0=51
TID_WATER_POOL={32,33,34,48,49,50}
TID_SAND0=68
TID_SAND_POOL={37,38,53,54,69,70}
TID_GRASS_NOMOVE=2
TID_GRASS_NOBALLOON=3
TID_GRAVEL_NOMOVE=4
TID_GRAVEL_NOBALLOON=5
TID_SAND_NOMOVE=6
TID_SAND_NOBALLOON=7
TID_SPAWN_TREE=112
TID_SPAWN_MBARS=113
TID_SPAWN_SWING=114
TID_SPAWN_REFILL=115
TID_SPAWN_PLAYER=116
TID_SPAWN_ELEPHANT=117
TID_SPAWN_XXX=118
TID_SPAWN_BUSH=119
TID_SPAWN_SIGN=128
TID_SPAWN_SEESAW=129
TID_SPAWN_ROCK1=132
TID_SPAWN_ROCK2=133
TID_SPAWN_TOILET=134
TID_SIGN1=10
TID_SIGN2=12
TID_SIGN3=14
-- sprite ids
SID_PLAYER=288
SID_REFILL=283
SID_REFILL_EMPTY={297,313,329}
SID_BUSH=263
SID_ELEPHANT=299
SID_TREE=269
SID_SWING=416
SID_MBARS=420
SID_SIGN=331
SID_SEESAW=258
SID_TOILET=256
-- sprite flags
SF_BLOCK_PLAYER=0
SF_BLOCK_BALLOON=1
SF_BLOCK_RUNNING=2
SF_BLOCK_SHADOWS=3
SF_SHALLOW_WATER=4
SF_SAND=5
SF_GRAVEL=6 -- HACK, only used for spawn-tile replacement heuristic
SF_HAZARD=7

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
tic80tri=tri
tri=function(x1,y1,x2,y2,x3,y3,color)
 tic80tri(x1-camera_x,y1-camera_y,
          x2-camera_x,y2-camera_y,
          x3-camera_x,y3-camera_y,
          color)
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
-- push/pop clip rectangle
-- (plus a clip() overload to store it,
-- since it's not memory-mapped)
clip_stack={}
tic80clip=clip
clip=function(x,y,w,h)
 clip_stack={}
 push_clip(x,y,w,h)
end
function push_clip(x,y,w,h)
 x=x or 0
 y=y or 0
 w=w or K_SCREEN_W
 h=h or K_SCREEN_H
 local current=clip_stack[#clip_stack]
    or {0,0,K_SCREEN_W,K_SCREEN_H}
 local cx1,cy1=current[1]+current[3],
               current[2]+current[4]
 local x1,y1=x+w,y+h
 x=max(x, current[1])
 y=max(y, current[2])
 x1=min(cx1,x1)
 y1=min(cy1,y1)
 w=x1-x
 h=y1-y
 add(clip_stack,{x,y,w,h})
 tic80clip(x,y,w,h)
end
function pop_clip()
 table.remove(clip_stack)
 local next=clip_stack[#clip_stack] or {}
 tic80clip(table.unpack(next))
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

function mod1n(x,n)
 return ((x-1)%n)+1
end

-- returns ID of button sprite
-- for a button.
-- if show_press isn't nil, show
-- the live state of the button.
-- if pid is non-nil, read that
-- player's button (1-4)
function btnspr(b,show_press,pid)
 pid=pid or 1
 local pressed=
  (show_press and btn(8*(pid-1)+b))
  and 16 or 0
 return TID_BTN0+b+pressed
end

-- returns three values:
-- track: 0-7 (255 if not playing)
-- frame: 0-15
-- row:   0-63
function music_state()
 return peek(0x13FFC),
        peek(0x13FFD),
        peek(0x13FFE)
end

-- return random element from a table
function rndt(t)
 return t[math.random(#t)]
end

-- a0,a1,b0,b1 are v2 bounds of two rects
function rects_overlap(a0,a1,b0,b1)
 return a1.x>=b0.x and a0.x<=b1.x
    and a1.y>=b0.y and a0.y<=b1.y
end

-- print with a drop-shadow
function dsprint(msg,x,y,c,cs,...)
 print(msg,x+1,y+1,cs,...)
 return print(msg,x,y,c,...)
end

-- print with a full outline
function oprint(msg,x,y,c,co,...)
 print(msg,x,y-1,co,...)
 print(msg,x,y+1,co,...)
 print(msg,x-1,y,co,...)
 print(msg,x+1,y,co,...)
 return print(msg,x,y,c,...)
end


-- palette fade
original_palette={} -- 48 RGB bytes
palbytes={}
function fade_init_palette()
 for i=0,47 do
  original_palette[i]=peek(0x3FC0+i)
 end
 for i=0,7 do
  palbytes[i]=peek(0x03FF0+i)
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
  about=about_enter,
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

mode_menu={}

function menu_enter(args)
 sync(1|2|4|32,1)
 camera(0,0)
 cls(0)
 if music_state()==255 then
  music(MUS_MENU)
 end
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  30)
 mode_menu=obj({
  update=menu_update,
  draw=menu_draw,
  leave=menu_leave,
  ignore_input=false,
  selected=0,
  drops={},
  drop_cooldown=0,
 })
 return mode_menu
end

function menu_leave(_ENV)
 clip()
end

MENU_DROP_SPAWNS={
 v2(64,22),v2(66,22),v2(68,22),v2(70,22),v2(72,22),v2(74,21),v2(76,19), -- D
 v2(80,21),v2(82,23),v2(84,23), -- o
 v2(89,22),v2(91,23),v2(93,23),v2(95,14),v2(97,23),v2(99,22), --n
 v2(101,13), -- '
 v2(82,23), -- t
 v2(117,19),v2(119,20),v2(121,22),v2(123,23),v2(125,9),v2(127,23),v2(129,21),v2(131,19), -- G
 v2(133,18),v2(135,23),v2(137,23),v2(139,18),v2(141,18),v2(143,17), -- e
 v2(145,13),v2(147,22),v2(149,22),v2(151,12), -- t
 v2(86,31),v2(88,32),v2(90,42),v2(92,42),v2(94,42),v2(96,42),v2(98,38),v2(100,36),v2(102,40), -- W
 v2(114,38),v2(116,42),v2(118,43),v2(120,43),v2(122,43),v2(124,43),v2(126,43),v2(128,38),v2(130,36), -- e
 v2(132,33),v2(134,42),v2(136,43),v2(138,43),v2(140,34),v2(142,33),
}
function menu_update(_ENV)
 -- input
 if not ignore_input then
  if btnp(0) then
   sfx(SFX_MENU_MOVE,"D-5",-1,K_CHAN_SFX)
   selected=(selected+1)%2
  elseif btnp(1) then
   sfx(SFX_MENU_MOVE,"D-5",-1,K_CHAN_SFX)
   selected=(selected+1)%2
  end
  if btnp(4) then
   sfx(SFX_MENU_CONFIRM,"D-5",-1,K_CHAN_SFX)
   ignore_input=true
   -- fade to black & advance to next mode
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     if selected==0 then
      set_next_mode("teams",{})
     elseif selected==1 then
      set_next_mode("about",{})
     end
    end,
    30)
  end
 end
 -- update water drops
 local drops2={}
 for _,d in ipairs(drops) do
  d.vel.y=d.vel.y+0.3
  d.pos=v2add(d.pos,d.vel)
  if d.pos.y<K_SCREEN_H then
   add(drops2,d)
  end
 end
 drops=drops2
 if drop_cooldown>0 then
  drop_cooldown=drop_cooldown-1
 else
  drop_cooldown=math.random(5,15)//1
  add(drops,{
   pos=v2cpy(rndt(MENU_DROP_SPAWNS)),
   vel=v2(0,0),
  })
 end
end

function menu_draw(_ENV)
 cls(C_TRANSPARENT)
 -- draw left side of screen
 map(0,0,30,1,0,0)
 -- draw top row of right screen
 map(0,1,14,16,0,8)
 -- draw right-hand fence and grass
 rect(128,80,128,56,C_DARKGREY)
 spr(464, 14*8,112, C_DARKGREY, 1,0,0, 16,3)
 -- draw water droplets
 for _,d in ipairs(drops) do
  circ(d.pos.x,d.pos.y,1,C_DARKBLUE)
  pix(d.pos.x,d.pos.y,5)
  pix(d.pos.x,d.pos.y-1,C_WHITE)
 end
 -- draw right side of screen
 spr(256, 14*8,8, C_TRANSPARENT, 1,0,0, 16,10)
 spr(400, 14*8,80, C_DARKGREY, 1,0,0, 16,4)
 -- draw foreground hand to occlude drops
 spr(464, 14*8,112, C_TRANSPARENT, 1,0,0, 2,1)
 spr(480, 14*8,120, C_TRANSPARENT, 1,0,0, 3,1)
 spr(496, 14*8,128, C_TRANSPARENT, 1,0,0, 3,1)
 -- draw logo
 spr(128, 48,4, C_TRANSPARENT, 1,0,0,
     16,5)
 -- Draw menu options
 dsprint("Play",46,89,
  selected==0 and C_WHITE or C_LIGHTGREY,
  C_BLACK,true)
 dsprint("About",46,97,
  selected==1 and C_WHITE or C_LIGHTGREY,
  C_BLACK,true)
 -- draw menu cursor
 spr(btnspr(4,1),36,88+8*selected,
  C_TRANSPARENT)
end

------ ABOUT

mode_about={}

function about_enter(args)
 sync(1|2|4|32,0)
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
 mode_about=obj({
  update=about_update,
  draw=about_draw,
  leave=about_leave,
  ignore_input=false,
  screens={"Help","About","Credits"},
  screen=1,
  scroll=0,
  scroll_max={90,0,0}, -- per screen
  move_player=create_player(1,1),
  run_player=create_player(2,2),
  throw_player=create_player(3,3),
  refill=create_refill(8,8),
  move_bounds={110,180}
 })
 local ab=mode_about
 ab.move_player.pos=v2(ab.move_bounds[1],20)
 ab.move_player.dir=v2(1,0)
 ab.move_player.anims:to("walklr")
 ab.run_player.pos=v2(ab.move_bounds[1],40)
 ab.run_player.dir=v2(1,0)
 ab.run_player.anims:to("walklr")
 ab.throw_player.pos=v2(50,50)
 ab.throw_player.anims:to("idlelr")
 return mode_about
end

function about_leave(_ENV)
 clip()
end

function about_update(_ENV)
 -- input
 if not ignore_input then
  if btn(0) then
   scroll=max(0,scroll-1)
  end
  if btn(1) then
   scroll=min(scroll_max[screen],scroll+1)
  end
  if btnp(2) then
   sfx(SFX_MENU_MOVE,"D-5",-1,K_CHAN_SFX)
   scroll,screen=0,mod1n(screen+1,#screens)
  end
  if btnp(3) then
   sfx(SFX_MENU_MOVE,"D-5",-1,K_CHAN_SFX)
   scroll,screen=0,mod1n(screen+#screens-1,#screens)
  end
  if btnp(5) then
   sfx(SFX_MENU_CANCEL,"D-5",-1,K_CHAN_SFX)
   ignore_input=true
   -- fade to black & advance to next mode
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     set_next_mode("menu",{})
    end,
    30)
  end
 end
 -- Update animations on help screen
 -- demo moving player
 move_player.pos.x=
  move_player.pos.x+
  move_player.dir.x*K_MAX_WALK_SPEED
 if move_player.dir.x<0
 and move_player.pos.x<move_bounds[1] then
  move_player.hflip=0
  move_player.dir.x=1
 elseif move_player.dir.x>0
 and move_player.pos.x>move_bounds[2] then
  move_player.hflip=1
  move_player.dir.x=-1
 end
 move_player.anims:nextv()
 -- demo running player
 if mode_frames%60==0 then
  run_player.running=not run_player.running
 end
 run_player.pos.x=
  run_player.pos.x+
  run_player.dir.x*
   (run_player.running
    and K_MAX_RUN_SPEED
     or K_MAX_WALK_SPEED)
 if run_player.dir.x<0
 and run_player.pos.x<move_bounds[1] then
  run_player.hflip=0
  run_player.dir.x=1
 elseif run_player.dir.x>0
 and run_player.pos.x>move_bounds[2] then
  run_player.hflip=1
  run_player.dir.x=-1
 end
 run_player.anims:nextv()
 -- TODO: demo throwing

 -- demo refill station
 for _,s in ipairs(refill.sparkles) do
  s:update()
 end
end

function about_draw(_ENV)
 cls(C_BLACK)
 camera()
 -- navigation controls
 local sprev=mod1n(screen+1,#screens)
 local snext=mod1n(screen+#screens-1,#screens)
 local mnext=screens[snext]
 spr(btnspr(2,1),1,1, C_TRANSPARENT)
 spr(btnspr(3,1),K_SCREEN_W-9,1, C_TRANSPARENT)
 dsprint(screens[sprev],10,2,C_WHITE,C_DARKGREY,true)
 dsprint(mnext,K_SCREEN_W-10-6*#mnext,2,C_WHITE,C_DARKGREY,true)
 spr(btnspr(0,1),1,K_SCREEN_H-9, C_TRANSPARENT)
 spr(btnspr(1,1),10,K_SCREEN_H-9, C_TRANSPARENT)
 dsprint("Scroll",19,K_SCREEN_H-8,C_WHITE,C_DARKGREY,true)
 spr(btnspr(5,1),K_SCREEN_W-34,K_SCREEN_H-9, C_TRANSPARENT)
 dsprint("Back",K_SCREEN_W-25,K_SCREEN_H-8,C_WHITE,C_DARKGREY,true)
 -- screen background
 rect(0,9,K_SCREEN_W-1,K_SCREEN_H-19,4)
 clip(0,9,K_SCREEN_W,K_SCREEN_H-19)
 camera(0,scroll)
 if screen==1 then -- HELP
  -- explain UI
  local xui0,yui0=2,10
  local w=dsprint("This bar shows your energy:",xui0,yui0+1,C_WHITE,C_BLACK)
  draw_energy_ui(xui0+w+2,yui0+2,32,5,K_MAX_ENERGY*0.75)
  dsprint("Walking, running, and getting hit",xui0,yui0+10,C_WHITE,C_BLACK)
  dsprint("by balloons consumes energy.",xui0,yui0+19,C_WHITE,C_BLACK)
  dsprint("If it runs out, you're eliminated!",xui0,yui0+28,C_WHITE,C_BLACK)
  dsprint("These dots show how many water",xui0,yui0+46,C_WHITE,C_BLACK)
  local w=dsprint("balloons you have:",xui0,yui0+55,C_WHITE,C_BLACK)
  draw_ammo_ui(xui0+w+2,yui0+58,K_MAX_AMMO,TEAM_COLORS[1])
  -- explain refill stations
  local xref0,yref0=2,yui0+73
  dsprint("Touching a tub of balloons restores",xref0,yref0+1,C_WHITE,C_BLACK)
  dsprint("both energy and water balloons.",xref0,yref0+10,C_WHITE,C_BLACK)
  local w=dsprint("The bowl takes some time to refill",xref0,yref0+19,C_WHITE,C_BLACK)
  refill.pos=v2(xref0+w+4,yref0+17)
  draw_refill(refill)
  dsprint("after use.",xref0,yref0+28,C_WHITE,C_BLACK)
  -- How to move
  local xmove0,ymove0=2,yref0+46
  dsprint("Use           to move.",xmove0,ymove0+1,C_WHITE,C_BLACK)
  local lpress=move_player.dir.x<0 and 16 or 0
  local rpress=move_player.dir.x>0 and 16 or 0
  spr(btnspr(0),xmove0+20,ymove0,C_TRANSPARENT)
  spr(btnspr(1),xmove0+30,ymove0,C_TRANSPARENT)
  spr(btnspr(2)+lpress,xmove0+40,ymove0,C_TRANSPARENT)
  spr(btnspr(3)+rpress,xmove0+50,ymove0,C_TRANSPARENT)
  move_player.pos.y=ymove0
  draw_player(move_player)
  -- How to run
  local xrun0,yrun0=2,ymove0+17
  dsprint("Hold   to run.",xrun0,yrun0+1,C_WHITE,C_BLACK)
  local press4=run_player.running and 16 or 0
  spr(btnspr(4)+press4,xrun0+25,yrun0,C_TRANSPARENT)
  dsprint("* Running consumes energy faster!",xrun0,yrun0+10,C_WHITE,C_BLACK)
  dsprint("* Not all terrain allows running!",xrun0,yrun0+19,C_WHITE,C_BLACK)
  dsprint("* You can't run while aiming a balloon!",xrun0,yrun0+28,C_WHITE,C_BLACK)
  run_player.pos.y=yrun0
  draw_player(run_player)
  -- How to throw
  local xthrow0,ythrow0=2,yrun0+46
  local w=dsprint("Hold   to aim a balloon, and",xthrow0,ythrow0+1,C_WHITE,C_BLACK)
  dsprint("release to throw.",xthrow0,ythrow0+10,C_WHITE,C_BLACK)
  spr(btnspr(5),xthrow0+25,ythrow0,C_TRANSPARENT)
  --throw_player.pos=v2(xthrow0+w+6,ythrow0+8)
  --draw_player(throw_player)
 elseif screen==2 then -- ABOUT
  local x0,y0=2,10
  dsprint("It's a beautiful summer day. You and your",x0,y0+1,C_WHITE,C_BLACK)
  dsprint("friends have the day off from school, but",x0,y0+10,C_WHITE,C_BLACK)
  dsprint("the adults are all stuck at work. Time to",x0,y0+19,C_WHITE,C_BLACK)
  dsprint("head down to Dewdrop Gardens for an epic",x0,y0+28,C_WHITE,C_BLACK)
  dsprint("water-balloon fight!",x0,y0+37,C_WHITE,C_BLACK)
  dsprint("The last dry kid wins. DON'T GET WET!",x0,y0+55,C_WHITE,C_BLACK)
 elseif screen==3 then -- CREDITS
  dsprint("Code, Music: Cort Stratton",2,10,C_WHITE,C_BLACK,true)
  dsprint("  Pixel Art: Donald Conrad",2,18,C_WHITE,C_BLACK,true)
  dsprint(" QA, Antics: Peter M.J. Gross",2,26,C_WHITE,C_BLACK,true)
  dsprint("Special Thx: Lesley, Mindy",2,34,C_WHITE,C_BLACK,true)
  dsprint("bitterlyindifferent.itch.io",40,62,C_LIGHTBLUE,C_BLACK,true)
  dsprint("    postgoodism.itch.io",40,70,C_LIGHTBLUE,C_BLACK,true)
 end
 clip()
 camera()
end

------ TEAMS

mode_team={}
K_IDLE=0
K_JOINED=1

function team_enter(args)
 sync(1|2|4|32,0)
 camera(0,0)
 vbank(1)
 poke(0x03FF8,C_BLACK) -- set overlay transparency color
 cls(C_BLACK)
 vbank(0)
 cls(C_BLACK)
 if music_state()==255 then
  music(MUS_MENU)
 end
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function() fade_black(0) end,
  30)
 mode_team=obj({
  update=team_update,
  draw=team_draw,
  leave=team_leave,
  ignore_input=false,
  state={K_JOINED,K_IDLE,K_IDLE,K_IDLE},
  players={},
  can_play=false,
  history={{},{},{},{}},
  ihistory={1,1,1,1},
  balloons={},
  btargets={},
  bsplatr=60,
 })
 local tm=mode_team
 for i=1,4 do
  local p=create_player(i,i)
  p.pos=v2(20+i*40-5,K_SCREEN_H/2)
  add(tm.players,p)
 end
 -- copy previous players if this is
 -- a rematch
 for _,pp in ipairs(args.prev_players or {}) do
  tm.state[pp.pid]=K_JOINED
  local p=tm.players[pp.pid]
  p.team=pp.team
  p.color=pp.color
  p.color2=pp.color2
  p.skinc=pp.skinc
  p.hairc=pp.hairc
  p.faceu=pp.faceu
  p.faced=pp.faced
  p.facelr=pp.facelr
  p.anims=pp.anims
  p.yerrik_dream_mode=nil
 end
 local sr=tm.bsplatr
 local sw=K_SCREEN_W/(2*sr)
 local sh=1+K_SCREEN_H/(2*sr)
 for y=0,sh do
  for x=0,sw do
   local t1=v2(x*2*sr,y*2*sr)
   local t2=v2(x*2*sr+sr,y*2*sr+sr)
   add(tm.btargets,t1)
   if t2.x-sr<K_SCREEN_W and t2.y-sr<K_SCREEN_H then
    add(tm.btargets,t2)
   end
  end
 end
 return mode_team
end

function team_leave(_ENV)
 clip()
end

function huevos(h,hi,p)
 -- seekrit character 1
 if hi>4
 and h[mod1n(hi-4,K_HISTORY_MAX)]==0
 and h[mod1n(hi-3,K_HISTORY_MAX)]==1
 and h[mod1n(hi-2,K_HISTORY_MAX)]==0
 and h[mod1n(hi-1,K_HISTORY_MAX)]==1 then
  p.facelr=478
  p.faced=p.facelr+16
  p.faceu=p.facelr+32
  p.skinc=C_TAN
  p.hairc=C_ORANGE
 end
 -- seekrit character 2
 if hi>4
 and h[mod1n(hi-4,K_HISTORY_MAX)]==0
 and h[mod1n(hi-3,K_HISTORY_MAX)]==1
 and h[mod1n(hi-2,K_HISTORY_MAX)]==1
 and h[mod1n(hi-1,K_HISTORY_MAX)]==0 then
  p.facelr=476
  p.faced=p.facelr+16
  p.faceu=p.facelr+32
  p.skinc=C_TAN
  p.hairc=C_ORANGE
 end
 -- seekrit character 3
 if hi>4
 and h[mod1n(hi-4,K_HISTORY_MAX)]==1
 and h[mod1n(hi-3,K_HISTORY_MAX)]==1
 and h[mod1n(hi-2,K_HISTORY_MAX)]==1
 and h[mod1n(hi-1,K_HISTORY_MAX)]==0 then
  p.facelr=392
  p.faced=p.facelr+16
  p.faceu=p.facelr+32
  p.skinc=C_TAN
  p.hairc=C_BROWN
 end
 -- seekrit character 3
 if hi>5
 and h[mod1n(hi-5,K_HISTORY_MAX)]==0
 and h[mod1n(hi-4,K_HISTORY_MAX)]==0
 and h[mod1n(hi-3,K_HISTORY_MAX)]==0
 and h[mod1n(hi-2,K_HISTORY_MAX)]==1
 and h[mod1n(hi-1,K_HISTORY_MAX)]==0 then
  p.facelr=368
  p.faced=p.facelr+16
  p.faceu=p.facelr+32
  p.skinc=C_TAN
  p.hairc=C_ORANGE
  p.anims=animgraph({
   idlelr={anim({372},8),"idlelr"},
   idled={anim({388},8),"idled"},
   idleu={anim({404},8),"idleu"},
   walklr={anim({370,372,374,372},8),"walklr"},
   walkd={anim({386,388,390,388},8),"walkd"},
   walku={anim({402,404,406,404},8),"walku"},
  },"idlelr")
 end
 -- dream mode
 if hi>6
 and h[mod1n(hi-5,K_HISTORY_MAX)]==0
 and h[mod1n(hi-5,K_HISTORY_MAX)]==0
 and h[mod1n(hi-4,K_HISTORY_MAX)]==1
 and h[mod1n(hi-3,K_HISTORY_MAX)]==0
 and h[mod1n(hi-2,K_HISTORY_MAX)]==1
 and h[mod1n(hi-1,K_HISTORY_MAX)]==1 then
  for _,pp in ipairs(mode_team.players) do
   pp.yerrik_dream_mode=true
  end
  sfx(SFX_SPRINKLE,"D-4",-1,2)
 end
end

function team_update(_ENV)
 -- input
 if not ignore_input then
  local pid_notes={2,9,-2,6}
  for pid,p in ipairs(players) do
   local pb0=8*(pid-1)
   -- check for P2-P4 joining/leaving
   if pid>1 and state[pid]==K_IDLE
   and btnp(pb0+4) then
    sfx(SFX_MENU_CONFIRM,"D-5",-1,K_CHAN_SFX)
    state[pid]=K_JOINED
    history[pid]={}
    ihistory[pid]=1
   elseif pid>1 and state[pid]==K_JOINED
   and btnp(pb0+5) then
    sfx(SFX_MENU_CANCEL,"D-5",-1,K_CHAN_SFX)
    state[pid]=K_IDLE
   -- joined players can change teams
   elseif state[pid]==K_JOINED then
    local h,hi=history[pid],ihistory[pid]
    if btnp(pb0+0) then
     h[mod1n(hi,K_HISTORY_MAX)]=0
     ihistory[pid]=hi+1
    elseif btnp(pb0+1) then
     h[mod1n(hi,K_HISTORY_MAX)]=1
     ihistory[pid]=hi+1
    elseif btnp(pb0+2) then
     sfx(SFX_MENU_MOVE,4*12+pid_notes[pid],-1,K_CHAN_SFX)
     p:set_team(mod1n(p.team+1,4))
    elseif btnp(pb0+3) then
     sfx(SFX_MENU_MOVE,4*12+pid_notes[pid],-1,K_CHAN_SFX)
     p:set_team(mod1n(p.team+3,4))
    elseif btnp(pb0+4) then
     -- handled above, doesn't go into history
    elseif btnp(pb0+5) then
     -- handled above, doesn't go into history
    elseif btnp(pb0+6) then
     h[mod1n(hi,K_HISTORY_MAX)]=6
     ihistory[pid]=hi+1
    elseif btnp(pb0+7) then
     huevos(h,hi,p)
     history[pid]={}
     ihistory[pid]=1
    end
   end
  end
  -- Check if we can start the game.
  -- Requires at least two teams.
  local nteams=0
  local seen_teams={false,false,false,false}
  for pid,p in ipairs(players)  do
   if state[pid]==K_JOINED then
    if not seen_teams[p.team] then
     seen_teams[p.team]=true
     nteams=nteams+1
    end
   end
  end
  can_play=nteams>1
  -- P1's (B) goes back to menu
  if btnp(5) then
   sfx(SFX_MENU_CANCEL,"D-5",-1,K_CHAN_SFX)
   ignore_input=true
   add_frame_hook(
    function(nleft,ntotal)
     fade_black((ntotal-nleft)/ntotal)
    end,
    function()
     set_next_mode("menu",{})
    end,
    30)
  elseif can_play and btnp(4) then
   -- P1's (A) enters the game
   -- if the teams are valid
   sfx(SFX_MENU_CONFIRM,"D-5",-1,K_CHAN_SFX)
   ignore_input=true
   -- clear overlay
   vbank(1)
   cls(C_BLACK)
   vbank(0)
   -- get quick list of active players
   -- to throw transition balloons from
   local ps={}
   for pid,p in ipairs(players) do
    if state[pid]==K_JOINED then
     add(ps,p)
     p.dir=v2(0,1)
     p.anims:to("idled") -- face screen
    end
   end
   -- spawn all transition balloons
   for i,targ in ipairs(btargets) do
    local p=rndt(ps)
    add(balloons,{
     pos0=v2cpy(p.pos),
     pos=v2cpy(p.pos),
     pos1=v2cpy(targ),
     t=-math.random(60)//1,
     t1=60+math.random(30)//1,
     pid=p.pid,
     team=p.team,
     pp=p.yerrik_dream_mode,
     color=p.color,
    })
   end
   -- sort transition balloons by distance from
   -- screen (t1-t), higher distances first
   table.sort(balloons,
    function(a,b)
     return a.t1-a.t>b.t1-b.t
    end)
  end
 end
 -- update transition balloons
 local balloons2={}
 for _,b in ipairs(balloons) do
  b.t=b.t+1
  if b.t>b.t1 then
   sfx(SFX_BALLOONPOP,6*12+math.random(0,4),
    -1,K_CHAN_NOISE)
   vbank(1)
   circ(b.pos.x,b.pos.y,bsplatr,
    b.pp and C_YELLOW or C_LIGHTBLUE)
   vbank(0)
  else
   add(balloons2,b)
  end
  if b.t==0 then
   music()
   sfx(SFX_THROW,3*12+math.random(7,11),
    -1,b.pid-1)
  elseif b.t>0 then
   b.pos=v2lerp(b.pos0,b.pos1,b.t/b.t1)
  end
 end
 -- after the last transition balloon
 -- has popped...
 if #balloons>0 and #balloons2==0 then
  -- make sure the overlay is totally filled
  vbank(1)
  cls(balloons[1].pp and C_YELLOW or C_LIGHTBLUE)
  vbank(0)
  local active_players={}
  for _,p in ipairs(players) do
   if state[p.pid]==K_JOINED then
    add(active_players,p)
   end
  end
  delay(
   function()
    set_next_mode("combat",{
     players=active_players,
    })
   end,20)
 end
 balloons=balloons2
end

function team_draw(_ENV)
 cls(C_DARKBLUE)
 dsprint("SELECT TEAMS",52,2,
  C_WHITE,C_BLACK,false,2)
 for pid,p in ipairs(players) do
  dsprint("P"..pid,
   p.pos.x,p.pos.y-24,
   C_WHITE,C_BLACK)
  if state[pid]==K_JOINED then
   draw_player(p)
   spr(btnspr(2,1,pid),p.pos.x-11,p.pos.y-2,C_TRANSPARENT)
   spr(btnspr(3,1,pid),p.pos.x+11,p.pos.y-2,C_TRANSPARENT)
  else
   dsprint("Join",p.pos.x-7, p.pos.y-8,
    TEAM_COLORS[mod1n(pid+mode_frames//8,#TEAM_COLORS)],
    C_BLACK,true,1,false)
   spr(btnspr(4),p.pos.x+1,p.pos.y,C_TRANSPARENT)
  end
 end
 -- navigation controls
 if can_play then
  spr(btnspr(4,1),1,K_SCREEN_H-9, C_TRANSPARENT)
  dsprint("Play",10,K_SCREEN_H-8,C_WHITE,C_DARKGREY,true)
 else
  dsprint("Invalid Teams",1,K_SCREEN_H-8,
   TEAM_COLORS[mod1n(mode_frames//10,#TEAM_COLORS)],
   C_DARKGREY,true)
 end
 spr(btnspr(5,1),K_SCREEN_W-34,K_SCREEN_H-9, C_TRANSPARENT)
 dsprint("Back",K_SCREEN_W-25,K_SCREEN_H-8,C_WHITE,C_DARKGREY,true)
 -- draw transition balloons
 for _,b in ipairs(balloons) do
  local t01=b.t/b.t1
  if t01>=0 then
   draw_balloon(b.pos.x,b.pos.y,
    lerp(K_BALLOON_RADIUS,bsplatr,t01*t01*t01*t01),b.team,
    b.t,b.t1,K_SCREEN_H/2)
  end
 end
end

------ COMBAT

mode_combat={}

function cb_enter(args)
 sync(1|2|4|32,0)
 fade_init_palette()
 camera(0,0)
 mode_combat=obj({
  update=cb_update,
  draw=cb_draw,
  leave=cb_leave,
  player_spawns={},
  players=args.players,
  balloons={},
  refills={},
  wparts={}, -- water particles
  refill_pings={},
  -- scenery entities
  obstacles={},
  dissolve={},
  end_hook=nil,
 })
 local cb=mode_combat
 -- adjust clip rects based on player count
 local player_clips={
  {  0, 0,240,136},
  {120, 0,120,136},
  {  0,68,120, 68},
  {120,68,120, 68},
 }
 if #cb.players>=2 then
  player_clips[1][3]=120
 end
 if #cb.players>=3 then
  player_clips[1][4]=68
  player_clips[2][4]=68
 end
 cb.clips=player_clips
 -- parse map and spawn entities at
 -- indicated locations
 for my=0,135 do
  for mx=0,239 do
   local tid=mget(mx,my)
   if tid==TID_GRASS0 then
    mset(mx,my,rndt(TID_GRASS_POOL))
   elseif tid==TID_WATER0 then
    mset(mx,my,rndt(TID_WATER_POOL))
   elseif tid==TID_SAND0 then
    mset(mx,my,rndt(TID_SAND_POOL))
   elseif tid==TID_SPAWN_TREE then
    add(cb.obstacles,create_tree(mx,my))
   elseif tid==TID_SPAWN_MBARS then
    add(cb.obstacles,create_mbars(mx,my))
   elseif tid==TID_SPAWN_SWING then
    add(cb.obstacles,create_swing(mx,my))
   elseif tid==TID_SPAWN_ELEPHANT then
    add(cb.obstacles,create_elephant(mx,my))
   elseif tid==TID_SPAWN_SEESAW then
    add(cb.obstacles,create_seesaw(mx,my))
   elseif tid==TID_SPAWN_TOILET then
    add(cb.obstacles,create_toilet(mx,my))
   elseif tid==TID_SPAWN_ROCK1 then
    add(cb.obstacles,create_rock(mx,my))
   elseif tid==TID_SPAWN_ROCK2 then
    add(cb.obstacles,create_rock(mx,my))
   elseif tid==TID_SPAWN_REFILL then
    add(cb.refills,create_refill(mx,my))
    mset(mx,my,rndt(TID_GRASS_POOL))
   elseif tid==TID_SPAWN_PLAYER then
    add(cb.player_spawns,v2(mx,my))
    mset(mx,my,rndt(TID_GRASS_POOL))
   elseif tid==TID_SPAWN_BUSH then
    add(cb.obstacles,create_bush(mx,my))
   elseif tid==TID_SPAWN_SIGN then
    add(cb.obstacles,create_sign(mx,my))
   end
  end
 end
 -- spawn players
 cb_spawn_players(cb)
 -- start music
 music(MUS_COMBAT,-1,-1,true,true)
 -- initialize dissolve array
 for x=1,K_SCREEN_W do
  add(cb.dissolve,0)
 end
 return cb
end

function guess_replace_tile(mx,my,block_moves)
 -- HACK: use the tile directly
 -- below the spawner to determine
 -- what tile type to replace the
 -- spawner with.
 local mtid=mget(mx,my+1)
 if fget(mtid,SF_GRAVEL) then
  return block_moves and TID_GRAVEL_NOMOVE or TID_GRAVEL_NOBALLOON
 elseif mtid==TID_SAND0
 or fget(mtid,SF_SAND) then
  return block_moves and TID_SAND_NOMOVE or TID_SAND_NOBALLOON
 end
 return block_moves and TID_GRASS_NOMOVE or TID_GRASS_NOBALLOON
end

function create_player(pid,team)
 local p=obj({
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
  set_team=function(self,new_team)
   self.team=new_team
   self.color=TEAM_COLORS[new_team]
   self.color2=TEAM_COLORS2[new_team]
  end,
  reset=function(self,new_pid,new_team)
   self.move=v2(0,0)
   self.dir=v2(1,0)
   if new_team then
    self.fpos=v2(0,0)
    self.pos=v2(0,0)
    self.vpcenter=v2(0,0)
    self.focus=v2(0,0)
    self.pid=new_pid
    self.set_team(self,new_team)
    self.randomize_skin(self)
   end
   self.sink=0
   self.hit_cooldown=0
   self.hit_drops={}
   self.running=false
   self.speed=0
   self.energy=K_MAX_ENERGY
   self.ammo=K_MAX_AMMO
   self.eliminated=false
   self.windup=0
   if self.facelr~=368 then
    self.anims=animgraph({
     idlelr={anim({428},8),"idlelr"},
     idled={anim({444},8),"idled"},
     idleu={anim({460},8),"idleu"},
     walklr={anim({426,428,430,428},8),"walklr"},
     walkd={anim({442,444,446,444},8),"walkd"},
     walku={anim({458,460,462,460},8),"walku"},
    },"idlelr")
   end
   self.hflip=0
   self.anims:to("idlelr")
  end,
  randomize_skin=function(self)
   -- randomize face
   local ALL_FACES={464,466,468,470,472,474}
   self.facelr=rndt(ALL_FACES)
   self.faced=self.facelr+16
   self.faceu=self.facelr+32
   -- randomize skin/hair
   local ALL_SKINHAIRS={
    {C_TAN,C_ORANGE},
    {C_TAN,C_BROWN},
    {C_TAN,C_BLACK},
    {C_TAN,C_YELLOW},
    {C_YELLOW,C_DARKGREY},
    {C_BROWN,C_DARKGREY},
   }
   self.skinc,self.hairc=
    table.unpack(rndt(ALL_SKINHAIRS))
  end,
 })
 p.reset(p,pid,team)
 return p
end
function cb_spawn_players(cb)
 for i,p in ipairs(cb.players) do
  -- choose a spawn tile
  local ispawn=math.random(#cb.player_spawns)
  p.fpos=v2scl(
   v2cpy(cb.player_spawns[ispawn]),8)
  table.remove(cb.player_spawns,ispawn)
  p.pos=v2flr(v2add(p.fpos,v2(0.5,0.5)))
  p.clipr=cb.clips[i]
  p.vpcenter=v2(
   p.clipr[1]+p.clipr[3]/2,
   p.clipr[2]+p.clipr[4]/2)
  p.focus=v2cpy(p.pos)
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
    p.eliminated=true
   end
  end
 end
 -- enable sudden death
 if mode_frames>=K_SUDDEN_DEATH_START
 and #refills>0 then
  -- remove all refill stations
  refills={}
  -- give all players one last refill
  for _,p in ipairs(players) do
   p.energy=K_MAX_ENERGY
   p.ammo=K_MAX_AMMO
  end
  -- stop music, play sudden death
  -- alarm, and queue up SD music
  music()
  local alarm_frames=140
  sfx(SFX_SUDDEN_DEATH,"D-4",alarm_frames)
  delay(function() music(MUS_SUDDEN_DEATH,-1,-1,true,true) end,alarm_frames)
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
   and b.pos.y>=p.pos.y-b.r
   and b.pos.x<=p.pos.x+7+b.r
   and b.pos.y<=p.pos.y+7+b.r then
    pop=true
    goto end_balloon_update
   end
  end
  ::end_balloon_update::
  if pop then
   sfx(SFX_BALLOONPOP,6*12+math.random(0,4),
    -1,K_CHAN_NOISE)
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
     p.hit_cooldown=K_HIT_COOLDOWN
     p.energy=max(0,p.energy-dmg)
     -- don't play "hit" sound on the
     -- same frame as "eliminated"
     if p.energy>0 then
      sfx(SFX_PLAYERHIT,3*12+math.random(10,22),
       -1,K_CHAN_SFX)
     end
    end
   end
   local disth=K_SPLASH_DIST/2
   local wc=b.pp and C_YELLOW or C_LIGHTBLUE
   for i=1,50 do
    add(wparts,{
     pos=v2cpy(b.pos),
     vel=v2scl(v2rnd(),0.5+rnd(1)),
     ttl=disth+rnd()*K_SPLASH_DIST,
     color=i<10 and b.color or wc,
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
  if not p.eliminated and p.energy==0 then
   p.eliminated=true
   sfx(SFX_ELIMINATED,4*12+math.random(0,4),
    -1,K_CHAN_SFX)
   -- TODO other time-of-elimination
   -- effects go here
  end
  -- touching hazard tiles is instant elimination
  local mtid=mget((p.pos.x+4)//8,
                  (p.pos.y+4)//8)
  if not p.eliminated
  and fget(mtid,SF_HAZARD) then
   p.eliminated=true
   sfx(SFX_ELIMINATED,4*12+math.random(0,4),
    -1,K_CHAN_SFX)
   -- TODO other time-of-drowning
   -- effects go here
  end
 end
 -- handle input & move players
 for _,p in ipairs(players) do
  if p.eliminated then
   p.sink=min(16,p.sink+0.25)
   goto player_update_end
  end
  local pb0=8*(p.pid-1)
  p.move.y=(btn(pb0+0) and -1 or 0)+(btn(pb0+1) and 1 or 0)
  p.move.x=(btn(pb0+2) and -1 or 0)+(btn(pb0+3) and 1 or 0)
  local mx,my=p.pos.x//8,p.pos.y//8
  p.running=btn(pb0+4)
   and p.sink==0
   and not fget(mget(mx,my),SF_BLOCK_RUNNING)
   and p.windup==0
  local max_speed=p.running
    and K_MAX_RUN_SPEED
     or K_MAX_WALK_SPEED
  if p.windup>0 then
   max_speed=K_MAX_WINDUP_SPEED
  end
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
   if p.move.y<0 then new_sn="walku" p.hflip=0
   elseif p.move.y>0 then new_sn="walkd" p.hflip=0
   else new_sn="walklr" p.hflip=p.move.x<0 and 1 or 0
   end
   -- footstep sounds interfere with
   -- the music
   --if mode_frames%15==p.pid then
   -- sfx(SFX_STEP,6*12+math.random(-4,4),
   --  -1,3)
   --end
  end
  if new_sn~=p.anims.sn then
   p.anims:to(new_sn)
  else
   p.anims:nextv()
  end
  -- Update "sink" if standing in
  -- shallow water
  local foot=v2(p.pos.x+4,p.pos.y+7)
  local mtid=mget(foot.x//8,foot.y//8)
  local fpi=8*(foot.y%8)+(foot.x%8)
  local fc=peek4(2*(0x4000+32*mtid)+fpi)
  local new_sink=0
  if fget(mtid,SF_SAND) then
   if fc==C_YELLOW or C_WHITE or C_TAN then
    new_sink=1
   end
  end
  if fget(mtid,SF_SHALLOW_WATER) then
   if fc==C_LIGHTBLUE or fc==C_DARKBLUE then
    new_sink=2
   end
  end
  if new_sink>p.sink then
   sfx(SFX_BALLOONPOP,5*12+math.random(0,4),
    -1,K_CHAN_NOISE)
   -- TODO: splash particles
  end
  p.sink=new_sink
  -- update hit cooldown and droplets
  if p.hit_cooldown>0 then
   p.hit_cooldown=p.hit_cooldown-1
   if (p.hit_cooldown%10)==0 then
    add(p.hit_drops,{
     pos=v2(flr(math.random(0,8)),0),
     vel=v2(0,0),
    })
   end
  end
  local hit_drops2={}
  for _,d in ipairs(p.hit_drops) do
   d.vel=v2add(d.vel,v2(0,K_GRAVITY))
   d.pos=v2add(d.pos,d.vel)
   if d.pos.y<16 then
    add(hit_drops2,d)
   end
  end
  p.hit_drops=hit_drops2
  -- Update player's camera focus.
  p.focus.x=approach(p.focus.x,p.pos.x+4,.1)//1
  p.focus.y=approach(p.focus.y,p.pos.y+4,.1)//1
  -- handle throwing balloons
  if p.ammo>0 and btn(pb0+5) then
   if p.windup==0 then
    sfx(SFX_WINDUP,2*12+math.random(5,9),
     -1,K_CHAN_SFX)
   end
   p.windup=min(K_MAX_WINDUP,p.windup+1)
  elseif not btn(pb0+5)
  and p.windup>0 then
   sfx(SFX_THROW,3*12+math.random(7,11),
    -1,K_CHAN_SFX)
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
    pp=p.yerrik_dream_mode,
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
  rp.radius=rp.radius+3
  if rp.radius<=K_MAX_PING_RADIUS then
   add(refill_pings2,rp)
  end
 end
 refill_pings=refill_pings2
 -- update refill stations
 for _,r in ipairs(refills) do
  if r.cooldown>0 then
   r.cooldown=r.cooldown-1
  else
   for _,s in ipairs(r.sparkles) do
    s:update()
   end
   for _,p in ipairs(players) do
    if not p.eliminated
    and rects_overlap(
        p.pos,v2add(p.pos,v2(7,7)),
        r.pos,v2add(r.pos,v2(7,7))) then
     sfx(SFX_REFILL,4*12+2,-1,K_CHAN_SFX)
     p.energy=K_MAX_ENERGY
     p.ammo=K_MAX_AMMO
     r.cooldown=K_REFILL_COOLDOWN
     add(refill_pings,{
      pos=v2add(r.pos,v2(4,4)),
      radius=0,
     })
    end
   end
  end
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

function create_tree(mx,my)
 t=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8-8, my*8-24),
  bounds1=v2(mx*8+15,my*8+7),
  flip=flr(rnd(2)),
  shadow=function(_ENV)
   elli(pos.x+4,pos.y+7,10,3,C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_TREE,pos.x-8,pos.y-24,
    C_TRANSPARENT, 1,flip,0, 3,4)
  end,
 })
 -- offset order slightly, so standing
 -- next to trees still puts your head
 -- in the leaves
 t.order,t.order2=t.pos.y+1,t.pos.x
 mset(mx,my,guess_replace_tile(mx,my,true))
 return t
end

function create_seesaw(mx,my)
 for x=mx,mx+4 do
  if mget(x,my)~=TID_SPAWN_SEESAW then
   trace("ERROR: seesaw spawn at "..mx..","..my.." must be 5 tiles wide", 2)
   exit()
  end
 end
 s=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8,my*8-8),
  bounds1=v2(mx*8+39,my*8+7),
  flip=flr(rnd(2)),
  shadow=function(_ENV)
   rect(pos.x,pos.y+7,40,2, C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_SEESAW, pos.x, pos.y-8,
    C_TRANSPARENT, 1,flip,0, 5,2)
  end,
 })
 s.order,s.order2=s.pos.y,s.pos.x
 for x=mx,mx+4 do
  mset(x,my,guess_replace_tile(mx,my,true))
 end
 return s
end

function create_toilet(mx,my)
 for x=mx,mx+1 do
  if mget(x,my)~=TID_SPAWN_TOILET then
   trace("ERROR: toilet spawn at "..mx..","..my.." must be 2 tiles wide", 2)
   exit()
  end
 end
 t=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8,my*8-16),
  bounds1=v2(mx*8+7,my*8+7),
  shadow=function(_ENV)
   rect(pos.x,pos.y+7,16,3, C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_TOILET, pos.x, pos.y-16,
    C_TRANSPARENT, 1,0,0, 2,3)
  end,
 })
 t.order,t.order2=t.pos.y,t.pos.x
 for x=mx,mx+1 do
  mset(x,my,guess_replace_tile(mx,my,true))
 end
 return t
end

function create_mbars(mx,my)
 for x=mx,mx+2 do
  if mget(x,my)~=TID_SPAWN_MBARS then
   trace("ERROR: mbars spawn at "..mx..","..my.." must be 3 tiles wide", 2)
   exit()
  end
 end
 m=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8,my*8-16),
  bounds1=v2(mx*8+23,my*8+7),
  colorkey=15,
  shadow=function(_ENV)
   line(pos.x, pos.y+7,
        pos.x+23, pos.y+7, C_DARKGREY)
   line(pos.x+6, pos.y+5,
        pos.x+17, pos.y+5, C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_MBARS, pos.x, pos.y-16,
    colorkey, 1,0,0, 3,3)
  end,
 })
 m.order,m.order2=m.pos.y,m.pos.x
 -- middle tile of monkey bars is passable
 -- TODO: skip the middle tile when drawing spawn tiles
 -- so we don't have to replace it
 mset(mx+0,my,guess_replace_tile(mx,my,true))
 mset(mx+1,my,rndt(TID_GRASS_POOL))
 mset(mx+2,my,guess_replace_tile(mx,my,true))
 return m
end

function create_swing(mx,my)
 for x=mx,mx+3 do
  if mget(x,my)~=TID_SPAWN_SWING then
   trace("ERROR: swing spawn at "..mx..","..my.." must be 4 tiles wide", 2)
   exit()
  end
 end
 s=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8, my*8-16),
  bounds1=v2(mx*8+31, my*8+7),
  shadow=function(_ENV)
   line(pos.x+1, pos.y+5,
        pos.x+26,pos.y+5,C_DARKGREY)
   elli(pos.x+10,pos.y+6,4,1,C_DARKGREY)
   elli(pos.x+21,pos.y+6,4,1,C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_SWING, pos.x, pos.y-16,
    C_TRANSPARENT, 1,0,0, 4,3)
  end,
 })
 s.order,s.order2=s.pos.y,s.pos.x
 for x=mx,mx+3 do
  mset(x,my,guess_replace_tile(mx,my,true))
 end
 return s
end

function create_elephant(mx,my)
 e=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8-4, my*8-8),
  bounds1=v2(mx*8+11,my*8+7),
  shadow=function(_ENV)
   elli(pos.x+4,pos.y+7,7,2,C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_ELEPHANT, pos.x-4, pos.y-8,
    C_TRANSPARENT, 1,0,0, 2,2)
  end,
 })
 e.order,e.order2=e.pos.y,e.pos.x
 mset(mx,my,guess_replace_tile(mx,my,true))
 return e
end

function create_bush(mx,my)
 local dx,dy=rnd(4)//1,rnd(7)//1
 b=obj({
  pos=v2(mx*8+dx,my*8+dy),
  bounds0=v2(mx*8+dx-8,my*8+dy-8),
  bounds1=v2(mx*8+dx+7,my*8+dy+7),
  flip=flr(rnd(2)),
  shadow=function(_ENV)
   elli(pos.x,pos.y+7,8,2,C_DARKGREY)
  end,
  draw=function(_ENV)
   spr(SID_BUSH, pos.x-8, pos.y-8,
    C_TRANSPARENT, 1,flip,0, 2,2)
  end,
 })
 b.order,b.order2=b.pos.y,b.pos.x
 -- bushes block balloons
 mset(mx,my,guess_replace_tile(mx,my,false))
 return b
end

ALL_SIGNS={
 [3]={
  {h=3,ft=function(spos) spr(TID_SIGN1,spos.x+4,spos.y-16+3,10, 1,0,0, 2,2) end},
  {h=3,ft=function(spos) spr(TID_SIGN2,spos.x+4,spos.y-16+3,10, 1,0,0, 2,2) end},
  {h=3,ft=function(spos) spr(TID_SIGN3,spos.x+4,spos.y-16+3,10, 1,0,0, 2,2) end},
 },
 [4]={
  {h=3,ft=function(spos) print("A Good\n  Sign",spos.x+6,spos.y-16+6,C_DARKGREY,false,1,true) end},
 },
 [5]={
  {h=3,ft=function(spos) print("Park at\nown risk",spos.x+6,spos.y-16+6,C_DARKGREY,false,1,true) end},
  {h=3,ft=function(spos) print("Dewdrop\nGardens",spos.x+6,spos.y-16+6,C_DARKGREY,false,1,true) end},
  {h=3,ft=function(spos) print("Have fun\nout there!",spos.x+6,spos.y-16+6,C_DARKGREY,false,1,true) end},
 },
 [6]={
  {h=3,ft=function(spos) print("NO CAMPING\n  ALLOWED!",spos.x+6,spos.y-16+6,C_DARKGREY,false,1,true) end},
  {h=3,ft=function(spos) print("NOTHING TO\nSEE HERE.",spos.x+6,spos.y-16+6,C_DARKGREY,false,1,true) end},
 },
}

function create_sign(mx,my)
 -- determine width of sign
 local mx2=mx
 while true do
  if mget(mx2+1,my)~=TID_SPAWN_SIGN then
   break
  end
  mx2=mx2+1
 end
 local sw=1+mx2-mx
 -- choose a random sign from ALL_SIGNS
 -- based on sign width
 if not ALL_SIGNS[sw] then
  trace("ERROR: No signs available of width "..sw.." for sign at "..mx..","..my, 2)
  exit()
 end
 local src=rndt(ALL_SIGNS[sw])
 s=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8, my*8-(src.h-1)*8),
  bounds1=v2(mx*8+sw*8-1, my*8+7),
  ft=src.ft,
  w=sw,
  h=src.h,
  shadow=function(_ENV)
   rect(pos.x,pos.y+7,sw*8,3,C_DARKGREY)
  end,
  draw=function(_ENV)
   local sx,sy=pos.x,
               pos.y+8-(src.h*8)
   spr(SID_SIGN, sx,sy,C_TRANSPARENT,
       1,0,0, 1,src.h)
   for i=1,sw-2 do
    spr(SID_SIGN+1, sx+i*8,sy,C_TRANSPARENT,
        1,0,0, 1,src.h)
   end
   spr(SID_SIGN+2, sx+sw*8-8,sy,
       C_TRANSPARENT, 1,0,0, 1,src.h)
   src.ft(pos)
  end,
 })
 s.order,s.order2=s.pos.y,s.pos.x
 for x=mx,mx+sw-1 do
  mset(x,my,guess_replace_tile(mx,my,true))
 end
 return s
end

ALL_ROCKS={
 [1]={
  {h=1,sid=334},
  {h=1,sid=335},
 },
 [2]={
  {h=1,sid=350},
  {h=2,sid=366},
 },
}
function create_rock(mx,my)
 -- determine width of rock
 local mw,spawner=1,mget(mx,my)
 if spawner==TID_SPAWN_ROCK2 then
  if mget(mx+1,my)~=TID_SPAWN_ROCK2 then
   trace("ERROR: large rock spawn at "..mx..","..my.." must be 2 tiles wide", 2)
   exit()
  end
  mw=2
 end
 local src=rndt(ALL_ROCKS[mw])
 r=obj({
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8, my*8+8-8*src.h),
  bounds1=v2(mx*8+8*mw-1, my*8+7),
  flip=flr(rnd(2)),
  shadow=function(_ENV)
   -- rocks don't need shadows
  end,
  draw=function(_ENV)
   spr(src.sid, pos.x, pos.y+8-8*src.h,
    C_TRANSPARENT, 1,flip,0, mw,src.h)
  end,
 })
 r.order,r.order2=r.pos.y,r.pos.x
 for x=mx,mx+mw-1 do
  mset(x,my,guess_replace_tile(mx,my,true))
 end
 return r
end

function create_refill(mx,my)
 local r={
  pos=v2(mx*8,my*8),
  bounds0=v2(mx*8-5, my*8),
  bounds1=v2(mx*8+5, my*8+8),
  cooldown=0,
  sparkles={}
 }
 for i=1,10 do
  local s=obj({
   ttl=0,
   reset=function(self)
    self.pos=v2(r.pos.x+flr(rnd(9)),
                r.pos.y+3)
    self.ttl=flr(rnd(35,45))
   end,
   update=function(self)
    if self.ttl==0 then
     self:reset()
    else
     self.ttl=self.ttl-1
     self.pos.x=self.pos.x+0.4*rnd(1)-0.2
     self.pos.y=self.pos.y-0.3
    end
   end,
   draw=function(self)
    local grad={
     C_DARKBLUE,
     C_LIGHTBLUE,
     C_LIGHTBLUE,
     C_LIGHTBLUE,
     C_WHITE,
     C_WHITE,
    }
    pix(self.pos.x,self.pos.y,
     grad[clamp(#grad*(self.ttl/20),1,#grad)//1])
   end,
  })
  for j=1,100 do
   s:update()
  end
  add(r.sparkles,s)
 end
 return r
end

function cb_draw(_ENV)
 -- update dissolve
 if dissolve then
  vbank(1)
  local mind=K_SCREEN_H
  for i=1,#dissolve do
   mind=min(mind,dissolve[i])
   if dissolve[i]<K_SCREEN_H then
    x=i-1
    local d2=dissolve[i]+1+rnd(3)
    line(x,dissolve[i],x,d2//1,C_BLACK)
    dissolve[i]=d2
   end
  end
  if mind==K_SCREEN_H then
   dissolve=nil
  end
  vbank(0)
 end
 clip()
 cls(C_BLACK)
 -- draw each player's viewport
 for _,p in ipairs(players) do
  clip(table.unpack(p.clipr))
  camera(-(p.vpcenter.x-p.focus.x),
         -(p.vpcenter.y-p.focus.y))
  -- compute culling rectangle extents,
  -- in world-space pixels.
  local clipdim=v2(p.clipr[3],p.clipr[4])
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
   m0.x*8,m0.y*8, -1,1,nil
  )
  -- build list of draw calls inside
  -- the culling rect, and draw
  -- shadows onto the map
  local draws={}
  -- draw players
  for _,p2 in ipairs(players) do -- draw corpses
   if rects_overlap(cull0,cull1,
       v2add(p2.pos,v2(-8,-8)),
       v2add(p2.pos,v2(8,8))) then
    local ec=p2.yerrik_dream_mode and C_BROWN or C_DARKBLUE
    elli(p2.pos.x+4,p2.pos.y+7,
         5,2,p2.eliminated and ec or C_DARKGREY)
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
      b.r, b.team, b.t, b.t1, 6
     }
    })
   end
  end
  -- draw obstacles (passive scenery)
  for _,o in ipairs(obstacles) do
   if rects_overlap(cull0,cull1,
       o.bounds0, o.bounds1) then
    o:shadow()
    add(draws,{
     order=o.order, order2=o.order2,
     f=function(o)
      o:draw()
     end, args={o}
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
     f=function(r)
      draw_refill(r)
     end, args={r}
    })
   end
  end
  -- re-draw objects that block shadows
  map(m0.x,m0.y,
   (cull1.x-cull0.x+7)//8,
   (cull1.y-cull0.y+7)//8 + 1,
   m0.x*8,m0.y*8, C_DARKGREEN,1,
   function(tid,x,y)
    return fget(tid,SF_BLOCK_SHADOWS)
     and tid or TID_GRASS0
   end
  )
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
  -- draw refill station pings
  for _,rp in ipairs(refill_pings) do
   if rects_overlap(cull0,cull1,
       v2sub(rp.pos,v2(rp.radius,rp.radius)),
       v2add(rp.pos,v2(rp.radius,rp.radius))) then
    circb(rp.pos.x, rp.pos.y,
          rp.radius, rp.radius%16)
   end
  end
  -- restore screen-space camera
  camera(0,0)
  -- draw player UI
  local msgw=oprint("P"..p.pid,p.clipr[1]+2,p.clipr[2]+2,p.color,p.color2)
  draw_energy_ui(p.clipr[1]+msgw+2,p.clipr[2]+2,32,5,p.energy)
  draw_ammo_ui(p.clipr[1]+msgw+39,p.clipr[2]+4,p.ammo,p.color)
  -- for low-energy/ammo players, draw "refill" prompt
  if (p.energy<K_ENERGY_WARNING or p.ammo==0)
  and not p.eliminated
  and mode_frames<K_SUDDEN_DEATH_START then
   dsprint("REFILL!",
         p.vpcenter.x-12,p.vpcenter.y+20,
         C_RED,C_DARKGREY)
   local pc=p.focus
   local closest=v2(math.huge,math.huge)
   local closest_d2=v2dstsq(pc,closest)
   for _,r in ipairs(refills) do
    local rc=v2add(r.pos,v2(4,4))
    local d2=v2dstsq(pc,rc)
    if r.cooldown==0
    and d2<closest_d2 then
     closest=v2cpy(rc)
     closest_d2=d2
    end
   end
   local closest_d=sqrt(closest_d2)
   if closest_d>40 then
    local closest_dir=v2scl(
     v2norm(v2sub(closest,pc)),
     min(mode_frames%30,closest_d))
    circ(p.vpcenter.x+closest_dir.x,
        p.vpcenter.y+closest_dir.y,
        1,C_RED)
   end
  end
  -- draw "game over" message for eliminated players
  if p.eliminated then
   rect(p.vpcenter.x-38,p.vpcenter.y-20,75,9,C_BLACK)
   rectb(p.vpcenter.x-38,p.vpcenter.y-20,75,9,p.color)
   local w=print("ELIMINATED!",p.vpcenter.x-36,p.vpcenter.y-18,p.color,true)
  end
  -- draw viewport border.
  rectb(p.clipr[1],p.clipr[2],p.clipr[3],p.clipr[4],p.color)
 end
 -- draw sudden death message
 if mode_frames>=K_SUDDEN_DEATH_START then
  camera()
  clip()
  local msg="SUDDEN DEATH!"
  local msgw=print(msg,500,500,C_RED,true,2)
  local msgx,msgy=K_SCREEN_W//2-msgw//2,
   -10+(mode_frames-K_SUDDEN_DEATH_START)//1
  dsprint(msg,msgx,msgy,
   C_RED,C_BLACK,true,2)
 end
end

function balloon_throw_target(p)
 local dist=lerp(K_MIN_THROW,K_MAX_THROW,
             p.windup/K_MAX_WINDUP)
 local target=v2add(v2add(p.pos,v2(4,4)),
                    v2scl(v2norm(p.dir),dist))
 if not v2eq(p.move,v2zero) then
  target=v2add(target,v2scl(v2norm(p.move),1))
 end
 return target
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

function draw_balloon(x,y,r,team,t,t1,h)
 local t=t or 0
 local t1=t1 or 1
 local h=h or 6
 local yoff=h*sin(-0.5*t/t1)
 local rx,ry=r+r*sin(.03*t)/3,
             r+r*cos(1.5+.04*t)/3
 elli(x,y-yoff,rx,ry,TEAM_COLORS2[team])
 elli(x+r/4,y-yoff-r/4,rx*.75,ry*.75,TEAM_COLORS[team])
 elli(x+r/4,y-yoff-r/4,rx*.25,ry*.25,C_WHITE)
 ellib(x,y-yoff,rx+1,ry+1,C_BLACK)
end

function draw_energy_ui(x,y,w,h,energy)
 rectb(x,y,w,h,K_WHITE)
 rect(x+1,y+1,(w-2)*energy/K_MAX_ENERGY,
  h-2,C_RED)
end

function draw_ammo_ui(x,y,count,color)
 for ib=0,count-1 do
  circ(x+1+ib*6,y,2,color)
  circb(x+1+ib*6,y,2,C_BLACK)
 end
end

function draw_refill(r)
 if r.cooldown==0 then
  for _,s in ipairs(r.sparkles) do
   s:draw()
  end
 end
 local t01=r.cooldown/K_REFILL_COOLDOWN
 local frame=1+min(t01*#SID_REFILL_EMPTY,#SID_REFILL_EMPTY-1)//1
 local sid=t01==0 and SID_REFILL
    or SID_REFILL_EMPTY[frame]
 spr(sid, r.pos.x-4, r.pos.y,
  C_TRANSPARENT, 1,0,0, 2,1)
end

function draw_player(p)
 local face=p.facelr
 if p.dir.y<0 then face=p.faceu
 elseif p.dir.y>0 then face=p.faced
 end
 local ybody,yface=p.pos.y+p.sink,
                   p.pos.y+p.sink-8
 local soakdarkc=p.yerrik_dream_mode
   and C_ORANGE or C_DARKBLUE
 local soaklitec=p.yerrik_dream_mode
   and C_YELLOW or C_LIGHTBLUE
 -- draw actual player
 local PAL_C1=6
 local PAL_C2=2
 local PAL_H=12
 local PAL_S=14
 if p.eliminated then
  -- swap to "soaked" palette
  poke4(2*0x03FF0,soakdarkc)
  for i=1,15 do
   poke4(2*0x03FF0+i,soaklitec)
  end
 else
  -- palette-swap player-specific colors
  poke4(2*0x03FF0+PAL_C1,p.color)
  poke4(2*0x03FF0+PAL_C2,p.color2)
  poke4(2*0x03FF0+PAL_H,p.hairc)
  poke4(2*0x03FF0+PAL_S,p.skinc)
 end
 push_clip(p.pos.x-4-camera_x,
           p.pos.y-8-camera_y,
           16,16)
 spr(face,p.pos.x-4,yface,
     C_TRANSPARENT, 1,p.hflip,0, 2,1)
 spr(p.anims.v,p.pos.x-4,ybody,
     C_TRANSPARENT, 1,p.hflip,0, 2,1)
 for i=0,7 do
  poke(0x03FF0+i,_g.palbytes[i])
 end
 -- recently-hit players have extra
 -- effects during the hit cooldown
 -- period
 if not p.eliminated
 and p.hit_cooldown>0 then
  push_clip(p.pos.x-4-camera_x,
            p.pos.y-8+(K_HIT_COOLDOWN-p.hit_cooldown)//3-camera_y,
            16,16)
  -- swap to "soaked" palette
  poke4(2*0x03FF0,soakdarkc)
  for i=1,15 do
   poke4(2*0x03FF0+i,soaklitec)
  end
  spr(face,p.pos.x-4,yface,
      C_TRANSPARENT, 1,p.hflip,0, 2,1)
  spr(p.anims.v,p.pos.x-4,ybody,
      C_TRANSPARENT, 1,p.hflip,0, 2,1)
  for i=0,7 do
   poke(0x03FF0+i,_g.palbytes[i])
  end
  pop_clip()
  for _,d in ipairs(p.hit_drops) do
   pix(p.pos.x-2+d.pos.x,
       p.pos.y-7+d.pos.y,
       soaklitec)
   pix(p.pos.x-2+d.pos.x,
       p.pos.y-7+d.pos.y+1,
       soakdarkc)
  end
 end
 pop_clip()
 -- draw balloon and reticle
 -- if winding up
 if p.windup>0 then
  local borig=balloon_origin(p.pos,p.dir)
  draw_balloon(borig.x,borig.y,
   K_BALLOON_RADIUS,p.team)
  local target=balloon_throw_target(p)
  for i=1,4 do
   local pt=v2lerp(borig,target,i/4)
   pix(pt.x,pt.y,C_WHITE)
  end
  circ(target.x,target.y,1,C_WHITE)
 end
end

---- victory

mode_victory={}
function vt_enter(args)
 sync(1|2|32,0)
 -- fade in from black
 fade_init_palette()
 fade_black(1)
 add_frame_hook(
  function(nleft,ntotal)
   fade_black(nleft/ntotal)
  end,
  function()
   fade_black(0)
   mode_victory.ignore_input=false
  end,
  30)
 camera(0,0)
 clip()
 mode_victory=obj({
  update=vt_update,
  draw=vt_draw,
  leave=vt_leave,
  players=args.players,
  winning_team=args.winning_team,
  grnd_y=80,
  drop_spawns={},
  drops={},
  ignore_input=true,
  balloons={},
  targets={},
 })
 local vt=mode_victory
 -- place players
 local x0,x1=60,180
 local dx=(x1-x0)/(#vt.players-1)
 for i,p in ipairs(vt.players) do
  p:reset()
  p.pos=v2(flr(x0+(i-1)*dx-4),
           vt.grnd_y-8)
  p.y0=p.pos.y -- jump pos
  p.dir=v2(1,0)
  p.hflip=false
  p.anims:to("idlelr")
 end
 -- Make a list of all pixels in a
 -- sprite that are not transparent.
 -- TODO: this is super overkill, just
 -- spawn drops in a rect like we do
 -- in-game.
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
 -- spawn loser balloons
 for _,p in ipairs(vt.players) do
  if p.team~=vt.winning_team then
   add(vt.targets,v2add(p.pos,v2(4,4)))
  end
 end
 for i=1,20*#vt.targets do
  local bp=v2(rndt({-10,K_SCREEN_W+10}),
   math.random(0,K_SCREEN_H))
  local bt=60+math.random(30)//1
  add(vt.balloons,{
   pos0=v2cpy(bp),
   pos=v2cpy(bp),
   shadowy=bp.y,
   pos1=v2add(rndt(vt.targets),
    v2(math.random(-6,6),math.random(-12,2))),
   t=math.random(0,bt), -- stagger initial throws
   t1=bt,
   --pid=p.pid, -- don't think we need a pid in this path
   team=vt.winning_team,
   pp=vt.players[1].yerrik_dream_mode,
   color=TEAM_COLORS[vt.winning_team],
  })
 end
 music(MUS_VICTORY,-1,-1,false)
 return vt
end

function vt_leave(_ENV)
 clip()
 music()
end

function vt_update(_ENV)
 if not ignore_input then
  -- go back to teams screen
  -- for a rematch
  if btnp(0*8+4) or btnp(1*8+4)
  or btnp(2*8+4) or btnp(3*8+4) then
   sfx(SFX_MENU_CONFIRM,"D-5",-1,K_CHAN_SFX)
   set_next_mode("teams",{
    prev_players=players,
   })
  end
 end
 -- update loser balloons
 for _,b in ipairs(balloons) do
  b.t=b.t+1
  if b.t>b.t1 then
   -- pop
   local chan=(music_state()==255)
     and math.random(0,3)
      or K_CHAN_SFX
   sfx(SFX_SHORT_POP,6*12+math.random(0,4),
    -1,chan)
   -- spawn drops from balloon
   local bvel=v2sub(b.pos,
    v2lerp(b.pos0,b.pos1,(b.t-1)/b.t1))
   for i=1,20 do
    add(drops,{
     pos=v2cpy(b.pos),
     y1=grnd_y,
     vel=v2add(v2scl(bvel,0.2),v2(
      rnd(1)-0.5,rnd(1)-0.75)),
     dark=rnd()<0.5,
     pp=players[1].yerrik_dream_mode,
    })
   end
   -- recycle balloon
   b.pos0=v2(rndt({-10,K_SCREEN_W+10}),
    math.random(0,K_SCREEN_H))
   b.pos=v2cpy(b.pos0)
   b.shadowy=lerp(b.pos0.y,grnd_y,b.t/b.t1)
   pos1=v2add(rndt(targets),
    v2(math.random(-6,6),math.random(-12,2)))
   b.r=K_BALLOON_RADIUS
   b.t=0
   b.t1=60+math.random(30)
  elseif b.t>=0 then
   b.pos=v2lerp(b.pos0,b.pos1,b.t/b.t1)
   b.shadowy=lerp(b.pos0.y,grnd_y,b.t/b.t1)
   local br0=lerp(1,4,b.pos0.y/K_SCREEN_H)
   b.r=lerp(br0,K_BALLOON_RADIUS,b.t/b.t1)
  end
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
     dark=rnd()<0.5,
     pp=p.yerrik_dream_mode,
    })
   end
  end
 end
end

function vt_draw(_ENV)
 cls(C_DARKBLUE)
 -- draw player shadows
 for _,p in ipairs(players) do
  if p.team==winning_team then
   local srx=lerp(5,3,(p.y0-p.pos.y)/10)
   local sry=lerp(2,1,(p.y0-p.pos.y)/10)
   elli(p.pos.x+4,p.y0+7,srx,sry,C_BLACK)
  else
   elli(p.pos.x+4,p.y0+7,18,4,
        p.yerrik_dream_mode and C_YELLOW or C_LIGHTBLUE)
   elli(p.pos.x+4,p.y0+7,6,2,
        p.yerrik_dream_mode and C_BROWN or C_DARKBLUE)
  end
 end
 -- draw loser balloon shadows
 table.sort(balloons,
  function(a,b) -- sort by height above ground
   return abs(0.5-(a.t/a.t1))
        < abs(0.5-(b.t/b.t1))
  end)
 for _,b in ipairs(balloons) do
  local bt01=b.t/b.t1
  local bs=C_BLACK
  if bt01>0.1 and bt01<0.9 then
   bs=C_DARKGREY
  end
  elli(b.pos.x,b.shadowy,b.r,1,bs)
 end
 -- draw players
 for _,p in ipairs(players) do
  draw_player(p)
 end
 -- draw loser balloons
 table.sort(balloons,
  function(a,b) -- sort back to front
   return a.shadowy==b.shadowy
      and a.pos.x<b.pos.x
      or  a.shadowy<b.shadowy
  end)
 for _,b in ipairs(balloons) do
  draw_balloon(b.pos.x,b.pos.y,
   b.r,b.team,b.t,b.t1,
   K_SCREEN_H/4)
 end
 -- draw water drops
 for _,d in ipairs(drops) do
  local c=d.dark and
   (d.pp and C_ORANGE or C_DARKBLUE) or
   (d.pp and C_YELLOW or C_LIGHTBLUE)
  pix(d.pos.x,d.pos.y,c)
 end
 -- draw message
 local msgc=(winning_team>0)
   and TEAM_COLORS[winning_team]
    or C_WHITE
 local msg=(winning_team>0)
   and ""..TEAM_NAMES[winning_team].." Team wins!"
    or "It's a tie!"
 local msgw=print(msg,0,200,msgc,false,2)
 dsprint(msg,120-msgw/2,100,msgc,C_BLACK,false,2)
 -- navigation controls
 spr(btnspr(4,1),1,K_SCREEN_H-9, C_TRANSPARENT)
 dsprint("Rematch",10,K_SCREEN_H-8,C_WHITE,C_DARKGREY,true)
end
-- <TILES>
-- 000:3333333333333333333333333333333333333333333333333333333333333333
-- 002:9bbbbbb1bbbbbbb1bbbbbbbbbbbbbbfbb1bb1b1bb1bb1bbbb1bbb37bbbbbbbbb
-- 003:bbb9bbbbbbbbbbbbbbbbbbb1bbbbbb1bb1bbbb1b1bbfbbbb1bbabb9b17bbbbbb
-- 004:777977777b77777777777777777771777777777777777779177777777777b777
-- 005:777b77777777777197777777777777777717777777777777777777b777779777
-- 006:eeeeeeeeeeefeeeeeeeee8eeeeeeeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeee
-- 007:eeeeeeeeeefee8eeeeeeeeeeeeeeeeeeeeeeeeeee8eee8eeeeefeeeeeeeeeeee
-- 010:aaaaaaaaaaaaaa55aaaa5558aaa55888aa555584aa58855da5588455a5884d85
-- 011:aaaaaaaa55aaaaaa8555aaaa48855aaa488855aa488885aad488855a5d48885a
-- 012:aaaaaaaaaaaaaaa8aaaaaaa8aaaaaaaaaaa33333aaa37377aaa37377aaa37377
-- 013:aaaaaaaa88aaaaaa8aaaaaaaaaaaaaaa33333aaa77373aaa77373aaa77373aaa
-- 014:aaaaaaaaaaaaaa55aaaa5557aaa55887aa555578aa588558a5578755a5888885
-- 015:aaaaaaaa55aaaaaa8555aaaa87855aaa878855aa788885aa8888855a5888885a
-- 023:0004844433334444333344443333844800044444333344443333444400844444
-- 026:a5884d8da5584dddaa584dddaa5584ddaaa55844aaaa5558aaaaaa55aaaaaaaa
-- 027:55d4885ad554855add5585aadd4555aa44855aaa8555aaaa55aaaaaaaaaaaaaa
-- 028:aaa37377aaaa3737aaaa3737aaaa3737aaaa3737aaaa3737aaaa3333aaaaaaaa
-- 029:77373aaa7373aaaa7373aaaa7373aaaa7373aaaa7373aaaa3333aaaaaaaaaaaa
-- 030:a5808000a5508000aa588888aa558888aaa55888aaaa5558aaaaaa55aaaaaaaa
-- 031:5500085a0550055a885585aa888555aa88855aaa8555aaaa55aaaaaaaaaaaaaa
-- 032:444484444444444444d444444444444444444444d4444444444444d4444d4444
-- 033:444444444444d44444444484444444444d4444444444444d4444444444844444
-- 034:d4444444444484444444444d44444444444444444844444444444d4444444444
-- 037:eeeeeeeeeeeeefeee8eeeeeeeeeeeeeeeeeeeeeeeefeee8eeeeeeeeeeeeeeeee
-- 038:eeeeeeeeeeeeeeeeeeeee8eeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 039:eeeeeeeeeeeeeee8eeeeee88eeeee8ddeeee8dddeee88dddeee8ddddee8dddd4
-- 040:88ddd4448ddd4444ddd44444dd444444dd444444d44444444444444444444444
-- 048:444d44444444444448444444444444d444444444d44444444444444444444844
-- 049:444444444d4444444444444d444448444444444444444444444d444484444444
-- 050:4484444444444444444444444444d4444444444d4444444444444484d4444444
-- 051:4444444444444444444444444444444444444444444444444444444444444444
-- 053:eeeeeeeeeeeeeeeeeeee8eeeeeeeeeeeee8eeeeeeeeeeeeeeefeefeeeeeeeeee
-- 054:eeeeeeeeeeefeeeeeeeee8eeeeeeeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeee
-- 055:ee8ddd44e8dddd44e8ddd444e8dddd44e8dddd44ee8d4d44ee8dddd4eee8ddd4
-- 056:eeee8dddeeee8dddeeeee8ddeeeeee8deeeeeee8eeeeee8eeeeeeeeeeeeeeeee
-- 057:4444444444444444d4444444dd444444dd4444448dd44444e8dd4444ee8dd444
-- 059:0000000033777733370000737000000730000007300dd00730dddd070dddddd0
-- 060:03333330d0000330dd000030ddd00000ddd00030dd000730d777733003333330
-- 061:0dddddd030dddd07300000073333777300000000333073333330733300000000
-- 062:033333300330000d030000dd03000ddd03000ddd030000dd0370000d03377770
-- 064:bbbbbbbbb9bbbbbbbbbb7bbbbbbbbb1bb1bbfb1bbbbb1bbbb1bbbbb1b1bbbbbb
-- 065:bb9bbbbbbbabbb7bbbabbbbbbbbbbb1bbbbb7b1bbbbbbbbb71bbbbbbb1bbbbbb
-- 066:bbbbbbbbfbb9bbbbbabbbb9bbabb1bbbbbb1bbbbbbb1bbbbb9bbbb1bbbbbbbab
-- 067:bbabbbbbbbabbbbbbbbb1bbbbbbb1bbbbbbb1bbbbbbb1b5bb1bbbbab1bbbbbbb
-- 068:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 069:eeeeeeeeeeeeeeefeeee8eeeeeeeeeeeeeeeeeeeeeeefeeee8eeeeeeeeeeeeee
-- 070:eeeeeeeeeefee8eeeeeeeeeeeeeeeeeeeeeeeeeee8eee8eeeeefeeeeeeeeeeee
-- 071:eee8ddd4ee8dddd4ee8ddd44ee8dd444eee8dd44eee8ddd4eee8dd44eeee8d44
-- 075:0000000000000000000080000000080008888880000008000000800000000000
-- 076:0000000000000000000080000000800000808080000888000000800000000000
-- 077:0000000000000000000000000008000000888000080808000008000000080000
-- 078:0000000000000000000800000080000008888880008000000008000000000000
-- 080:bbbbbb37b1bbb377b1bbabbbb9bbb1bbbb1bbbbbabbbbb2babbbbbabbbbbbbbb
-- 081:bbbbbbbbb1b9bbbbb1bbbbbabbbbbbbabbbbbbbb19bb137b1bb1b37bbbb1bbbb
-- 082:bbbbbb1bbbbbbbb1bbb1bbb1bbbbbbbbbbbbbbbbbb1bfbbbb1bbab7bb1bbbb7b
-- 083:bbbb7bbbbbbbbbbb9bbbbbbbbbbbbbbbbfbbbbbbbbabbbabbbabbabb9bbbbabb
-- 084:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 085:ffffffff33333333333333333333333333333333333333333333333333333333
-- 086:ffffffff33333333333333333333333333333333333333333333333333333333
-- 089:9ddddd91c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c79ddddd9b
-- 090:9ccccccbd7777779dccccccdd777777ddccccccdd777777ddcccccc99777777b
-- 091:ddd9b1194ddd999d4ddddddd4ddddddd4ddddddd4ddddddddddddddd4dddd999
-- 092:d444444ddddddddddddddddddddddddd9dddddddb9ddddd999dddd9bb9ddddd9
-- 093:b9ddddd99ddddd9b9ddddd999ddddddddddddddddddddddddddddddd4d4444dd
-- 094:bb9dddd499ddddddddddddd4ddddddd4dddddddddddddddd9dddddddb99dddd4
-- 095:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 096:bbbfbbbbbbbabbbb1bbbbbbb1bbbbbb11bb9bbb1b1bbbbb1b1bb9b1bb1bbbbbb
-- 097:bbbbbbbbbbbbbb3bb7bb1bbb1bbb1bbbbbbb1bb1bbab1b91bbab1bbbbbabbbbb
-- 098:bbbbbbbbb3bbbbbb1bbbbbbbbb1bb1babbbbb11bb1bbba3bbb1bba7bbb1bbbbb
-- 099:bbb9bbbbbbbbbbbbbbbbbbb1bbbbbb1bb1bbbb1b1bbfbbbb1bbabb9b17bbbbbb
-- 100:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 101:33333333333333333333333333333333333333333333333333333333ffffffff
-- 102:33333333333333333333333333333333333333333333333333333333ffffffff
-- 104:9bbbfbbbd99b1b99dd99999dddddddddddddddddddddd1dddddd91999999bbbb
-- 105:99999991ddddddd9ddddddddddddddddddd9dddddd9119ddd951bb199bbbbb1b
-- 106:b99999919ddddd99ddddddd9ddddddd9dddddd12dddddd919ddddd9bb9ddddd9
-- 107:bbbbb1b1bfb17bb11bb11bb9bbbbb99d1bbb9dddbbb9ddddbbb9dd4dbb9ddddd
-- 108:b1b99bbbbb9dd9b599dddd91ddddddd9dddddddddddddddddd4ddddddddd44d4
-- 109:bbbbbbbbbbbbbbbbb99bb9999dd99ddddddddd4ddddddddd4ddddddddd444d44
-- 110:bbb137b1fbbbbbbb99999bbbddddd999d4dddddddddddd4ddddddddd44dd444d
-- 111:1bbbbbbb1bbbb11bbbb1bbbbbb77bbfb9bbbbbb1d9bbbbb1dd9b1bbbddd9bbbb
-- 112:110000111001100100b11b0000b11b000b1111b0000cc000100cc00111000011
-- 113:1100001117777771070c0c7007cccc7007000070070000701700007111000011
-- 114:1100001117777771070400700704007007040070070cc0701700007111000011
-- 115:1100001110aa000100acc0000055c20007552270074444701077770111000011
-- 116:1108801110088001008888000808808000088000008008001080080111000011
-- 117:110007111009977100799770077797077077770700777700100c00011100c011
-- 118:110000111044000104dddd4004ddddd004ddddd0004444401000000111000011
-- 119:110b0011100b70010b070b700b7a07000ababab000a0ab0010b0b00111000011
-- 120:1999999b99ddddd99ddddddd9ddddddd21dddddd19ddddddb9ddddd99ddddd9b
-- 121:9ddddd9b9ddddd9b9dddd91b9dddd91b29ddd9bb19dddd9bb9dddd9b9ddddd91
-- 122:b9ddddd9b9ddddd9b59dddd9b19dddd9bb9ddd9fb9dddd91b9dddd9b19ddddd9
-- 123:bb9dddddb9ddddd4b9ddd4d4b9ddddd4b9ddddd4bb9d4dd4bb9dddd4bbb9ddd4
-- 127:ddd9b111ddd9bbb14dd9bb1bdddd99bb4ddddd9b4dd4dd9bddddd9bbdd4dd9bb
-- 128:11000011100000010999999009eeee9009999990090000901000000111000011
-- 129:1100001110000001044000000004700000007440000070001000000111000011
-- 132:1100001110000001000000000003700000777000007337001000000111000011
-- 133:1100001110007001007777000773377003777330007337301033330111000011
-- 134:1100001110088001008dd80000d88d0000d88d0000dddd0010dddd0111000011
-- 137:9ddddd919ddddd9bb9dddd91b1dddd5b19ddd91b9dddd9bb9dddd9b19ddddd9b
-- 138:19ddddd9b9ddddd919dddd9bb1dddd1bb19ddd91bb9dddd91b9dddd9b9ddddd9
-- 139:bbb9ddd4bb9dddd4bb9dddd4bb9dd4d4bbb9ddd4bbb9ddd4bbb9ddddbbbb9ddd
-- 143:4dddd9bb4d4dd9bb4dddd9bb4dddd9bb4dddd9bbdddd99bbd4dd9bbbdddd9bbb
-- 150:7eeeeeee97ee8eee777eeeee717eeeee77eeefee737eeeee17ee8e8e7eeeeeee
-- 151:717777977737177e737e77ee77eeeeee717eee8e377feeee77eeeeee77eeeeee
-- 153:b9dddd9b9dddddd99ddddddd9ddddddd9ddddddd9ddddddd99ddf99d1999b1b9
-- 154:b9dddd9b9dddddd9ddddddd9ddddddd9ddddddd9ddddddd9d991dd999b1b9991
-- 155:1bbb9ddd1b1bb999bb1bb1bbbbbbbbbbbbbbbb2b1bfb11bb1b1bbbbb1bbbbbbb
-- 156:d444dd44dddddddd99ddd4dd1b99ddddbbb19191bfb131b1b1bb7bb1b1bbbbbb
-- 157:4dddd444dddddddddd4dddddddddd99d99dd9bb9bb999bbbbbbbbbbbbbbbbbbb
-- 158:44dddd4dddd4ddddddddddddd9999ddd9bfbb9ddb11bbb99bbbb1bbbb7bb1bbb
-- 159:ddddd9bbdd4d91bbdddd91bbddd9bbbbdd9bbb7b99bb2bbbbb1b1bbbbb1bbbbb
-- 166:71777797e737177eee7e77eeeeeeeeeee8eeee8eeeefeeeee8eeeeeeeeeeeeee
-- 167:7eeeeeee17eeee8e737efeee77eeeeee717eeeee777e8eee77eeeeee7eeeeeee
-- 170:bbb1bbbb1b87878717558855b8258e55b78e5588b898558817558852b85be855
-- 171:b1bbb1bb8787871b8852888bb855887b5588558b558e557b8955888b8855887b
-- 172:bbb1bbb1bbb1bbb11bb1bb7711bb77b7bbb77777bbb77797bb117777b1177777
-- 173:bbbb1bb1bbbb1bb1b77777b77777777777777737777777777737777777777777
-- 174:bbb1bbbb7bb1bb1b77bbb1bb7177b1bb777771bb77777b117797b71b7777771b
-- 176:0000000003778558037778550377700003000000030000000300000000000000
-- 177:0000000055585558855585550000000000000000000000000000000000000000
-- 178:0000000055580703855807030000070300000700000003030000030300000000
-- 182:7317773777777377977733337733333377333333777333337973333377733333
-- 183:7317773777377377313333333333333333333333333333333333333333333333
-- 186:b7885588b888558817528e55b8558855b78955b818e855881b787878bbb1bbbb
-- 187:5588528b25e85571c85598e18855b87b55e8558b2588557b7878781bb1bbbb1b
-- 188:b1777777b1b737771b7777771b7777771b777777bb777797bb777777bb177777
-- 189:777977777b77777777777777777771777777777777777779177777777777b777
-- 190:77777bb1777777b1737777b1777777bb777777b1777777b177737b1b7777771b
-- 198:7777333397733333733333337733333377333333973333333773333377333333
-- 199:3333333333333333333333333333333333333333333333333333333333333333
-- 204:b1777777b1797377bbb77777bb177777b11b7717b1bb1b77b1bb1bb7bbbbbbbb
-- 205:77777777777779777777777779777777777777171b7777711bb11bb1bbbbbbbb
-- 206:7777777b777717bb79777bbb7777711b7b77b1b17711bbb1bb1bbbb1bbbbbbbb
-- 208:0000000007333307073333070733330707300000073073330000733307307330
-- 209:0000000033330733333307333333073300000000333073333330733300000000
-- 210:0000000030733330307333303073333000003330333033303330000007307330
-- 220:bbbbbbbbbbbb77b7bb77777717779717bb777777b7777777bb3777771777777b
-- 221:bbbbbbbb77777b77777777777737777777777777777b7777b7777977bbbbbbab
-- 222:bbbbbb117b7b7b1b7977771b777777bb7777377b7777777b777717bbb777777b
-- 224:0730733007307330073073300000733007307330073000000730733007307330
-- 226:0730733007307330073073300730000007307330000073300730733007307330
-- 228:5777777577777777777337777733337773333337777777773777777353333335
-- 229:5777777577777777733333377733337777733777777777773777777353333335
-- 230:5777777577773777777337777733377777733777777737773777777353333335
-- 231:5777777577737777777337777773337777733777777377773777777353333335
-- 232:51111115111bb11111b11b1111b11b1111bbbb1111b11b11b111111b5bbbbbb5
-- 233:5666666566222666662662666622266666266266662226662666666252222225
-- 234:5dddddd5dd4dd4dddd4dd4ddddd44ddddd4dd4dddd4dd4dd4dddddd454444445
-- 235:5cccccc5cc9cc9cccc9cc9ccccc999ccccccc9ccccc99ccc9cccccc959999995
-- 236:b777777bb777777a1b77773b1777777bb7777b1bb779771bb7777771b77777bb
-- 238:b77777bb777777b777777777777977777777717717b77777777773771777777b
-- 240:0730733000007333073073330730733307300000073333070733330700000000
-- 241:0000000033330733333307333333073300000000333073333330733300000000
-- 242:0730733033300000333073303330733000007330307333303073333000000000
-- 244:5555555557777775777777777773377777333377733333377777777757777775
-- 245:5555555557777775777777777333333777333377777337777777777757777775
-- 246:5555555557777775777737777773377777333777777337777777377757777775
-- 247:5555555557777775777377777773377777733377777337777773777757777775
-- 248:5555555551111115111bb11111b11b1111b11b1111bbbb1111b11b1151111115
-- 249:5555555556666665662226666626626666222666662662666622266656666665
-- 250:555555555dddddd5dd4dd4dddd4dd4ddddd44ddddd4dd4dddd4dd4dd5dddddd5
-- 251:555555555cccccc5cc9cc9cccc9cc9ccccc999ccccccc9ccccc99ccc5cccccc5
-- 252:b777777bbb717777b7777777177377771b7717771b711797bbb1b7b7bbbbbbbb
-- 254:1777777b777779bb77777771777777b17173777b771717bb7b17b1bbbbbbbbbb
-- </TILES>

-- <TILES1>
-- 001:3333373333333733333337333333377333333773333337733333377333333773
-- 002:55555555555555555555555555555555555555555555555555555555555ddddd
-- 003:55555555555555555555555555555555555555555555555555555555ddddd555
-- 004:55555555555555555555555555555555555555555555555d55dd45dfddd445df
-- 005:5555555555555555555555555555555555555555dddd5555f4444555f4444455
-- 006:bbbb1bbbb1b1bbb1bbbbbbb1bbbb1bbb1bbbbbbb1bbbbbbb1bb1bbbbbbb1bbb1
-- 008:bb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbb
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
-- 037:1bbbb1bbbbbb1bbbbbbbbbbbb1bbbbbbb1bbbbbbbbbbbbb1bbbbbbbbbb1bbbbb
-- 038:bbbbb733bb1bb733bb1bb733bbbbb733bbbbb333bbb1b333b1bbb733bbbbb733
-- 039:3337333333373333333733333337333333373333333733333337333333373333
-- 040:3333377b333337713333377b3333377b33333771333337773333337733333377
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
-- 054:bbbbb777bbbbb777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 055:7737333377777777bbb7777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 056:3333333777733337b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 058:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 060:5555555e55555555555555555555555555555555555555555555555555555555
-- 061:e7aabbbbeaabbaabeaaaaaaaaaaaaaaa5aaaaaaa5555aaaa5555555a5555555a
-- 062:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 063:bbb85555bbbb8555bbbba855bbbbba85bbbbba85bbbbbba8bbbbbbaabbbbabba
-- 064:3333333333333333337333333373333333773333333733333337333333377333
-- 065:5555d4445555d4445555d4445555d4445555d4445555d4445555444455554444
-- 067:4444444d4444444d4444444d444444d5444444d5444444d54444445544444455
-- 068:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bb1bbbb1b1bbbbbb1
-- 069:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbb1bbbbb
-- 070:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbb1b1bbbbbb1b
-- 071:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbb1bbbbbbb1bbbbbbb
-- 072:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 073:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 074:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb11bbbbb111bbbbbbbb
-- 075:bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb77bbbbb773bbbbb733b1b11b33
-- 077:5555555a5555555a5555555a555555aa555555aa555555aa555555aa555555aa
-- 079:bbbbabbabbbbabbabbbbabbabbbbabbabbbbabbebbbbaabebbbbbaeebbbbbae7
-- 080:3337333333377333333373333337733333377333333773333337733333373333
-- 081:5555444455554444555544445555444455554444555544445555444455554444
-- 083:4444445544444455444444554444445544444455444444554444445544444455
-- 084:bbbbbbbb1bbbbbbbbbbbbbbbbb1bbbbbb1bbbbbbb1bbbbbbbbbbbbbbbbbb1bbb
-- 085:bb1bbbbbbbbbbbbbbbbbbbbbbbbbbbb1111bbbbbbbbbb1bb1bbbbb1b1bbbbb1b
-- 086:bbbbbbbbbbbbbbbbbbb1bbbbbbb1b1bbbbbb1bbbb1bb1bbbbbbbbbbbbbbbbbbb
-- 087:1b1bbbbbbbb1bbbbbbb1bbbb1bbbbbbbb1bbbbbbbbbb1bbbbbb1bbbbbbb1bbbb
-- 088:bbbb1bbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bb1bbbbbbbb
-- 089:bbbbb1bbb1bbbbb1b1bbbbbbbbbbbbbbbbbbbbb1bbb1bbbbbbbbbbbb1bbbbbbb
-- 090:bbbbbb1bbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11bb1bbbb
-- 091:b1bbbbb31bbbbbbbbbbbb1b1b1bbbb1bbb1bbbbbbbbb1bbbbbbbb1bbb1bb1bbb
-- 093:333333aa333333aa333333aa333333aa333333aa333333aa3333333a3333333a
-- 095:bbbbbee7bbbbbe77bbbbbe77bbbbee77bbbbee77bbeee777bbe7e777bbe7e777
-- 097:3333444433334444333344443333444433334444333344443333444433334444
-- 099:4444443344444433444444334444443344444433444444334444443344444433
-- 100:bbbbbbbb1bbbbbbbb1bbbbbbbbbbbbbbbbbb1b11bbbb1bb1bbbb1bbbbbbbbbbb
-- 101:bbbbbbbbbbb1bbbbbbbb1b1bbbbbbbb1bbbbbbbbbbbbb1bbbbbbbb1bbbbbbbbb
-- 102:1bbbbbbb1b1bb1b1bbbb1bbbbbbbbbbbbbb1bbbbbb1bbb1b1bbbbbbbbbbbbbbb
-- 103:1bbbbbbbbbbbb1bbbbbbb1bb1bbbbbbbbbbb1b1bb1bbbbb11bbbbbbbbbbbbbbb
-- 104:1bbbbbbb1b1bbbbbbbbbbbbbb1bbbb1bb1bbb1bbbbb1b1bbbbbbbbbbbbbbbbbb
-- 105:1bbbb1b1bbbbb1b1bbb1bbbbbbb1b1bbbbbb1b1bbbbbbbbb1bbbb1bbb1bbbbbb
-- 106:bbbbbb1bbbbbbbbbb1bbbbbbbb1bbbbbb1bbbbbbbbbbbb1bbbbbb1bbbbbbb1bb
-- 107:b1bbbbbbbbbbbbbbbbbbb1bb1bbbbb1bbb1bbb1bbbbbbb1bbbbbbbbbb1bbbbbb
-- 109:3333333a3333333a3333333a3333333333333333333333333333333333333333
-- 110:abbbbbbbabbbbbbbabbbbbbbaabbbbbb77333333733333337333333373333333
-- 111:bbe7e777bbe7e777bbe7e777bbe7ee7733e77e7733e77e7733e77e7733e77e77
-- 113:3334444433344444333444443333444433334444333344333333373333333733
-- 114:4444444444444444444444444433333333333333333333333333333333333333
-- 115:4444443344333733333377333333773333333733333337333333373333333733
-- 125:3333333333333333333333333333333333333333333333333333333333333333
-- 126:7333333373333333733333337333333373333333733333737333337373333373
-- 127:33e77e7733e77ee733e7777733e7777733e7777733e7777733e7777733e77777
-- 128:5555555555555555555555555555555555555555555555555555555555555555
-- 129:5555555555555555555555555555555555555555555555555555555555555555
-- 130:500000000ddddddd0dd8dddd0d8dd0000dddd0550dddd0550dddd0550dddd055
-- 131:05555555d0000555ddddd055ddddd0550dddd0550dddd0550dddd0550dddd050
-- 132:5555555555555555555555555555555555555555500000550ddddd05dd8dddd0
-- 133:55555555555555555555555555555555555555555500555050dd050d508d050d
-- 134:555555555555555555555005555508d055550dd000550d05dd050d058d050d05
-- 135:55555555555555555555555555500555550dd0555008d0050d8dddd00dddddd0
-- 136:55555555555555505555555055555500555550d8555550dd555550dd555550dd
-- 137:00000000ddddddddd8dddddd8dddddddddd000dddd05550ddd055550dd055555
-- 138:05555555d0555555d0555555dd055555dd055555d05555500555550d555550d8
-- 139:5555555555555555555555555555555555555555000000558ddddd05dddddd05
-- 140:555500555550dd0555508d05550d8d05550ddd05550ddd00508dddd850dddddd
-- 141:5555555555555555555555555555555555555555555555550555555505555555
-- 142:5555555555555555555555555555555555555555555555555555555555555555
-- 143:5555555555555555555555555555555555555555555555555555555555555555
-- 144:5555555555555555555555555555555555555555555555555555555555555555
-- 145:5555555555555555555555555555555555555555555555555555555555555555
-- 146:0dddd0550dddd0550ddd40550444405504444000044444440444448404444444
-- 147:0dddd0500dddd050044dd0500444405044444050444440504444405044440550
-- 148:d8ddddd0ddd00dd0ddd00dd044d00dd0444004d0444004404444444044488440
-- 149:50dd00dd50ddddd050dddd0550dddd0550444d05504444055044440550444405
-- 150:ddd050550dd055550dd055550dd055550d405555044055550440555504405555
-- 151:0dddddd0500dd005550dd055550dd05555044055550440555504400555044440
-- 152:555550dd555550dd555550dd5555504d55555044555550445555504455555500
-- 153:dd055500dd0550d8dd0550ddd405550044055555440055554440000044444444
-- 154:000550ddddd050ddddd050dd0d4050dd0d4050d4044050444440550444055504
-- 155:d00ddd050550ddd0d00d8dd0ddddddd044d44440000000050555555540000055
-- 156:50dddddd550ddd00550dd4055504440555044405550444055504440055504444
-- 157:0555555555555555555555555555555555555555555555550555555505555555
-- 158:5555555555555555555555555555555555555555555555555555555555555555
-- 159:5555555555555555555555555555555555555555555555555555555555555555
-- 160:5555555555555555555555555555555555555555555555555555555555555555
-- 161:5555555555555555555555555555555555555555555555555555555555555555
-- 162:0444444404444444500000005555555555555555555555555555555555555555
-- 163:4440555040005555055555555555555555555555555555555555555555555555
-- 164:44444440044444055000005555555555555555505555550d5555550d5555550d
-- 165:5044440550444405550000555555555500005555dddd055588dd05558ddd0555
-- 166:04405555044055555005555555555555500000050dddddd00d8dddd00d8dddd0
-- 167:555044805550444055550005555555555555500055000ddd50ddddd050d88dd0
-- 168:5555555555555555555555555555555555555555055555555555555555555555
-- 169:0044884400444444550000005555555555555555555555555555555555555555
-- 170:4055550440555504055555505555555555555555555555505555550d5555550d
-- 171:44844405444444050000005555555555500555550dd05555ddd055558dd05555
-- 172:5550444855504444555500005555555555555555555555555555555555555555
-- 173:0555555505555555555555555555555555555555555555555555555555555555
-- 174:5555555555555555555555555555555555555555555555555555555555555555
-- 175:5555555555555555555555555555555555555555555555555555555555555555
-- 176:5555555555555555555555555555555555555555555555555555555555555555
-- 177:5555555555555555555555555555555555555555555555555555555555555555
-- 178:5555555555555555555555555555555555555555555555555555555555555555
-- 179:5555555555555555555555555555555555555555555555555555555555555555
-- 180:5555550d5555550d5555550d5555555055555555555555555555555555555555
-- 181:dddd0555dddd0555dddd055000dd055050dd055050ddd00050ddddd850d4dddd
-- 182:0dddddd00dddddddddddddddddd0ddddddd0dddddd00dddddd00dddddd00dddd
-- 183:50ddddd000ddddd000ddddd000ddddd000ddddd000ddddd0d8dddd05dddddd05
-- 184:5555555555555500555550dd55550d8d55550ddd55550dd05550dd05550dddd0
-- 185:5555555500000055dddddd00dddddddddddddddd000000dd5555550d0000008d
-- 186:5555550d5555000d5550d88d0550dddd0550ddddd050ddddd055000ddd05550d
-- 187:8dd05555ddd00055dddd8d05dddddd05dddddd05dddddd05ddd00055ddd05555
-- 188:5555555555555555555555555555555555555555555555555555555555555555
-- 189:5555555555555555555555555555555555555555555555555555555555555555
-- 190:5555555555555555555555555555555555555555555555555555555555555555
-- 191:5555555555555555555555555555555555555555555555555555555555555555
-- 192:5555555555555555555555555555555555555555555555555555555555555555
-- 193:5555555555555555555555555555555555555555555555555555555555555555
-- 194:5555555555555555555555555555555555555555555555555555555555555555
-- 195:5555555555555555555555555555555555555555555555555555555555555555
-- 196:5555555555555555555555555555555555555555555555555555555555555555
-- 197:504444d450444444504444445504444455044444550444445504444455500000
-- 198:4405000d44055504405555044055550440555504405555504055555005555555
-- 199:4444440544444405444444054444440544444055444440554444405500000555
-- 200:550444dd55044444550444005550440555504400555504445555044455555000
-- 201:ddddd44d44444444000000005555555500000000448844444444444400000000
-- 202:dd05550444055504005555045555550455555504055555040555550455555550
-- 203:44d0555544405555444055554440005544444405444488054444440500000055
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 206:5555555555555555555555555555555555555555555555555555555555555555
-- 207:5555555555555555555555555555555555555555555555555555555555555555
-- 228:5777777577777777777337777733337773333337777777773777777353333335
-- 229:5777777577777777733333377733337777733777777777773777777353333335
-- 230:5777777577773777777337777733377777733777777737773777777353333335
-- 231:5777777577737777777337777773337777733777777377773777777353333335
-- 232:51111115111bb11111b11b1111b11b1111bbbb1111b11b11b111111b5bbbbbb5
-- 233:5666666566222666662662666622266666266266662226662666666252222225
-- 234:5dddddd5dd4dd4dddd4dd4ddddd44ddddd4dd4dddd4dd4dd4dddddd454444445
-- 235:5cccccc5cc9cc9cccc9cc9ccccc999ccccccc9ccccc99ccc9cccccc959999995
-- 244:5555555557777775777777777773377777333377733333377777777757777775
-- 245:5555555557777775777777777333333777333377777337777777777757777775
-- 246:5555555557777775777737777773377777333777777337777777377757777775
-- 247:5555555557777775777377777773377777733377777337777773777757777775
-- 248:5555555551111115111bb11111b11b1111b11b1111bbbb1111b11b1151111115
-- 249:5555555556666665662226666626626666222666662662666622266656666665
-- 250:555555555dddddd5dd4dd4dddd4dd4ddddd44ddddd4dd4dddd4dd4dd5dddddd5
-- 251:555555555cccccc5cc9cc9cccc9cc9ccccc999ccccccc9ccccc99ccc5cccccc5
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
-- 075:000555500cc0550c0c9905090c9c90ce0c9e9c9e0c9eeeee0c9eeeee0c9eeeee
-- 076:00000000cccccccc99999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 077:05000000050ccc9005099c900550ec90e90cec90eeeeec90eeeeec90eeeeec90
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
-- 107:500eeeee5550eeee000eeeee0c9999990c9000000c9055550c9055550c905555
-- 108:eeeeeeeeeeeeeeeeeeeeeeee9999999900000000555555555555555555555555
-- 109:eeeeec90eeeccc90eec99c9099900c9000050c9055550c9055550c9055550c90
-- 110:5555555555555555555555505555550755550073555077075507307350733333
-- 111:5555555555555555005555553305555533055555333055553333055533330555
-- 112:5555500055550fff5550ffff5550fffc550fffce550fccee50fceeee50ff0eee
-- 113:00055555fcc00555ccef0555ceecf0558e8ef0559e9ef055eeeec055eee0cf05
-- 114:550ff000550f026655502666555e2666555ee266555500005550f0555550ff05
-- 115:000cfff06620cff066620ff06662e005662ee55500005555550f0555550ff055
-- 116:50fff00050fc026650c0266655002666555e0266555ee00055550f0555550ff0
-- 117:000cff056620cf0566620055666205556620e555000ee55550f0555550ff0555
-- 118:0fffc0000ffc02660fc02666500e2666555ee26655550000555550f0555550ff
-- 119:000cf0556620f055666205556662e555662ee555000055550f0555550ff05555
-- 120:5555555555555555555555555555555555555555555555555555555555555555
-- 121:5555555555555555555555555555555555555555555555555555555555555555
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:5555555555555555555555555555555555555555555555555555555555555555
-- 125:5555555555555555555555555555555555555555555555555555555555555555
-- 126:5073333350700033500777330773333307333333073333775073373355073733
-- 127:3333305533333305337333303733330537333305333333053333305533333055
-- 128:5555000055550fff5550fffc5550fcce550fce8e550cee9e50fceeee50fc0eee
-- 129:00005555ccf05555eecc0555eeec0555e8ec0555e9ecf055eeeecf05eee0cf05
-- 130:50ffc00050ff02665500266655502666555e0266555e000055550f0555555555
-- 131:000cfff06620cff066620c056662e0556620e5550005555550f0555550f05555
-- 132:50ffc00050fc026650c0266655002666555e0266555e000055550f0555550f05
-- 133:000cff056620c055666205556662e5556620e5550005e55550f0555550f05555
-- 134:0fffc0000ffc026650c0266655002666555e0266555e000055550f0555550f05
-- 135:000cff056620f055666205556662e5556620e5550005555550f0555555555555
-- 136:5505500050600ccc55066666506066665500ccce5550ccee5550eeee55550eee
-- 137:00055555ccc00555cc666055666660558e8e05559e9e0555eeee0555eee05555
-- 138:5555555555555555555555555555555555555555555555555555555555555555
-- 139:5555555555555555555555555555555555555555555555555555555555555555
-- 140:5555555555555555555555555555555555555555555555555555555555555555
-- 141:5555555555555555555555555555555555555555555555555555555555555555
-- 142:5555555555555555555555555555555555555555555555555555555555555555
-- 143:5555555555555555555555555555555555555555555555555555555555555555
-- 144:5555500055550ccc5550cfff5550cfff550cffff550cfcff50cffcff50cffcff
-- 145:00055555ccc05555fffc0555cffc0555cffc0555cfffc055cffcfc05fcfcfc05
-- 146:550cffcf550cffff5550cccc555e0000555e02665555000055550f0555550f05
-- 147:ffcffc05fcfffc05c0cccc05060000556620e5550005e55550f0555555555555
-- 148:550cfcff550cffcf550ccccc55500000555e0266555e000055550f0555550f05
-- 149:ffcfc055ffcfc055cccc05550000e5556620e5550005e55550f0555550f05555
-- 150:50cffcff50cffcff50ccc00c55000260555e0266555e000055550f0555555555
-- 151:fcffcc05ffcc0055cc0005550002e5556620e5550005555550f0555550f05555
-- 152:5505500050600ccc506666cc060666665050ee8e5550ee9e5550eeee55550eee
-- 153:00055555ccc055556666655566666555e8ee0555e9ee0555eeee0555eee05555
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
-- 168:5555500055500ccc55066666550666665550cccc5550eccc5550eecc55550eee
-- 169:00055055ccc006056666660566666060cccc0505ccce0555ccee0555eee05555
-- 170:555550005555026655502666555e2666555ee266555500005550f0555550ff05
-- 171:0005555566205555666205556662e555662ee55500005555550f0555550ff055
-- 172:55555000555502665550266655502666555e0266555ee00055550f0555550ff0
-- 173:000555556620555566620555666205556620e555000ee55550f0555550ff0555
-- 174:555550005555026655502666555e2666555ee26655555000555550f0555550ff
-- 175:0005555566205555666205556662e555662ee555000555550f0555550ff05555
-- 176:0430555004305550040305500403055004030550040305500403055004030550
-- 177:7050705570507055705070557050705570507055705070557050705570507055
-- 178:5507050755070507550705075507050755070507550705075507050755070507
-- 179:0555034005550340055030400550304005503040055030400550304005503040
-- 180:f050f070f0500003f05ccccc05000000050ff070050ff070050ff070050ff070
-- 181:ffffffff00000000cccccccc00000000ffffffffffffffffffffffffffffffff
-- 182:070f050f0000050fccccc50f00000050070ff050070ff050070ff050070ff050
-- 183:5555555555555555555555555555555555555555555555555555555555555555
-- 184:55555000555502065555026e5555026e555550065555500055550f055550ff05
-- 185:0005555566205555e6605555e6605555662055550005555550f0555550ff0555
-- 186:55555000555502665550266655502666555e0266555e000055550f0555555555
-- 187:0005555566205555666205556662e5556620e5550005555550f0555550f05555
-- 188:55555000555502665550266655502666555e0266555e500055550f0555550f05
-- 189:000555556620555566620555666205556620e5550005e55550f0555550f05555
-- 190:555550005555026655502666555e2666555e02665555500055550f0555550f05
-- 191:000555556620555566620555666205556620e5550000e55550f0555555555555
-- 192:040305500403055004003050040030500400300c040030500405555504055555
-- 193:70507055705070557050705570007055cccccc05000000555555555555555555
-- 194:5507050755070507550705075507000750cccccc550000005555555555555555
-- 195:05503040055030400503004005030040c0030040050300405555504055555040
-- 196:050ff070050ff070050ff070050ff070050ff070050ff070050fffff050fffff
-- 197:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 198:070ff050070ff050070ff050070ff050070ff050070ff050fffff050fffff050
-- 199:5555555555555555555555555555555555555555555555555555555555555555
-- 200:55e55000555e02665550266655502666555502665555500055550f0555555005
-- 201:00055e556620e5556662055566620555666055550005555550f0555550055555
-- 202:55555000555502665550266655502666555e0266555e000055550f0555555555
-- 203:0005555566205555666205556662e5556620e5550005555550f0555550f05555
-- 204:55555000555502665550266655502666555e0266555e500055550f0555550f05
-- 205:000555556620555566620555666205556620e5550005e55550f0555550f05555
-- 206:555550005555026655502666555e2666555e02665555500055550f0555550f05
-- 207:000555556620555566620555666205556620e5550000e55550f0555555555555
-- 208:555550005555022655502266555000005550ccee5550ecee5550eeee55550eee
-- 209:000555556620555566620555000000008e8e05553e3e0555eeee0555eee05555
-- 210:5500500050cc022650c0226650c0000000c0ccee0cc0ecee0000eeee55550eee
-- 211:000555556620555566620555000000008e8e05553e3e0555eeee0555eee05555
-- 212:55555000555502265550226655500000550cccee50ccecee50cceeee50000eee
-- 213:000555556620555566620555000000008e8ec0553e3ecc05eeeecc05eee00055
-- 214:555500005550cccc550ccccc50cccccc50ccccce502c6cee550266ee555022ee
-- 215:00005555cccc0555ccccc055cccccc058e8ecc053e3ec605eeee6055eee00555
-- 216:555550005555022655502266555000005550eeee5550eeee5550eeee55550eee
-- 217:000555556620555566620555000000008e8e05553e3e0555eeee0555eee05555
-- 218:555550005555022655502266000000005550ccee5550ecee5550eeee55550eee
-- 219:00055555622055556ee20555000005558e8e05553e3e0555eeee0555eee05555
-- 220:5555500055550ccc5550cccc55500000555033ee5503e7ee5037e37755070337
-- 221:00055555cc805555888c0555000000008e8e05554e4e0555777705557ee05555
-- 222:55555000555503995550ccfc5509999950393cce550ccece50cc0eee55000eee
-- 223:0005555599305555cccc0005999999308e8e00054e4e0555eeee0555eee05555
-- 224:555550005555022655502266555000005550ce8e5550ce3e5550eeee55550eee
-- 225:00055555662055556662055500000555e8ec0555e3ec0555eeee0555eee05555
-- 226:555550005555022655502266555000005550ce8e5550ce3e5550eeee55550eee
-- 227:00055555662055556662055500000555e8ec0555e3ec0555eeee0555eee05555
-- 228:55555000555502265550226655500000550cce8e50ccce3e50cceeee55000eee
-- 229:00055555662055556662055500000555e8ecc055e3eccc05eeeecc05eee00005
-- 230:555500005550cccc550ccccc50cccccc50ccce8e506c6e3e55066eee55502eee
-- 231:00005555cccc0555ccccc055cccccc05e8eccc05e3e6c605eee66055eee20555
-- 232:555550005555022655502266555000005550ee8e5550ee3e5550eeee55550eee
-- 233:00055555662055556662055500000555e8ee0555e3ee0555eeee0555eee05555
-- 234:55555000555502265550226e555000005550ce8e5550ce3e5550eeee55550eee
-- 235:0005555566205555e662055500000555e8ec0555e3ec0555eeee0555eee05555
-- 236:5555500055550cc85550cc885550000055507e8e55507e4e555077775555077e
-- 237:000555558cc0555588cc055500000555e8e70555e4e7055577770555e7705555
-- 238:55555000555503995000cccc039999995039ce8e5507ce4e5550eeee55550eee
-- 239:0005555599305555cccc000599999930e8ec9305e4ec7055eeee0555eee05555
-- 240:555550005555022655502266555000005550cccc5550cccc5550eccc55550ecc
-- 241:00055555662055556662055500000555cccc0555cccc0555ccce0555cce05555
-- 242:55555000555502205550220c5550000c5550cc0c5550cc0c5550ec0c55550ec0
-- 243:0005555506205555c0620555c0000555c0cc05550ccc05550cce0555cce05555
-- 244:55555000555502265550226655500000550ccccc50cccccc50cccccc55000ccc
-- 245:00055555662055556662055500000555ccccc055cccccc05cccccc05ccc00055
-- 246:555500005550cccc550ccccc50cccccc50c6c6c6506666665502262655500222
-- 247:00005555cccc0555ccccc055cccccc05c6c6c605666666052626205522200555
-- 248:555550005555022655502266555000005550eeee5550eeee5550eeee55550eee
-- 249:00055555662055556662055500000555eeee0555eeee0555eeee0555eee05555
-- 250:555550005555022655502266555000005550cccc5550cccc5550eccc55550ecc
-- 251:00055555662055556662055500000555cccc0555cccc0555ccce0555cce05555
-- 252:5555500055550ccc5550ccc75550000055503333555037775550777755550777
-- 253:00055555ccc055557ccc05550000055533330555777305557777055577705555
-- 254:5555500055550399555039995000cc99039999cc500399995550030355550cc9
-- 255:00055555993055559993055599cc0005cc99993099993005303005559cc05555
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
-- 073:5555555555555555555555552222226522222222222222222222222222222222
-- 074:5555555555555555555555555555555565555555655555556555555565555555
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
-- 103:5522222255222225555ee777555ee777555ee775555e7775555e7775555e7775
-- 104:555555ee55555562555556625555566255556622555662225556222255622662
-- 105:7777222222222222222222222222222222222226222222262222222222222222
-- 106:2265555522255555222655552222555522226555622225556622265566222225
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
-- 120:5562262275626622726266227762622277766222777662227777622277776222
-- 121:22222222222222222222222222222226222222ee22222ee72222ee7722eee777
-- 122:2622222626622226266222266677b225e7777555777775557777555577755555
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
-- 138:7265555522655555226555552265555522655555226555552265555522265555
-- 139:5555555555555555555555555555555555555555555555555555555555555555
-- 140:5555555555555555555555555555555555555555555555555555555555555555
-- 141:5555555555555555555555555555555555555555555555555555555555555555
-- 142:5555555555555555555555555555555555555555555555555555555555555555
-- 143:5555ee775555ee775555ee775555ee77555eee77555eee77555ee77755ee7777
-- 144:7777ccee77777ee777777e777777ee777777e7777777e777777ee777777e7777
-- 145:e77ccccc7777cccc7777cccc7777cccc7777cccc7777cccc7c7ccccccccccccc
-- 146:cccccffcccccccfcccccccfccccccccccccccccccccccccccccccccccccccccc
-- 147:ccccc333ccccc333ccccc333ccccc333cccccc33cccccc33cccccc33cccccc33
-- 148:3333333333333333333333333333333333333333333333333333333333333333
-- 149:3333333333333333333333333333333333333333333333333333333333333333
-- 150:3333333333333333333333333333333333333333333333333333333333333333
-- 151:3333333333333333333333333333333333333333333333333333333333333333
-- 152:3337772233372222333622223336222233362222333622223336222233362222
-- 153:2222222222222222222222222222222222222222222222222222222222222222
-- 154:2226333322263333222633332226333322263333222633332226333322263333
-- 155:33333333333333333333333333333333333333333333333333333333333333ff
-- 156:3333333333333333333333333333333333333333333333333333333fffffffff
-- 157:333333333333333333333333333333333333333333333333fffffffecccccccc
-- 158:333333333333333e33333eee3333e77733ee7777eee77777ee777777cccccccc
-- 159:3ee77777ee77777777777777777777777777777777777777777777cccccccccc
-- 160:777e7777777e777c777e777c777e777777777777777777777777777777777777
-- 161:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccc
-- 162:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 163:cccccc33ccccc333ccccc333ccccc333ccccc333ccccc333ccccc333cccc3333
-- 164:3333333333333333333333333333333333333333333333333333333333333333
-- 165:3333333333333333333333333333333333333333333333333333333333333333
-- 166:3333333333333333333333333333333333333333333333333333333333333333
-- 167:3333333333333333333333333333333333333333333333333333333333333333
-- 168:3333622233336222333362223336222233362222333622233336673333333733
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
-- 210:7bbbbbbb7b1bbbbb7bbbbbbb7bbb1bbb7bbb1bbb7bbbbbbb777bbbbb777bbbbb
-- 211:b1bbbbb11bbbbbb11bbb1bbbbb1bbbbbbb1b1bbbb1bbbb1bbbbbbbb1bbbbbbbb
-- 212:bb1bbbbbbbbbbb1bbbb1bb1bbbbbbbbbb1bbb1bbb1bbbbb1bbbbbb1bbbbbbbbb
-- 213:1bbbbbbbb1bb1bbbbbbb1bb1bbb1bbbbbbbbbb1bbbb1bbbbbb1bbbbbbbbb1bbb
-- 214:b1bbbbbbbbbb1bbbbbbb1bbbbbbbbbbb1bbbbbbbbbbbbbb1bbbbbbbbbb1bbbbb
-- 215:bbbb1b1bbbbbb1bbbbbbbbbbb1bbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbb1bbb
-- 216:bbbb773fbbbb73ffbbb773ffbb7773ffb77333ff37733ffc37333ffc373fffcc
-- 217:fcccccccccccccccccccccccccccccccccccccccccccccccccccccc3ccccccc3
-- 218:cccccc33ccc33333cc333333cc333333c3333333333333333333333333333333
-- 219:3333333333333333333333333333333333333333333333333333333333333333
-- 220:3333333333333333333333333333333333333333333333333333333333333333
-- 221:3333333333333333333333333333333333333333333333333333333333333333
-- 222:3333333333333333333333333333333333333333333333333333333333333333
-- 223:3333333333333333333333333333333333333333333333333333333333333333
-- 224:bee77777bbee7777bbbe7777bbbee777bbbbe777bb1bee77bb1bbe77bbbbbee7
-- 225:7777777777777777777777777777777777777777777777777777777777777777
-- 226:777bbb1b7777bbb17777bb1b7777bbbb77777bbb77777bbb77777bbb777777bb
-- 227:bbbbbbbbbbb1bbbbbbb1bbb1bbbbbb1b1bbbbb1bbbbbbbbbbb1bbbbbbbb1bbbb
-- 228:bbbbbbbbbb1bbbb1bbbbbbb1bbbb1b1bbbb1bbbbbbbbb1b1bbbbbbbb1bbbbbbb
-- 229:bbbbbbbbbbb1bbb1b1b1bbb1b1bbbbbbbb1bbbbbbbbbbbbbbbb1b1bbbb1b1b1b
-- 230:bbb1bbb1bbbbbbb1bb1bbbb11bbbbbbbb1bbbbbbbbbbb1bbbbbb1bbbbbbb1bb1
-- 231:bbbb1bbbb1bbbbbbbbbbb1bbbbbbbbbbb1bbbbb1bbbbbb1bbbb1bbbbbb1bb1bb
-- 232:333ffcccb3ffccccbbffccccbffcccccbffcccccffccccccffccccccffcccccc
-- 233:cccccc33cccccc33ccccc333cccc3333cccc3333ccc33333cc333333cc333333
-- 234:3333333333333333333333333333333333333333333333333333333333333333
-- 235:3333333333333333333333333333333333333333333333333333333333333333
-- 236:3333333333333333333333333333333333333333333333333333333333333333
-- 237:3333333333333333333333333333333333333333333333333333333333333333
-- 238:3333333333333333333333333333333333333333333333333333333333333333
-- 239:3333333333333333333333333333333333333333333333333333333333333333
-- 240:bbbbbbe7bbb1bbeebbbbbbeebbbbbb1ebbbbb1bebbbbb1bebbbbbbbbbbbbbb1b
-- 241:7777777777777777777777777777777777777777e7777777ee777777ee777777
-- 242:777777bb777777bb7777777b7777777b77777777777777777777777777777777
-- 243:bb1bbbb11bbbb1bb1bbbbb1bbbbb1bbbbbb1bbbb7bbb1bbb1bbbbb1b71bbbbb1
-- 244:b1bbbb1b1bbbbb1bbbb1bbbbbbbbbb1bbbbb1bb1bbbbb1bb1b1bb1bbbb1bbbbb
-- 245:b1bb1b1bbbbbbbbbb1bbbbbbbb1bbb1bb1bbb1bbbb1bbbbb1bbbbbb11bbbb1b1
-- 246:bb1bbbbbb1bbbb1bbb1bbb1bbbbbbbbb1bbbbbbbbbbbb1bbbbbb1bbbbb1bbbbb
-- 247:bb1bbbbbbbbbbbbfbbbb1bbfb1bbbbffbbbbbbffb1bbbbffbb1bbffcbbbbbffc
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
-- 013:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000db32d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ea72e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ea82e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d1d1d1d1d1d1d1d1d1d2fa80f1d1d1d1d1d1d1d1d1d1d1d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646878696869686968696a94646464646585846464646460f2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646a7464646464646464646464646464646464646464646070f1d1d1d1d1d1d1d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646954646464646464646464646464646464646464646460777dbdbdbdbdbdbdb2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d1d1d1d2f4646a746460d1d1d1d1d1d1d1d1d1d1d1d1d1d2dcadddddddddddb08080808dbdb2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:000000000000000000000000000000000000000000000000000000000000000000000000000000002e46464646464646a846460e000000000000000000000000002eeb4846464677dbdbdbdbdbdbdb2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646b6d6e6c6d5e6f60e000000000000000000000000002eeb4646464646dbdbdbdbdbdbdb2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646b73333333333f70f1f1f1f1f1f1f1f1f1d1d1d2d002eeb4646464677db6b7b7b7b7b7b2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:000000000000000000000000000000000000000000000000000000000000000000000000000000002e464646b9e9c5e9d9e9f94646464646464646464646370e002eeb4646464646db6c7c7c7c56662e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646464646a7464646464607464607464607464607460e002eeb4646464677db6c7c7c7c7c7c2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646464646a8464646464646464646464646464646460e002eeb4646464646db6c7c7c7c7c7c2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:000000000000000000000000000000000000000000000000000000000000000000000000000000002e4646464646a7464646460d1d1d1d1d1d1d1d1d2d46460e002eeb4646464677db6c7c7c7c55652e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:0000000000000000000000000000000d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d2f4617171746a8464646462e00000000000000000e46460e002eeb4646464646db6c7c7c7c56662e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:0000000000000000000000000000000e6868686868687746464646464648463777777777464646464646464646469986a646460f1f1f1f1f1f1f1f1f2f46460f1f2feb4646464677db6c7c7c7c7c7c2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:0000000000000000000000000000000edbdbdbdbdbeb774646464646464646464646464646cadaea464646464646464699a6464646464646464646464646464646caec4646460d1f1f0b1b1b1b2b1f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:0000000000000000000000000000000edbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbddddddddddea464646a8460746464608080808080846464646ee464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:0000000000000000000000000000000edcdcdcdcdcec774646585846464646462727272746cbdbeb0746464646ee464646a7464646464646464677464646464646ee464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:0000000000000000000000000000000e777777777777774646464646464646464646464646ccdbec4646464646ee465746a8464646464646464646774646464646ee464658580e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:0000000000000000000000000000000e77777777464646464646460d1d1d1d1f1f1f1f1f2d46ce464646464647ee464646a84646cadadadadadadadadadadadadaec46460d1f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000000000000000000000000000000e77377746464646464646460e00000000000000002e46ce464646464646ee465746998696a596a6464646464646464646464646460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:0000000000000000000000000000000e77777746464646464646460e00000000000000002e46ce464607464646ccddddddddddddec4697464646464646464646464646460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:0000000000000000000000000000000f1d1d1d1d1d2d46464646460e00000000000000002e46ce46464646464646464646464646464698464646465746574627272727460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:0000000000000000000000000000000000000000002e46464646460f1d1d2d00000000002ecdeedded46464646464646464646b6c6d6d5e6f646464646464646464646460e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:00000000000000000000000000000000000d1f1f1f2f46464646464646460e00000000002ece7777ce46464646464646464646b833333333f7460d1f1f1f1f1f1f1f1f1f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:000000000000000000000000000000000d2f4646464646464646464658580e00000000002ece7777ce46464646464646aaba46b733333333f8460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000d2f464646464607464646074646460e00000000002ecfeeddef48464646464646abbb46b833333333f8460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000000000000000000000d2f46464646464646464646374646460e00000000002e46ce464646464646464646464646b9c9e9d9e9f9460e000d1d1d1d1d1d1d1d71333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000d2f4646464646464646464646464646460e00000000002e46ce464646464646774646464646464646464646460e002e68686868db7a7333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000000000000000000e46464646474646464646b6d6e6f646460e00000000002e46ce464646774646464677464646464646464646460f1f2fdbdbdbdbdb7a7433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000e46574646464646467777b83333f746460e00000000002e07ce07464646464646464646464646464646464646cbdbdbdb796a6a6a447333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:000000000000000000000000000e46464646464646467777b9c9d9f946460e00000000002e46ce46464646467746464646464646272727274647cb7a6a6a44444444447433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:000000000000000000000000000e464646464646464646464646484646460e00000000002e46ce17171746464646464646465746464646464646cb7a444444444444447333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:000000000000000000000000000e464646464618181818184646464646460e00000000002e46ce46464646464646464646464646464646464646cb7a444444444444447433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000e46464646b6c6d6e6c6d6f646464646460e00000000002e46ce4646464646460d1d1d1d1d1d2d484646464646cb7a444444444444447333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000d1f1f2f46464646b83333333333b586968696a60e00000000002e46eedddddddded460e00000000002e464646464646cb7a444444444444447433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:00000000000000000000e386968696a59686e53333333333f877777777a70e00000000002e46ceb6d6d6f6ce460e00000000002e464646464646cb7a444444444444447333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:000000000000000000000f1f1f2d464646460d1d1d1d1d1d2d46aaba77a80e00000000002e46ceb83333f7ce460e00000000002e464646464646cb7a444444444444447433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:000000000000000000000000000e464646070e00000000002e46abbb77a70e00000000002e46ceb83333f8ce460e00000000002e374646464646cb7a444444444444447333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:000000000000000000000000000e464646460e00000000002e46464677a80e00000000002e46ceb83333f7ce460e00000000002e464646464646cb7a444444444444447433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:000000000000000000000000000e464607460e00000d1f1f2f46464677a70e00000000002e46ceb9c9d9f9ce460e00000d1d1d2f464646464646cc7a444444444444447433333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:000000000000000000000000000e464646460e00000e46464646464677a80e00000000002e46ce77585807ce460e00002e0777484646464646460d1d0f1f1f1f1f1f1f1d71333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:000000000000000000000000000e464646070f1f1f2f46574646464677a70f1f1f1f1f1f2f46eeddddddddeb460e00002e7777464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 058:000000000000000000000000000e464646464646464646464646878696a946464646464646464646464646ce460f1f1f2f7746464646464646460e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:000000000000000000000000000e464646464646464646464646a746464646464646464646464646464646ce46777777777746464646464646460f1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:000000000000000000000000000e464646464646464646464646a846464646464646464646464646464646ce4646464646464646464646464646777746464646464646464646464646772e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:000000000000000000000000000f2d464646464646464646b6c6d5e6f64646464646464646464646464646ce4646464646464646464646464646464618181818184646464608080846772e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:00000000000000000000000000000f2d4646464646464646b7333333f74646464646464657464646464646ce4646464646464646464646464646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:0000000000000000000000000000000f2d46464646464646b8333333f84646464646464646464646464646ccdddddddddddddddddddddddddddddddddddddadadadadadadadadadadaea2e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:000000000000000000000000000000000f2d464677464646b9c9d9e9f94646465858464646464646464646464646467746464646464607374646464646460727272727464646464648eb2e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:00000000000000000000000000000000000f1f1f1f2d46464646464646460d1d1d1d1d1d2d4646464646464646464607774646464646464646467777464646464646464646dcdcdcdcec2e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:0000000000000000000000000000000000000000002e46464646464646460e00000000002e464646464646464646464646464646464646464646777746464646464646464646171717462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:0000000000000000000000000000000000000000002e46464646464646460f2d000000002e464646460746464646464646464646464646464646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:0000000000000000000000000000000000000000002e4646464646464677770f2d0000002e4646464646464646464646464646460d1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d77770d1f1f1f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 069:0000000000000000000000000000000000000000002e464646464646467777370f2d00002e4646464646464646464646464646460e00000000000000000000000000002e46462e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:0000000000000000000000000000000000000000002e46464646464646464677770f1f1f2f464646464646464646aaba464646460f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2f77770f1f1f1f2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:0000000000000000000000000000000000000000002e464646464646464646777746464646464646464646464646abbb46464646464646464646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:0000000000000000000000000000000000000000000f2d4646074646464646464646464646464646464646464646464646464646467777464657464646464646464646464646464646482e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:000000000000000000000000000000000000000000000f2d46464646464646464646464646464646464646464646464646464646464646464646464646460808080846464646460746462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:00000000000000000000000000000000000000000000000f2d464646464646464646464646464646465746464646464646464646272727274646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000000000000000000000000000000000000000000000000f2d4646464646464646464646464646464646464646464646464646464646464646464646464646464646464646474646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:000000000000000000000000000000000000000000000000000f2d46464646464646464646464646464646464646181818181846464646464646464646464646464646464646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 077:00000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1d1d1d2d464646464646464646464646464646460d1d2d464646460d1d1d2d4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 078:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000eb6d6e6f60e00002eb6d6e6f646460f1f2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 079:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464646464646464646460e000eb73333f70e00002eb73333b5a5868696c300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 080:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646b6c6c6e6f646464646460e000eb83333f80e00002eb73333f846460d1d2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 081:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646b8333333f746464646460e000eb9c9c5f90f1f1f2fb83333f746462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 082:000000000000000000000000000000000000000000000000000000000000000000000000000000000e461717174646b9c9c5e9f946464646460e000e4846998686968696e53333f846462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 083:000000000000000000000000000000000000000000000000000000000000000000000000000000000e4646464646464646a7585846464646460e000e4646464677777777b9c9e9f946462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 084:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646464695464646464646460e000e46574657464677774646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000000000000000000000000e4646464646464646a8464646464646460e000e464646460d1d1d2d4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646b6c6d5e6f646464646460e000e464646460e00000e4646465746462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646464646b7333333f746464646460e000f1f1f1f1f2f00000e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646878696e5333333f846464646460e0000000000000000000e4646aaba46462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646a84646b9c9d9e9f946464646460e0000000000000000000e4646abbb46462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 090:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646a74646272727274646464646460e0000000000000000000e4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 091:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646a84646464646464646464646460f1d1d1d1d1d1d1d1d1d2f4646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000000000000000000000000000000e4646469546464637464646464646464677777777777777777777774646464637462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:000000000000000000000000000000000000000000000000000000000000000000000000000000000e464646a846464646464646460746074677777777773777777777774646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:000000000000000000000000000000000000000000000000000000000000000000000000000000000e465858a746464646464646464646464677777777777777777758584646464646462e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:000000000000000000000000000000000000000000000000000000000000000000000000000000000f1f1f2da80d1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 096:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ea72e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 097:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ea82e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fd32f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 010:d7162336d7d7d7d7d7d7d7d5e3f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:d7172737d7d7d7d7d7d7d7d6e6f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d7020410d7d7d7d7d7d7d7d7e7f700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d7030511d7d7d7d7d7d7d7d7a0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:52627282445464748494a4b4a1b100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:53637383455565758595a5b5a2b200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:6080a3a2465666768696a6b6a3e300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP1>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0023456789abcdffffdcba9876543200
-- 002:0123456789abcdef0123456789abcdef
-- 004:02469a96786777890b6c861204a257e9
-- 005:0000ffffffffffff0000ffffffffffff
-- 007:000112358acdeefffffeedb853211000
-- 008:0122234689bceffffeddcb9875432100
-- </WAVES>

-- <SFX>
-- 001:d600e600e600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600f600600000000000
-- 002:6000607060c060e060c06040600060006000600060007000700070008000900090009000a000a000b000b000c000c000d000e000e000e000f000f000362000000600
-- 018:05006505a500f500f5006500b505f500f500c500e505f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c72000000000
-- 019:05096500a500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c72000000000
-- 020:0500650a9508f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c62000000000
-- 021:670d970da70dc70da70f87006702470337041705070607060706f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700a17000000000
-- 022:0107010701070107110711071107110621052104210331033102410141015100510f610e610e710d710c810b810b910a9109a109b108c108e108f108b29000000000
-- 023:6300d300c300e300c300e300d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300672000000000
-- 024:1407240644046400a40de40af408f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400b79000000000
-- 025:42098209a209e209f200f200320b720bc20be20bf200f200120d620da20de20df200f200220f520f920fe20ff200f200020032007200e200f200f200c12000000000
-- 026:040704070406040604050405040514041404140424032403340244014401540f640f740e840d940da40cb40cc40bd40ad409f408f400f400f400f400402000000000
-- 027:02000202020302050207020602040201020c020a0209020a020c020f0200020002000200020002000200020002000200020002000200020002000200b0200000000f
-- 048:01000100210041006100a100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100200000000000
-- 049:040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400402000000000
-- 050:80007000700070007000800090009000a000b000d000e000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 051:61004100410041005100610071008100a100a100a100b100b100b100b100b100b100b100b100b100b100c100c100d100e100f100f100f100f100f100202000000000
-- 052:e000d000d000d000d000e000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000300000000000
-- 053:d100c100c100c100c100c100d100d100d100e100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100202000000000
-- 054:3100110001000100010001001100110011002100210031004100510061007100810081009100a100a100910081007100610061007100810081008100470000ff0000
-- 055:700070007000800080008000900090009000a000a000a000a000b000b000c000c000c000d000d000d000d000e000e000e000e000e000f000f000f000464000000000
-- 056:23008300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300400000000000
-- 057:23008300a300c300d300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300600000000000
-- 058:4300a301b301b302c302c302c303c303d304d304e305e305f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300600000000000
-- 059:4407070717053704470467039703b702c701d700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700f700802000000000
-- 060:030003001300430083009300a300a300b300b300b300b300b300b300b300b300b300b300b300c300c300c300c300d300d300d300e300e300e300f300529000000000
-- </SFX>

-- <PATTERNS>
-- 000:688907100811d00807100811600807100811d00807100811600807100811d00807100811600807d00807400809100801600807100801d00807100801600807100801d00807100801600807100801d00807100801600807100801d00807100801600807100801d00807100801600807d00807400809600809600807100801d00807100801600807100801d00807100801600807100801d00807100801400807100801d00807100801600807100801d00807100801600807100801d00807100801
-- 001:08810080088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000060088b00000040088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000040088b60088b80088b00000000000040088b00000000000000000000000040088b00000000000060088b00000000000000000000000040088b00000000000040088b00000000000000000000000070088b00000000000040088bd0088900000050088b
-- 002:002c11086911a00817100811d00817f00817d00817100811600817100811000000000000100811000000600819100811000000000000400819f00817400819100811d00817100811000000000000000000000000000000000000b00817a00817b00817100811a00817100811d00817f00817d00817100811a00817100811600817400817100811000811800817100811a00817100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:002c1106891160081b10081140081bf0081940081b100811a00819100811000000000000a0081b10081160081b100811000000000000a00819800819a00819100811b0081910081100000000000000000000000000000000000040081bf00819d0081910081160081b10081140081bd00819f0081910081140081b100811f00819d0081910081100081140081b100811d00819100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:688925100000d00825600845600827d00845800827600847100000800847d00825100000b00827d00845a00827b00847600827a00847d00825600847600825d00845d00825600845600827d00845800827600847100000800847d00825100000b00827d00845d00827b00847a00827d00847100000a00847600827100000100000600847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:644935000831600837000831d00835000831b00835000831000831000000f00835000831b00835000831a00835000831b00835000831d00835000831600835000831600837000831b00835000831d00835000831000831000000600837000831600835000831600837000831b00835000831d00835000831600837000831800837000831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:04410000000040089d00000000000000000000000000000090089d00000000000000000000000000000040089d00000090089d0000008008ad00000000000000000060089d00000000000000000000000000000090089d00000000000000000000000000000090089d00000090089d00000090089d0000009008ad000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:f88923000000a00825f00843600827a00845800827600847000841800847f00825000000a00827f00845000821a00847800827000841500006800847f00823500847a00825f00843600827a00845800827600847000000800847f00825000000600827f00845b00827600847a00827b00847000000a00847500827000000f00825500847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:b88923000000600825b00843d00825600845a00827d00845000841a00847d00825000000b00825d00845600827b00845800827600847a00827800847b00823a00847600825b00843600827600845a00827600847000000a00847d00825000000800827d00845d00827800847a00827d00847000000a00847600827000000000821600847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:d88923000000800825d00843600827800845800827600847000000800847600827000000d00825600847800825d00845f00825800845600827f00845d00823000000500827d00843600827500847800827600847000000800847d00825000000500827d00845f00827500847d00827f00847000000d00847a00827000000800827a00847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:f44933000000f00835000000800835000000a00835000000000831000000d00835000000800835000000700835000000800835000000a00835000000f00833000000f00835000000800835000000a00835000000000000000000f00835000000500837000000500835000000800835000000a00835000000d00835000000500837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:644935000000b00835000000a00835000000f00835000000000000000000d00835000000b00835000000600835000000600837000000f00835000000b00835000000f00833000000600835000000f00835000000000000000000d00835000000b00835000000600835000000f00835000000b00835000831400837000000600837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:844935000000500835000000800835000000d00835000000000000000000f00835000000500837000000d00835000000800837000000f00835000000d00835000000800835000000d00835000000800837000000000000000000f00835000000d00835000000a00837000000800837000000f00835000000d00835000000800837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:6449b100000080089d0000000000000008b100000000000080089d00000000000000000000000000000080088d00000080089d000000d008cd0000006008b1000000a0089d000000000000000000000000000000a0089d0000000000000000007008b1000000a0088d000000c0089d000000b008ad0000009008cd0000008008b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:6889b1000000a0089d0000007008b1000000a008ab000000a008cb000000c0089fb0089f6008b10000000000000000004008b1000000b008cb0000007008b1000000d0089d0000006008b1000000e008ad000000d0089f000000b008cb000000c0088d0000009008b1000000e008ad0000008008b1000000a008c90000005008b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:6889b1b0089de0089fc008af6008b10008c1a008c9000000b0088dd0088b4008b1e0088da008b1c0089de008af0000006008b10008c1b008c98008c96008b1c0088fe008ad0000006008b1e0088f9008c70000006008b1c0089db008c9a008c7e008af0000006008b1000000b008c96008b1d008c99008cb0000006008b1b0088de0088f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:688935600857600835600857600835600855600835600837600835600857600835600857b00835b00857b00835b00857d00835d00857d00835d00837600835600857600835600857600835600855600835600837600835600857600835600857b00835b00857b00835b00857d00835d00857d00835d00837800835800857800835800837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:f88933f00855f00833f00855f00833f00853f00833f00835f00833f00855f00833f00855800835800857800835800857a00835a00857a00835a00837f00833f00855f00833f00855f00833f00853f00833f00835f00833f00855f00833f00855800835800857800835800857a00835a00857a00835a00837500835500857500835500837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:b88935b00857b00835b00857b00835b00855b00835b00837b00835b00857b00835b00857400835400857400835400857600835600857600835600837b00835b00857b00835b00857b00835b00855b00835b00837b00835b00857b00835b00857400835400857400835400857600835600857600835600837800835800857800835800837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:d88933d00855d00833d00855d00833d00853d00833d00835d00833d00855d00833d00855600835600857600835600857800835800857800835800837d00833d00855d00833d00855d00833d00853d00833d00835d00833d00855d00833d00855600835600857600835600857800835800857800835800837a00835a00857600835600837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000d00869000000b00869000000a54e69000000000000000000000861000000100861000000b00869a00869600869000861854e69000861100861000000d00869000000b00869000000a54e69000000000000000000000000000000100861000000500869000000600869000000d54e69000000000861000000100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:f88923000000a00825f00843600827a00845800827600847000841800847f00825000000a00827f00845000821a00847800827000841500006800847b00823a00847600825b00843600827600845a00827600847000000a00847d00825000000800827d00845d00827800847a00827d00847000000a00847600827000000000821600847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:f44933000000f00835000000800835000000a00835000000000831000000d00835000000800835000000700835000000800835000000a00835000000b00835000000f00833000000600835000000f00835000000000000000000d00835000000b00835000000600835000000f00835000000b00835000831400837000000600837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:d88923000000800825d00843600827800845800827600847000000800847600827000000d00825600847800825d00845f00825800845600827f00845b00823a00847600825b00843600827600845a00827600847000000a00847d00825000000800827d00845d00827800847a00827d00847000000a00847600827000000000821600847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:844935000000500835000000800835000000d00835000000000000000000f00835000000500837000000d00835000000800837000000f00835000000b00835000000f00833000000600835000000f00835000000000000000000d00835000000b00835000000600835000000f00835000000b00835000831400837000000600837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:d88923000000800825d00843600827800845800827600847000841800847f00825000000a00827f00845000821a00847800827000841500006800847f00823500847a00825f00843600827a00845800827600847000000800847f00825000000500827d00845f00827500847d00827f00847000000d00847a00827000000800827a00847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:844935000000500835000000800835000000d00835000000000831000000d00835000000800835000000700835000000800835000000a00835000000b00835000000f00833000000600835000000f00835000000000000000000d00835000000d00835000000a00837000000800837000000f00835000000d00835000000800837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:a00825000000500825a00845d00825500845500827d00845000000500847d00825000000600827d00845500827600847d00825500847a00825d00845b00823a00845600825b00843600827600845a00827600847000000a00847d00825000000800827d00845d00827800847a00827d00847000000a00847600827000000000821600847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:500837000000d00835000000a00835000000500835000000000000000000500837000000d00835000000a00835000000600837000000f00835000000b00835000000f00833000000600835000000f00835000000000000000000d00835000000b00835000000600835000000f00835000000b00835000831400837000000600837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:800825000000f00825800847600827f00845800827600847000000800847500827000000d00825500847800825d00845f00825800845600827f00845d00823600847500827d00843600827500847800827600847000000800847d00825000000500827d00845f00827500847d00827f00847000000d00847a00827000000800827a00847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:b00835000000800835000000f00835000000600837000000000831000000d00835000000b00835000000800835000000600835000000f00835000000d00835000000800835000000d00835000000800837000000000000000000f00835000000d00835000000a00837000000800837000000f00835000000d00835000000800837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:f88933f00855f00833f00855f00833f00853f00833f00835f00833f00855f00833f00855800835800857800835800857a00835a00857a00835a00837b00835b00857b00835b00857b00835b00855b00835b00837b00835b00857b00835b00857400835400857400835400857600835600857600835600837800835800857800835800837000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:6f4929000000600849600829600829800829a00829800849a00849d00829000821d00849653e7b000871000821000000000821000000000000000000000000000000000000000000000000000000000000000871000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:6ff935000000600855800835600835800835a00835800835600835d00835600855d00855653e670ee9710cc9210aa100088921066100044100022100100961000000000000000000000000000000000000000871000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:a4f929000000a00849d00829b00829d00829f00829b00879f0087950082bd00879b0087ba53e7b000871000821000000000821000000000000000000000000000000000000000000000000000000000000100821000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:688907100811b00807100811600807100811b00807100811600807100811b00807100811600807b00807f00807100801600807100801b00807100801600807b00807f00807400809600807100801b00807100801600807100801b00807100801600807100801d00807100801600807100801d00807100801600807d00807400809600809600807100801d00807100801600807100801d00807100801600807100801d00807100801600807100801d00807100801400809d00807a00807600807
-- 036:888907100811d00807100811800807100811d00807100811800807100811d00807100811800807d00807500809600809500807100801d00807100801500807100801d00807400809800807100801d00807100801500807100801d00807100801600807100801d00807100801600807100801d00807100801600807d00807400809600809600807100801d00807100801600807100801d00807100801600807100801d00807100801600807100801d00807a00807400809600809a00807800807
-- 037:002c11086911800817100811b00817d00817b00817100811d00815100811000000000000100811000000800819100811000000000000f00817d00817f00817100811500819100811000000000000000000000000000000000000800817a00817b00817100811a00817100811d00817f00817d00817100811a00817100811600817400817100811000811800817100811a00817100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:002c1106891180081b10081150081b40081b50081b100811d0081910081100000000000080081b100811b0081b100811000000000000b00819a00819b0081910081180081910081100000000000000000000000000000000000040081bf00819d0081910081160081b10081140081bd00819f0081910081140081b100811f00819d0081910081100081140081b100811d00819100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:002c11086911b00817100811d00817f00817d00817100811b00817100811000000000000100811000000600819100811000000000000400819f00817400819100811d00817100811000000000000000000000000000000000000b00817a00817b00817100811a00817100811d00817f00817d00817100811a00817100811600817400817100811000811800817100811a00817100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:002c1106891160081b10081160081b80081960081b100811f0081910081100000000000040081b10081160081b10081100000000000040081bf0081940081b100811b00819100811000000000000000000000000000000000000b00819800819a0081910081160081b10081140081bd00819f0081910081140081b10081160081bd0081910081100081140081b100811d00819100811000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:6889b380088bd008ad000000a008c90000000000000000006008b350088b000000d0089d8008c90000006008b360088b6008b340088be0089dc0088bb008c90000000000000000006008b350088b9008c900000040088bd0089d00000040088b6008b380088b90089d000000b008cb0000000000000000006008b340088bd008c900000060088b000000000000d008b36008b340088be008ad000000c008c98008c90000000000006008b370088bd008ad00000040088bd0089d6008b3b0088b
-- 042:6889b380088bd008ad000000a008c90000000000000000006008b350088b000000d0089d8008c90000006008b360088b6008b340088be0089dc0088bb008c90000000000000000006008b350088b9008c900000040088bd0089d00000040088b6008b380088b90089d000000b008cb0000000000000000006008b340088bd008c900000060088b000000000000d008b36008b340088be008ad000000c008c980089da0088b0000006008b370088bd008ad00000040088bc0089d9008c97008c9
-- 043:08810080088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000060088b00000040088b00000000000040088b00000000000000000000000050088b00000000000040088b00000000000040088b60088b80088b00000000000040088b00000000000000000000000040088b00000000000060088b00000000000000000000000040088b00000000000040088b00000000000000000060088b70089dd0089da0088b9008c980088b6008b3000881
-- </PATTERNS>

-- <TRACKS>
-- 000:30124086a2096e9c69301a6086aa296e9b69000000000000000000000000000000000000000000000000000000000000000000
-- 001:581000581000a43700581700581e006d5e00581e006d5e00856f00ad6f00c57f00ed7f000000000000000000000000001f4100
-- 002:5440106180100000000000000000000000000000000000000000000000000000000000000000000000000000000000001f4100
-- 003:1a83200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f4200
-- </TRACKS>

-- <FLAGS>
-- 000:00003060306032620000000000000000000000000010001000000000000000000808080010020203010000000000000008080800000202030300001010101000000000000002020300000000000000000000000000000000000000010101010000000000000000000101010101010101101010101010101001010101000000011010000000000000000101010000000110101000000002060001010101010101101010101010060200000000000000000000000000100404000000000004000000000000001000100010000000040000b0b0b000000010100000000000000000b000b000000000000000000000000000b0b0b000000000000000000000000000
-- </FLAGS>

-- <SCREEN>
-- 000:5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555fffcccccccccccccccccccc
-- 001:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555fffccccccccccccccccccccc
-- 002:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccc
-- 003:55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccc
-- 004:55555555555555555555555555555555555555555555555555555555555555555000000005555555555555555555555555555555555555555555555500000000055555555555555555550055555555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccc
-- 005:55555555555555555555555555555555555555555555555555555555555555550dddddddd00005555555555555555555555555555555555555555550ddddddddd0555555555555555550dd055555555555555555555555555555555555555555555555555555555555555fffcccccccccccccccccccccccc
-- 006:55555555555555555555555555555555555555555555555555555555555555550dd8ddddddddd0555555555555555555555550055555555555555550d8ddddddd05555555555555555508d055555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccc
-- 007:55555555555555555555555555555555555555555555555555555555555555550d8dd000ddddd0555555555555555555555508d055500555555555008ddddddddd05555555555555550d8d055555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccc
-- 008:55555555555555555555555555555555555555555555555555555555555555550dddd0550dddd055555555555555555555550dd0550dd055555550d8ddd000dddd05555555555555550ddd05555555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 009:55555555555555555555555555555555555555555555555555555555555555550dddd0550dddd055500000555500555000550d055008d005555550dddd05550dd055555000000055550ddd00555555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 010:55555555555555555555555555555555555555555555555555555555555555550dddd0550dddd0550ddddd0550dd050ddd050d050d8dddd0555550dddd0555500555550d8ddddd05508dddd8055555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 011:55555555555555555555555555555555555555555555555555555555555555550dddd0550dddd050dd8dddd0508d050d8d050d050dddddd0555550dddd055555555550d8dddddd0550dddddd055555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 012:55555555555555555555555555555555555555555555555555555555555555550dddd0550dddd050d8ddddd050dd00ddddd050550dddddd0555550dddd055500000550ddd00ddd0550dddddd055555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 013:55555555555555555555555555555555555555555555555555555555555555550dddd0550dddd050ddd00dd050ddddd00dd05555500dd005555550dddd0550d8ddd050dd0550ddd0550ddd00555555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 014:55555555555555555555555555555555555555555555555555555555555555550ddd4055044dd050ddd00dd050dddd050dd05555550dd055555550dddd0550ddddd050ddd00d8dd0550dd405555555555555555555555555555555555555555555555555555555555555ffcccccccccccccccccccccccccc
-- 015:5555555555555555555555555555555555555555555555555555555555555555044440550444405044d00dd050dddd050dd05555550dd0555555504dd40555000d4050ddddddddd05504440555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 016:55555555555555555555555555555555555555555555555555555555555555550444400044444050444004d050444d050d4055555504405555555044440555550d4050d444d444405504440555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 017:5555555555555555555555555555555555555555555555555555555555555555044444444444405044400440504444050440555555044055555550444400555504405044000000055504440555555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 018:5555555555555555555555555555555555555555555555555555555555555555044444844444405044444440504444050440555555044005555550444440000044405504055555555504440005555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 019:5555555555555555555555555555555555555555555555555555555555555555044444444444055044488440504444050440555555044440555555004444444444055504400000555550444405555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 020:5555555555555555555555555555555555555555555555555555555555555555044444444440555044444440504444050440555555504480555555550044884440555504448444055550444805555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 021:5555555555555555555555555555555555555555555555555555555555555555044444444000555504444405504444050440555555504440555555550044444440555504444444055550444405555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 022:5555555555555555555555555555555555555555555555555555555555555555500000000555555550000055550000555005555555550005555555555500000005555550000000555555000055555555555555555555555555555555555555555555555555555555555ffccccccccccccccccccccccccccc
-- 023:55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555fffcccccccccccccccccccccccccccc
-- 024:5555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000055555000000555555000555555555555555555555555500555555555555555555555555555555555555555555555fffffffffffffffffffffffffccccccccccccccccccccccccccccccc
-- 025:555555555555555555555555555555555555555555555555555555555555555555555555555555555555550ddddd05550dddddd055000ddd0555555555555555555555500dd05555555555555555555555555555555555555555555fcccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 026:555555555555555555555555555555555555555555555555555555555555555555555555555555555555550d88dd05550d8dddd050ddddd055555555555555555555550dddd05555555555555555555555555555555555555555555fcccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 027:555555555555555555555555555555555555555555555555555555555555555555555555555555555555550d8ddd05550d8dddd050d88dd055555555555555555555550d8dd05555555555555555555555555555555555555555555fcccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 028:555555555555555555555555555555555555555555555555555555555555555555555555555555555555550ddddd05550dddddd050ddddd055555555555555555555550d8dd05555555555555555555555555555555555555555555555555555555555555555555555555553333333333333333333333333
-- 029:555555555555555555555555555555555555555555555555555555555555555555555555555555555555550ddddd05550ddddddd00ddddd055555500000000555555000dddd00055555555555555555555555555555555555555555555555555555555555555555555555557777333333333333333333333
-- 030:555555555555555555555555555555555555555555555555555555555555555555555555555555555555550ddddd0550dddddddd00ddddd0555550dddddddd005550d88ddddd8d05555555555555555555555555555555555555555555555555555555555555555555555557777773333333333333333333
-- 031:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555000dd0550ddd0dddd00ddddd055550d8ddddddddd0550dddddddddd05555555555555555555555555555555555555555555555555555555555555555555555557777777333333333333333333
-- 032:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550dd0550ddd0dddd00ddddd055550ddddddddddd0550dddddddddd05555555555555555555555555555555555555555555555555555555555555555555555557777777733333333333333333
-- 033:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550ddd000dd00dddd00ddddd055550dd0000000ddd050dddddddddd05555555555555555555555555555555555555555555555555555555555555555555555555ee7777733333333333333333
-- 034:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550ddddd8dd00ddddd8dddd055550dd055555550dd055000dddd00055555555555555555555555555555555555555555555555555555555555555555555555555eee7e7733333333333333333
-- 035:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550d4dddddd00dddddddddd05550dddd00000008ddd05550dddd055555555555555555555555555555555555555555555555555555555555555555555555555555eeee7773333333333333333
-- 036:5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555504444d44405000d44444405550444ddddddd44ddd05550444d055555555555555555555555555555555555555555555555555555555555555555555555555555eeeee777333333333333333
-- 037:555555555555555555555555555555555555555ddddd55555555555555555555555555555555555555555555504444444405550444444405550444444444444444055504444055555555555555555555555555555555555555555555555555555555555555555555555555555eeeeee77333333333333333
-- 038:5555555555555555555555555555555555dd45dff44445555555555555555555555555555555555555555555504444444055550444444405550444000000000000555504444055555555555555555555555555555555555555555555555555555555555555555555555555555eeeeee77733333333333333
-- 039:5555555555555555555dddddddddd555ddd445dff44444555555555555555555555555555555555555555555550444444055550444444405555044055555555555555504444000555555555555555555555555555555555555555555555555555555555555555555555555555eeeeee77733333333333333
-- 040:555555555555555555dd44444444ddddd4455d4444444d555555555555555555555555555555555555555555550444444055550444444055555044000000000055555504444444055555555555555555555555555555555555555555555555555555555555555555555555555eeeeee77733333333333333
-- 041:55555555555555555dd4444444444dd555555d4444444d555555555555555555555555555555555555555555550444444055555044444055555504444488444405555504444488055555555555555555555555555555555555555555555555555555555555555555555555555eeeeeee7733333333333333
-- 042:55555555555555555dd4444444444dd55555544444444d555555555555555555555555555555555555555555550444444055555044444055555504444444444405555504444444055555555555555555555555555555555555555555555555555555555555555555555555555eeeeeee7777333333333333
-- 043:55555555555555555d444444444444455555544444444d555555555555555555555555555555555555555555555000000555555500000555555550000000000055555550000000555555555555555555555555555555555555555662222222655555555555555555555555555eeeeeee7777333333333333
-- 044:55555555555555555d4444444444445555555744444445555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555556622222222226555555555555555555555555eeeeeeee777733333333333
-- 045:555555555555555554444447777ee55555555e774dd555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555566222222222226555555555555555555555555eeeeeeeee77773333333333
-- 046:5555555555555555544437777777e55555555e775555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555566666662222222222265555555555555555555555555eeeeeeee77777733333333
-- 047:5555555555555555554377777777e55555555e775555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555552222222222222222222265555555555555555555555555eeeeeeeee7777773733333
-- 048:555555555555555555337777777ee55555555e77555555555555555555555555555555555555555555555555abbb55555555bbbbaaa5555555555555555555555555555555555555555555555555555555555555555555555555e7333333332225555555555555555555555555eeeeeeeee7777777777333
-- 049:555555555555555555337777777e555555555e77555555555555555555555555555555555555555555555abbbb1ba55555bbbbbbbbaa555555555555555555555555555555555555555555555555555555555555555555555555e77777777333255555555555555555555555555eeeeeeee7777777777733
-- 050:555555555555555555337777777e555555555e77555555555555555555555555555555555555555555555ab1bbbba5555bb33bbbbbbaaa5555555555555555555555555555555555555555555555555555555555555555555555e77777777333555555555555555555555555555eeeeeee77777777777733
-- 051:55555555555555555537777777ee555555555e77555555555555555555555555555555555555555555555ab111bba5855bb3bbbbbbbbaaaaa5555555555555555555555555555555555555555555555555555555555562555555ee77777777775555555555555555555555555555eeeeee77777777777773
-- 052:555555555555555555577777eeee55555555ee77555555555555555555555555555555555555555555555bbbbbbba4545bbbbbbbbbbbbbbbb55555555555555555555555555555555555555555555555555555555526622255555e77777777775555555555555555555555555555eeeeee77777777777777
-- 053:55555555555555555557777eee5555555555e777555555555555555555555555555555555555555555555bbbbbbba5455bb3333337ee5555555555555555555555555555555555555555555555555555555555555522222255555e777777777755555555555555555555555555555eeeee77777777777777
-- 054:5555555555555555d4444444444dddddd555e77755555555555555555555555555555555555555555555555a7bba555557333777777e5555555555555555555555555555555555555555555555555555555555555526622255555ee77777777755555555555555555555555555555eeeee77777777777777
-- 055:555555555555555dd444444444444444dd5ee77755555555555555555555555555555555555555555555555e7b77555557737777777e55555555555555555555555555555555555555555555555555555555555552222222555555e777777722255555555555555555555555555555eeee77777777777777
-- 056:55555555555555dd44444444444444444d4e777755555555555555555555555555555555555555555555555e777555555577777777ee55555555555555555555555555555555555555555555555555555555555555222222555555ee77772222226555555555555555555555555555eeee77777777777777
-- 057:5555555555555dd444444444444444444447777755555555555555555555555555555555555555555555555e777555555577777777e555555555555555555555555555555555555555555555555555555555555555222225555555622222222222255555555555555555555555555555eee7777777777777
-- 058:5555555555555d4444444444444444444447777755555555555555555555555555555555555555555555555e77755555557777777ee5555555555555555555555555555555555555555555555555555555555555555ee777555556622222222222265555555555555555555555555555eee7777777777777
-- 059:5555555555555d4444444444444444444447777755555555555555555555555555555555555555555555555e77755555557777777ee5555555555555555555555555555555555555555555555555555555555555555ee7775555566222222222222255555555555555555555555555555eee777777777777
-- 060:5555555555555d4444444444444444444447777755555555555555555555555555555555555555555555555e7775555555777777ee55555555555555555555555555555555555555555555555555555555555555555ee7755555662222222226222265555555555555555555555555555eee777777777777
-- 061:5555555555555d4444444444444444444447777555555555555555555555555555555555555555555555555e777fffffff7777eee555555555555555555555555555555555555555555555555555555555555555555e777555566222222222266222255555555555555555555555555555ee777777777777
-- 062:555555555555dd44444444444444444dd555555555555555555555555555555555555555555555555555555e777faaabbbbbbbbb8b55555555555555555555555555555555555555555555555555555555555555555e777555562222222222226622265555555555555555555555555555ee777777777777
-- 063:555555555555d444444444444444444d5555555555555555555555555555555555555555555555555555555ee77aabbbbbbbbbbbbba5555555555555555555555555555555555555555555555555555555555555555e7775556226622222222266222225555555555555555555555555555ee77777777777
-- 064:555555555555d444444444444444444d5555555555555555555555555555555555555555555555555555555ee7aabbbbbbbbbbbbbbb8555555555555555555555555555555555555555555555555555555555555555ee7775562262222222222262222265555555555555555555555555555e77777777777
-- 065:555555555555d444444444444444444d55555555555555555555555555555555555555555555555555555555eaabbaabbbbbbbbbbbbb8555555555555555555555555555555555555555555555555555555555555555e77775626622222222222662222655555555555555555555555555555e7777777777
-- 066:555555555555d444444444444444444d55555555555555555555555555555555555555555555555555555555eaaaaaaabbbbbbbbbbbba855555555555555555555555555555555555555555555555555555555555555e77772626622222222222662222655555555555555555555555555555eee77777777
-- 067:555555555555d44444444444444444d555555555555555555555555555555555555555555555555555555555aaaaaaaabbbbbbbbbbbbba85555555555555555555555555555555555555555555555555555555555555e77777626222222222266677b225555555555555555555555555555555eee7777777
-- 068:555555555555d44444444444444444d5555555555555555555555555555555555555555555555555555555555aaaaaaabbbbbbbbbbbbba85555555555555555555555555555555555555555555555555555555555555ee7777766222222222eee777755555555555555555555555555555555555ee777777
-- 069:555555555555d44444444444444444d5555555555555555555555555555555555555555555555555555555555555aaaabbbbbbbbbbbbbba8555555555555ffffccc555555555555555555555555555555555555555555e777776622222222ee777777555555555555555555555555555555555555ee77777
-- 070:55555555555544444444444444444455555555555555555555555555555555555555555555555555555555555555555abbbbbbbbbbbbbbaa555555555fffcccccccccc555555555555555555555555555555555555555ee7777762222222ee77777755555555555555555555555555555555555555eee777
-- 071:55555555555544444444444444444455555555555555555555555555555555555555555555555555555555555555555abbbbbbbbbbbbabba5555555ffccccccccccccccc5555555555555555555555555555555555555ee77777622222eee77777755555555555555555555555555555555555555555ee77
-- 072:55555555555544444444444444444455555555555555555555555555555555555555555555555555555555555555555abbbbbbbbbbbbabba5555fffccccccccccccccccccc555555555555555555555555555555555555ee77776222eee7777772655555555555555555555555555555555555555555ee77
-- 073:55555555555544444444444444444455555555555555555555555555555555555555555555555555555555555555555abbbbbbbbbbbbabba555fccccccccccccccccccccccc5555555555555555555555555555555555555eee76222ee77777722655555555555555555555555555555555555555555ee77
-- 074:55555555555544444444444444444455555555555555555555555555555555555555555555555555555555555555555abbbbbbbbbbbbabba55fcccccccccccccccccccccccc555555555555555555555555555555555555555ee7eee7777722222655555555555555555555555555555555555555555ee77
-- 075:5555555555554444444444444444445555555555555555555555555555555555555555555555555555555555555555aabbbbbbbbbbbbabba55fcccccccccccccccfffccccccc555555555555555555555555555555555555555eee777777222222655555555555555555555555555555555555555555ee77
-- 076:5555555555554444444444444444445555555555555555555555555555555555555555555555555555555555555555aabbbbbbbbbbbbabbeeecccccccccccccccccffccccccc555555555555555555555555555555555555555eee77777722222265555555555555555555555555555555555555555eee77
-- 077:5555555555554444444444444444445555555555555555555555555555555555555555555555555555555555555555aabbbbbbbbbbbbaabeeeccccccccccccccccccffcccccc555555555555555555555555555555555555555e7777772222222265555555555555555555555555555555555555555eee77
-- 078:5555555555554444444444444444445555555555555555555555555555555555555555555555555555555555555555aabbbbbbbbbbbbbaeeee7cccccccccccccccccffccccccc55555555555555555555555555555555555555e7772222222222265555555555555555555555555555555555555555ee777
-- 079:5555555555554444444444444444445555555555555555555555555555555555555555555555555555555555555555aabbbbbbbbbbbbbae77777cccccccccccccccccffcccccc55555555555555555555555555555555555555e772222222222222655555555555555555555555555555555555555ee7777
-- 080:3333333333334444444444444444443333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbbbbbee77777cceee77ccccccccccffcccccc33333333333333333333333333333333333333777222222222222263333333333333333333333333333333333333ee77777
-- 081:3333333333334444444444444444443333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbbbbbe7777777ee77777ccccccccccfcccccc333333333333333333333333333333333333337222222222222222633333333333333333333333333333333333eee777777
-- 082:3333333333334444444444444444443333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbbbbbe7777777e777777ccccccccccfcccccc3333333333333333333333333333333333333362222222222222226333333333333333333333333333333333eee77777777
-- 083:3333333333334444444444444444443333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbbbbee777777ee777777ccccccccccccccccc333333333333333333333333333333333333336222222222222222633333333333333333333333333333333e77777777777
-- 084:3333333333334444444444444444443333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbbbbee777777e7777777cccccccccccccccccc333333333333333333333333333333333333362222222222222226333333333333333333333333333333ee777777777777
-- 085:3333333333334444444444444444443333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbbeee7777777e7777777cccccccccccccccccc3333333333333333333333333333333333333622222222222222263333333333333333333333333333eee7777777777777
-- 086:33333333333344444444444444444433333333333333333333333333333333333333333333333333333333333333333abbbbbbbbbbe7e777777ee7777c7ccccccccccccccccccc3333333333333333333333333333333333333622222222222222263333333333333333333ffffffffeee777777777777cc
-- 087:33333333333344444444444444444433333333333333333333333333333333333333333333333333333333333333333abbbbbbbbbbe7e777777e7777cccccccccccccccccccccc3333333333333333333333333333333333333622222222222222263333333333ffffffffffcccccccccccccccccccccccc
-- 088:33333333333444444444444444444433333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbe7e777777e7777cccccccccccccccccccccc33333333333333333333333333333333333333622222222222222233333333fffffffffffccccccccccccccccccccccccc
-- 089:33333333333444444444444444333733333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbe7e777777e777cccccccccccccccccccccc3333333333333333333333333333333333333336222222222222222233333fffccccccccccccccccccccccccccccccccccc
-- 090:33333333333444444444444433337733333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbbe7e777777e777cccccccccccccccccccccc333333333333333333333333333333333333333622222222222222233333ffccccccccccccccccccccccccccccccccccccc
-- 091:333333333333444444333333333377333333333333333333333333333333333333333333333333333333333333333333aabbbbbbbbe7ee77777e7777ccccccccccccccccccccc3333333333333333333333333333333333333362222222223333373333fffcccccccccccccccccccccccccccccccccccccc
-- 092:3333333333334444333333333333373333333333333333333333333333333333333333333333333333333333333333337733333333e77e7777777777ccccccccccccccccccccc3333333333333333333333333333333333333362222222333333373ffffcccccccccccccccccccccccccccccccccccccccc
-- 093:3333333333334433333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e7777777777ccccccccccccccccccccc333333333333333333333333333333333333336222333333333337fffcccccccccccccccccccccccccccccccccccccccccc
-- 094:3333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e7777777777ccccccccccccccccccccc333333333333333333333333333333333333336673333333333337ffccccccccccccccccccccccccccccccccccccccccccc
-- 095:3333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e77777777777ccccccccccccccccccc333333333333333333333333333333333333333337333333333333ffcccccccccccccccccccccccccccc3333cccccccccccc
-- 096:3333333333333773333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77e77777777777ccccccccccccccccccc3333333333333333333333333333333333333333373333333333fffccccccccccccccccccccccccc33333333333333333333
-- 097:3333333333333773333333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e77ee77777777777ccccccccccccccccc33333333333333333333333333333333333333333373333373333ffccccccccccccccccccccccc33333333333333333333333
-- 098:3333333333333773337333333333373333333333333333333333333333333333333333333333333333333333333333337333333333e7777777777777777ccccccccccccccc33333333333333333333333333333333333333333337333337333ffcccccccccccccccccccccc3333333333333333333333333
-- 099:3333333333333773337333333333377333333333333333333333333333333333333333333333333333333333333333337333333333e77777777777777777cccccccc7777e33333333333333333333333333333333333333333333733333733ffccccccccccccccccccccc333333333333333333333333333
-- 100:3333333333333773337733333333377333333333333333333333333333333333333333333333333333333333333333337333333333e777777777777777777cccc7777777e3333333333333333333333333333333333333333333373333373ffccccccccccccccccccccc3333333333333333333333333333
-- 101:3333333333333773333733333333377333333333333333333333333333333333333333333333333333333333333333337333337333e7777777777777777777cc77777777e333333333333333333333333333333333333333333337333337ffcccccccccccccccccccc333333333333333333333333333333
-- 102:3333333333333773333733333333377333333333333333333333333333333333333333333333333333333333333333337333337333e7777777777777777777777777777ee33333333333333333333333333333333333333333333733333ffcccccccccccccccccccc3333333333333333333333333333333
-- 103:3333333333333773333773333333377333333333333333333333333333333333333383333333333333333333333333337333337333e777777777777777777777777777ee333333333333333333333333333333333333333333333733337fccccccccccccccccccc333333333333333333333333333333333
-- 104:3333333333333733333733333333337333333333333333333333333333333333333454333333333333333333333333333733337333ee777777777777777777777777eee333333333333333333333333333333333333333333333373333ffcccccccccccccccc3c3333333333333333333333333333333333
-- 105:3333333333333733333773333333337333333333333333333333333333333333333343333333333333333333333333333733337333ee77777777777777777777777ee3333333333333333333333333333333333333333333333337333ffccccccccccccccc33333333333333333333333333333333333333
-- 106:33333333333337333333733333333373333333333333333333333333333333333333333333333333333333333333333337333373337e777777777777777777777eee33333333333333333333333333333333333333333333333337333ffcccccccccccccc333333333333333333333333333333333333333
-- 107:33333333333337333337733333333373333333333333333333333333333333333333333333333333333333333333333337333373333e777777777777777777777ee33333333333333333333333333333333333333333333333333733ffcccccccccccccc3333333333333333333333333333333333333333
-- 108:33333333333337333337733333333773333333333333333333333333333333333333333333333333333333333333333337333373333ee77777777777777777777333333333333333333333333333333333333333333333333333777ffccccccccccccccc3333333333333333333333333333333333333333
-- 109:33333333333337333337733333333773333333333333333333333333333333333333333333333333333333333333333337333373333ee77777777777777777777333333333333333333333333333333333333333333333333333773ffcccccccccccccc33333333333333333333333333333333333333333
-- 110:33333333333337333337733333333773333333333333333333333333333333333333333333333333333333333333333337333373333ee77777777777777777777333333333333333333333333333333333333333333333333333773ffccccccccccccc333333333333333333333333333333333333333333
-- 111:333333333333373333373333333337733333333333333333333333333333333333333333333333333333333333333333373337733333e77777777777777777777333333333333333333333333333333333333333333333333333733ffccccccccccccc333333333333333333333333333333333333333333
-- 112:1bbbb1bbbbbbb733333733333333377bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3373337333333ee7777777777777777777bbbbbbbb1bbbbb1bb1bbbbb1bbbbbbbb1bbbbbbbbbb1b1bbbbb773ffccccccccccccc333333333333333333333333333333333333333333
-- 113:bbbb1bbbbb1bb7333337333333333771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3373337333333ee7777777777777777777b1bbbbb1bbbbbb1bbbbbb1bb1bb1bbbbbbb1bbbbbbbb1bbbbbb73ffccccccccccc333333333333333333333333333333333333333333333
-- 114:bbbbbbbbbb1bb733333733333333377bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3373337333333be7777777777777777777bbbbbbb1bbb1bbbbbb1bb1bbbbb1bb1bbbb1bbbbbbbbbbbbbb773ffcccccccccc3333333333333333333333333333333333333333333333
-- 115:b1bbbbbbbbbbb733333733333333377bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b73337333333bbe777777777777777777bbb1bbbbb1bbbbbbbbbbbbbbbb1bbbbbbbbbbbbb1bbbbbbbb7773ffcccccccccc3333333333333333333333333333333333333333333333
-- 116:b1bbbbbbbbbbb3333337333333333771bbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbb1bbbbbbbbbb777733773333333be777777777777777777bbb1bbbbb1b1bbbb1bbb1bbbbbbbb1b1bbbbbbbbbbbbbbbb77333ffccccccccc33333333333333333333333333333333333333333333333
-- 117:bbbbbbb1bbb1b3333337333333333777bbbbbb1bbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbb77333377b3333333bbee7777777777777777bbbbbbbb1bbbb1bb1bbbbb1bbb1bbbbbbbbbbb1bbb1bbbb37733ffccccccccc333333333333333333333333333333333333333333333333
-- 118:bbbbbbbbb1bbb7333337333333333377b1bbbb1bbbbbbbbb1bbbb1b11bbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbbb7333777733333333bbbee77777777777777777bbbbbbbbbbbb1bbbbbb1bbb1bbbbbbbbbbbbbbbbbbbbb37333ffcccccccc3333333333333333333333333333333333333333333333333
-- 119:bb1bbbbbbbbbb73333373333333333771bbbbbb1bb1bbbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11b333733333333333bbbbe77777777777777777bbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbbb1bbb373fffccccccccc3333333333333333333333333333333333333333333333333
-- 120:b11bbbbbbbbbb7777737333333333337bbbbbbbbbb1bbbbbbbbbbbbb1b1bbbbbbbbb1bbbbbbbb1bbbbbbbb1bb1bbbbb3bbbbbbbb3bbbbbbbbee7777777777777777bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbb1bbbb1bbb333ffccccccccc33333333333333333333333333333333333333333333333333
-- 121:b11bbbbbbbbbb77777777777777333371bbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbb1bbbbb1bbbbbbbb1bbbbbbb7bbbbbbbbbbbbbbbbbee7777777777777777bbb1bbb1bbbbbb1bbbb1bbb1bbb1bbbbbbb1b1bbbbbbb3ffcccccccccc33333333333333333333333333333333333333333333333333
-- 122:bb1bbbbbbbbbbbbbbbb7777bb777bbbbbbbbbbbbbbbbbbbbbbb1bbbbbbb1bbbb1bbbbbbbb1bbbbbbbbbbb1bbbbbbb1b1bbbbbbbbbbbbbbbbbbbe7777777777777777bb1bbbb1bbb1bbbbbbb1b1b1bbb1bb1bbbb1bbbbb1bbbbffccccccccc333333333333333333333333333333333333333333333333333
-- 123:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbb1bbb1b1bb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbb1bbbbbbbbbbbbbbbbbbbbee777777777777777bbbbbbbbbb1bbbbb1b1bb1bbbbbb1bbbbbbbbbbbbbbbbffccccccccc3333333333333333333333333333333333333333333333333333
-- 124:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbb111bbbbbbbbb1bbbb1bbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbe7777777777777777bbb1bbbbb1bbbb1bbbbbb1bbbbbb1bbbbbbb1bbbbb1bffccccccccc3333333333333333333333333333333333333333333333333333
-- 125:bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbb1bbb1bb1bbbbbbb1bbbbbbbbbbbbbb1bbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbb1bee777777777777777bbbbbbbbbbbbbbbb1b1bbbbbbbbbbbbb1bbbbbbbb1bffccccccccc33333333333333333333333333333333333333333333333333333
-- 126:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbb1bbbbbbbbbbbb1bbbbbbbb1bb1bbbbbbbbbbbbb1b1bbbbb1bbbbbbbbbbbbbbbbbbbb1bbe777777777777777bbbbb1bbbbbbbbbbbbbbbb1b1bbbbbb1bbbbbb1bbbbffcccccccc333333333333333333333333333333333333333333333333333333
-- 127:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbb1bbbbb1bbbbbbbbbbbb1bbbbbbbbbbbb1bbbbbbb1bb1bbbbb1bb1bbbbbbbbbbbbbbbbbbbbbbbbee777777777777777bbbbb1bbbb1bbbbbbbbb1b1b1bbbbb1bb1bb1bb1bbffcccccccc333333333333333333333333333333333333333333333333333333
-- 128:bbbb1bbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbb1bbbbbbb1bbbbbbb1bbbb1b1bbbbbb1bb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbe777777777777777bbbb1bbbb1b1bbbb1bb1bb1b1bbb1bbbbbbb1bbbbbffcccccccc333333333333333333333333333333333333333333333333333333
-- 129:b1b1bbb1bbbbbbbbbbbbbbbb7bbbbbbb1bbbbbbbbbb1bbbb1b1bb1b1bbbbb1bb1b1bbbbbbbbbb1b1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbee77777777777777bb1bbbb1bb1bbbbb1bbbbbbbbbb1bbbb1bbbbbbbbffccccccccc333333333333333333333333333333333333333333333333333333
-- 130:bbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb1b1bbbbb1bbbbbbbb1bbbbbbbbbbbbb1bbbbb1bbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbee777777777777777b1bbbbb1bbbb1bbbbb1bbbbbbbb1bbb1bbbbb1bbffcccccccc3333333333333333333333333333333333333333333333333333333
-- 131:bbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbb1bbbbbbbb1bbbb1bbbb1b1bbbb1bbbbb1bbbbb1bbbbbbbbbbbbbbbbbbbbbbb1e777777777777777bbbbb1bbbbbbbbb1bbb1bbb1bbbbbbbbbb1bbbbffccccccccc3333333333333333333333333333333333333333333333333333333
-- 132:1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b11bbbbbbbbbbb1bbbbbbbb1b1bb1bbb1bbbbbb1b1bb1bbbbbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbb1be7777777777777777bbb1bbbbbbbb1bb1b1bbb1bb1bbbbbbbbbbbbbffccccccccc3333333333333333333333333333333333333333333333333333333
-- 133:1bbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbb1bb1bbbbb1bbbb1bbb1bb1bbbbb1bbb1b1bbbbbbbbbbbbbbbb1bbbbbbb1bbbbbbbbbbbbbbbbbbbbbb1bee7777777777777777bbb1bbbbbbbb1bbbb1bbbbbbbbbb1bbb1bbbbffccccccccc3333333333333333333333333333333333333333333333333333333
-- 134:1bb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbb1b1bbbbbbb1bbbbbbbbbbbbbbb1bbbb1bbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbee777777777777771bbbbb1b1b1bb1bb1bbbbbb1bbbb1bbbbb1bbffccccccccccc333333333333333333333333333333333333333333333333333333
-- 135:bbb1bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbb1bbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbb1bee7777777777777771bbbbb1bb1bbbbb1bbbb1b1bb1bbbbbbbbbbffccccccccccc333333333333333333333333333333333333333333333333333333
-- </SCREEN>

-- <PALETTE>
-- 000:00000074b72ea858a82936403b5dc9ff0006ff79c2566c87f4f4f46d40144cda85466d1ded820e41a6f6ffe5b4ffe761
-- </PALETTE>

-- <PALETTE1>
-- 000:00000074b72ea858a82936403b5dc900fff9ff79c2566c87f4f4f42571794cda85466d1ded820d41a6f6ffe5b4ffe761
-- </PALETTE1>

