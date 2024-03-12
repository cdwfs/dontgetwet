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
K_FOO=0
-- sounds
SFX_FOO=0
-- music patterns
MUS_MENU=0
-- sprite ids
SID_PLAYER=352
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
 return cb
end

function cb_create_player(pid)
 local pid_colors={2,4,6,10}
 return {
  --[[
  notes on player coordinates:
  - positions are for the player's
    upper-left corner
  - fx,fy are raw floating-point pos,
    which should only be used for motion.
  - px,py are fx,fy rounded to the nearest
    pixel (always integers)
  - dx,dy are the player's current raw
    movement in each axis: -1,0,1
    (later scaled by speed)
  - cx,cy are the pixel offsets to the
    center of the current player's
    viewport. These are computed once at
    startup and are constant for each
    player thereafter.
  - focusx,focusy is the world-space
    position that should be drawn at
    the center of the player's viewport.
  - The final screen-space coordinates
    for an object at world-space wx,wy
    for a given player are:
    cx-focusx+wx,cy-focusy+wy
  ]]
  fx=0,
  fy=0,
  px=0,
  py=0,
  dx=0,
  dy=0,
  cx=0,
  cy=0,
  focusx=0,
  focusy=0,
  color=pid_colors[pid],
  pid=pid,
  dir=0, -- 0-7: 0=N, 1=NE, 2=E, etc.
  speed=1, -- how far to move in current dir per frame
  dead=false,
 }
end
function cb_init_players(cb)
 local spawns={
  {16,16}, {16,64},
  {40,30}, {80,60},
 }
 for pid=1,cb.all_player_count do
  local p=cb_create_player(pid)
  p.fx,p.fy=table.unpack(spawns[pid])
  -- todo: use fx,fy for movement
  -- and round afterwards
  p.px=flr(p.fx+0.5)
  p.py=flr(p.fy+0.5)
  local pclip=cb.clips[pid]
  p.cx=pclip[1]+pclip[3]/2
  p.cy=pclip[2]+pclip[4]/2
  add(cb.players,p)
 end
end

function cb_leave(_ENV)
 clip()
 music()
end

function cb_update(_ENV)
 -- handle input & move players
 local function is_walkable(px,py)
  return not fget(mget(px//8,py//8),SF_IMPASSABLE)
 end
 for _,p in ipairs(players) do
  local pb0=8*(p.pid-1)
  p.dy=(btn(pb0+0) and -1 or 0)+(btn(pb0+1) and 1 or 0)
  p.dx=(btn(pb0+2) and -1 or 0)+(btn(pb0+3) and 1 or 0)
  -- TODO: walk one pixel at a time
  local s=p.speed
  if p.dy<0 then -- up
   if is_walkable(p.px,p.py-1)
   and is_walkable(p.px+7,p.py-1) then
    p.py=p.py-s
   end
  elseif p.dy>0 then -- down
   if is_walkable(p.px,p.py+1+7)
   and is_walkable(p.px+7,p.py+1+7) then
    p.py=p.py+s
   end
  end
  if p.dx<0 then -- left
   if is_walkable(p.px-1,p.py)
   and is_walkable(p.px-1,p.py+7) then
    p.px=p.px-s
   end
  elseif p.dx>0 then -- right
   if is_walkable(p.px+1+7,p.py)
   and is_walkable(p.px+1+7,p.py+7) then
    p.px=p.px+s
   end
  end
  -- Update player's camera focus.
  p.focusx=approach(p.focusx,p.px,.2)
  p.focusy=approach(p.focusy,p.py,.2)
  -- Update player's facing direction,
  -- if input was pressed.
  local dir_lut={[0]=7,0,1,6,-1,2,5,4,3}
  local dir=dir_lut[3*(p.dy+1)+(p.dx+1)]
  if dir>=0 then p.dir=dir end
  ::end_player_update::
 end
end

function cb_draw(_ENV)
 clip()
 cls(0)
 -- draw each player's viewport
 for pid,p in ipairs(players) do
  local pclip=clips[pid]
  clip(table.unpack(pclip))
  camera(-(p.cx-p.focusx),
         -(p.cy-p.focusy))
  -- draw map
  map(0,0,30,17,0,0)
  -- draw the players
  for _,p2 in ipairs(players) do -- draw corpses
   draw_player(p2)
  end
  -- restore screen-space camera
  camera(0,0)
  -- draw "game over" message for eliminated players
  if p.dead then
   rect(p.cx-38,p.cy-20,75,9,0)
   rectb(p.cx-38,p.cy-20,75,9,p.color)
   local w=print("KILLED BY PX",p.cx-36,p.cy-18,p.color,true)
  end
  -- draw border.
  -- TODO: perhaps cx,cy should be the inside of this
  -- border?
  rectb(pclip[1],pclip[2],pclip[3],pclip[4],p.color)
 end
end

function draw_player(player)
 local p=player
 local d=p.dir
 local sid=SID_PLAYER
 local flip=0
 --[[
 -- dirs are 0-7: 0=N, 1=NE, 2=E etc.
 if d==0 then -- up
  sid=sid+64
 elseif d==1 or d==2 or d==3 then -- right
 elseif d==4 then -- down
  sid=sid+32
 elseif d==5 or d==6 or d==7 then -- left
  flip=1
 end
 -- animate if the player is alive and moving.
 if not p.dead
 and (p.dx~=0 or p.dy~=0) then
  sid=sid+2+2*((mode_frames//4)%2)
 end
 ]]
 -- draw player
 local prev=peek4(2*0x03FF0+2)
 poke4(2*0x03FF0+2,p.color)
 spr(sid,p.px,p.py-8,5,1,flip,0,1,2)
 poke4(2*0x03FF0+2,prev)
end

-- <TILES>
-- 004:0000000000600505076575760066565606655666005776670077766507777666
-- 005:0000000060070060676566656566676677766566755677665566556566666665
-- 006:0000000060070060676566006566670077766500755677605566500066666600
-- 008:7555576666676666666657666676656775676666566777750550666600000666
-- 009:6675555766667666667566667656676666667657577776656666055066600000
-- 020:0657657700656555076575760566565600655666005776670577766507777666
-- 021:666665766666665666677666777556766576f666755666756ffff5656f666666
-- 022:6666660066676600676566606566670077766560755677005566556066666000
-- 024:6675555766667666667566667656676666667657577776656666055066600000
-- 025:7555576666676666666657666676656775676666566777750550666600000666
-- 032:0000000000000000000000000000000000000022002222202220000000200000
-- 033:0000000000000000000000000000000020000000000000200000202020202020
-- 034:0000220002222000220000002000220020202020202020202020220020002020
-- 035:0000002000002002220022002020202020202202220020002020000020000000
-- 036:0555576600676666006657660676656705676666066777750050665600000000
-- 037:7555576666676666666657666676656775676666566777750550665000000000
-- 038:6675555066667600667566007656676066667650577776606566050000000000
-- 048:0020020000200220002002020020020000200200002002000020000000200022
-- 049:2020202020220020202000202000000000000022000020000222200020000000
-- 050:2200202002002200020000002000000000000000000000000000000000000000
-- 064:0020220022220000200000000000000000000000000000000000000000000000
-- </TILES>

-- <SPRITES>
-- 004:0000000d000000cc0000000d0000000d0000000d0000000d0000000d0000000d
-- 005:00000000c0000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000d000000d000000d000000d000
-- 007:0ccd000000dc00000d0c0000d000000000000000000000000000000000000000
-- 016:000c000000ddd000000c0000000c0000000c0000000c00000012300001020300
-- 017:000c000000ddd000000c0000000c0000000c0000000c00000034c00003040c00
-- 018:000c000000ddd000000c0000000c0000000c0000000c00000076500007060500
-- 019:000c000000ddd000000c0000000c0000000c0000000c0000009ab000090a0b00
-- 020:0000000d0000000d0000000d0000000d0000000d0000001d0000011200000002
-- 021:0000000000000000000000000000000000000000300000003300000000000000
-- 022:000d000011d00000023000002030000000000000000000000000000000000000
-- 032:00000dcc000000dc00000c0d0000c000000c000011c000000230000020300000
-- 033:00000dcc000000dc00000c0d0000c000000c000033c0000004c0000040c00000
-- 034:00000dcc000000dc00000c0d0000c000000c000077c000000650000060500000
-- 035:00000dcc000000dc00000c0d0000c000000c000099c000000ab00000a0b00000
-- 036:5552222255222222522222225222222c522222cc522222cc522222cc55222ccc
-- 037:22225555222225552cc22225cccc2225c11cc555c11cc555ccccccc5ccccccc5
-- 038:5552222255222222522222225222222c522222cc522222cc522222cc55222ccc
-- 039:2222555522222555ccc22225cccc2225c11cc555c11cc555ccccccc5ccccccc5
-- 040:5552222255222222522222225222222c522222cc522222cc522222cc55222ccc
-- 041:2222555522222555ccc22225cccc2225c11cc555c11cc555ccccccc5ccccccc5
-- 048:52222255522cc225522c1c5552ccccc5552cc55555ccccc55c5cc55555dd5dd5
-- 049:52222255522cc225522c1c5552ccccc5552cc5555ccccc5555dc5cd5555d5d55
-- 050:52222255522cc225522c1c5552ccccc5552cc55555ccc5555c5cc555555ddd55
-- 052:55222ccc55522ccc55552ccc55555ccc555ccccc555ccccc555dccc55555ddd5
-- 053:cccc5555ccc55555ccc55555cccccc55cccccc55ccc55555dccc55555ddd5555
-- 054:55222ccc55522ccc55552ccc55555ccc55555ccc5555cccc5555ddcc55555dd5
-- 055:cccc5555ccc55555ccc55555cccccc55cccccc55cc555555ccd55555ddd55555
-- 056:55222ccc55522ccc55552ccc55555ccc55555ccc55555ccc55555dcc555555dd
-- 057:cccc5555ccc55555ccc55555cccccc55cccccc55cc5555555c5555555d555555
-- 064:5522225552cc2225521cc22552cccc25555cc25555cccc555c5cc5c5555dd555
-- 065:5522225552cc2225521cc22552cccc25555cc25555ccccc55c5dc5555555d555
-- 066:5522225552cc2225521cc22552cccc25555cc2555ccccc55555cd5c5555d5555
-- 068:555222225522222252222ccc5222cccc522cc11c522cc11c522ccccc5522cccc
-- 069:2222555522222555ccc22225cccc2225c11cc225c11c2225cccc2225ccccccc5
-- 070:555222225522222252222ccc5222cccc522cc11c522cc11c522ccccc5522cccc
-- 071:2222555522222555ccc22225cccc2225c11cc225c11c2225cccc2225ccccccc5
-- 072:555222225522222252222ccc5222cccc522cc11c522cc11c522ccccc5522cccc
-- 073:2222555522222555ccc22225cccc2225c11cc225c11c2225cccc2225ccccccc5
-- 080:552222555222222552222225522222255522c55555cccc555c5cc5c5555dd555
-- 081:552222555222222552222225522222255522c55555ccccc55c5dc5555555d555
-- 082:552222555222222552222225522222255522c5555ccccc55555cd5c5555d5555
-- 084:555ccccc555ccccc55cccccc5ccc5ccc55555ccc55555ccc55555cc555555dd5
-- 085:ccccc555cccccc55ccc5cc55ccc55c55ccc55555ccc555555cc555555dd55555
-- 086:555ccccc555ccccc55cccccc5ccc5ccc55555ccc55555ccc55555dd555555555
-- 087:ccccc555cccccc55ccc5cc55ccc55c55ccc55555ccc555555cc555555dd55555
-- 088:555ccccc555ccccc55cccccc5ccc5ccc55555ccc55555ccc55555cc555555dd5
-- 089:ccccc555cccccc55ccc5cc55ccc55c55ccc55555ccc555555dd5555555555555
-- 096:5552255555222255555dd55555cccc555cdccdc5cd5cc5dccd5cc5dc555cc555
-- 100:5552222255222222522222225222222252222222522222225222222255222222
-- 101:2222555522222555222222252222222522222225222222252222222522222cc5
-- 102:5552222255222222522222225222222252222222522222225222222255222222
-- 103:2222555522222555222222252222222522222225222222252222222522222cc5
-- 104:5552222255222222522222225222222252222222522222225222222255222222
-- 105:2222555522222555222222252222222522222225222222252222222522222cc5
-- 112:555cc55555cccc555ccddcc55cd55dc55cd55dc55cd55dc55cd55dc55cd55dc5
-- 116:555c2222555ccc2255cccccc5ccc5ccc55555ccc55555ccc55555cc555555dd5
-- 117:222225552222cc552225cc55c2c55c55ccc55555ccc555555cc555555dd55555
-- 118:555c2222555ccc2255cccccc5ccc5ccc55555ccc55555ccc55555dd555555555
-- 119:222225552222cc552225cc55c2c55c55ccc55555ccc555555cc555555dd55555
-- 120:555c2222555ccc2255cccccc5ccc5ccc55555ccc55555ccc55555cc555555dd5
-- 121:222225552222cc552225cc55c2c55c55ccc55555ccc555555dd5555555555555
-- </SPRITES>

-- <MAP>
-- 000:515151515151515151515151515151515151515151515151515151515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:519052525252525252525252525252525252525252525252525280515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:516100000000000000000000000000000000000000000000000041515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:516100000000000000000000000000000000000000000000000041515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:516100004060000040505050505050505060000000000000000041515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:516100004161000041515252525252528061000000000000000041515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:516100004161000041610000000000004161000000000000000042528051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:516100004262000041610000000000004262000000000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:516100000000000042525151000000000000000000000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:516100000000000000000000000000000000000000000000000040515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:516100005100000000000000000000000000000000000000000042529151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:516100005151000040000000004000000000000000000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:516100000000000041510000004151000000000000000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:516100000000000040500000405151000000000000000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:516100000000000041510000415151510000000000000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:519150505050505040504050405151504050405040504050405040504051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:515151515151515151515151515151515151515151515151515151515151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:00000000101010001010000000000000000000001010100010100000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202000000000000000000000000000202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

