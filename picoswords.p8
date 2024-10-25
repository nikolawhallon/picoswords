pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- objects

-- usage:
-- ```
-- myanim=anim:new({
--  sprs={19,21},
--  fpi=3
-- })
-- ```
-- sprs = sprite indices
-- fpi = frames per index
anim={
 sprs={},
 cur=0,
 fpi=1,

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,
 
 update=function(self,f)
  for n=1,#self.sprs do
   if f / self.fpi % #self.sprs == n - 1 then
    self.cur=self.sprs[n]
   end
  end
 end
}

player={
 x=16,
 y=16,
 -- move, idle must be present
 -- override for p2, etc
 anims={
  move=anim:new({
   sprs={19,21},
   fpi=3
  }),
  idle=anim:new({
   sprs={19,20},
   fpi=10
  })
 },
 dir='right',
 mov=false,
 score=0,
 health=3,
 -- consider making sword object
 -- would have:
 -- x,y,dir,active,draw
 swd_dir='right',
 swd_out=false,

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,

 -- update state
 -- l,r,u,d,a,b = controller input
 update=function(self,f,l,r,u,d,a,b)
  if not a and not b then
   self.swd_out=false
  else
   self.swd_out=true
  end
  
  if l then
   if not self.swd_out then
    if not intersects_tile(3,self.x-1,self.y,8,8) then
     self.x-=1
    end
   end
   self.dir='left'
   self.swd_dir='left'
  end
  if r then
   if not self.swd_out then
    if not intersects_tile(3,self.x+1,self.y,8,8) then
     self.x+=1
    end
   end
   self.dir='right'
   self.swd_dir='right'
  end
  if u then
   if not self.swd_out then
    if not intersects_tile(3,self.x,self.y-1,8,8) then
     self.y-=1
    end
   end
   self.swd_dir='up'
  end
  if d then
   if not self.swd_out then
    if not intersects_tile(3,self.x,self.y+1,8,8) then
     self.y+=1
    end
   end
   self.swd_dir='down'
  end

  if l or r or u or d then
   self.mov=true
  else
   self.mov=false
  end

  for k,v in pairs(self.anims) do
   v:update(f)
  end
 end,

 -- pick the animation
 -- based on state
 draw=function(self)
  flp=false
  if self.dir=='left' then
   flp=true
  end
  
  if self.mov then
   cur=self.anims['move'].cur
   spr(cur,self.x,self.y,1,1,flp)
  else
   cur=self.anims['idle'].cur
   spr(cur,self.x,self.y,1,1,flp)
  end

  if self.swd_out then
   if self.swd_dir=='left' then
    spr(28,self.x-8,self.y,1,1,true)
   elseif self.swd_dir=='right' then
    spr(28,self.x+8,self.y)
   elseif self.swd_dir=='up' then
    spr(29,self.x,self.y-8,1,1,false,true)
   elseif self.swd_dir=='down' then
    spr(29,self.x,self.y+8)
   end
  end

  -- ui health bar
  rectfill(self.x,self.y-3,self.x+1,self.y-2,11)
  rectfill(self.x+3,self.y-3,self.x+4,self.y-2,11)
  rectfill(self.x+6,self.y-3,self.x+7,self.y-2,11)
 
 end
}

gosoh={
 x=64,
 y=64,
 xvel=0.0,
 yvel=0.0,
 anims={
  move=anim:new({
   sprs={5,6,7},
   fpi=3
  })
 },

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,

 update=function(self,f)
  self.x += self.xvel
  self.y += self.yvel
  for k,v in pairs(self.anims) do
   v:update(f)
  end
 end,

 draw=function(self)
  cur=self.anims['move'].cur
  spr(cur,self.x,self.y)
 end
}

function intersects(x1,y1,w1,h1,x2,y2,w2,h2)
 if x1+w1<=x2 or x2+w2<=x1 then
  return false
 end
    
 if y1+h1<=y2 or y2+h2<=y1 then
  return false
 end
     
 return true
end

function intersects_tile(t,x1,y1,w1,h1)
 local n=2
 for i=0,n do
  for j=0,n do
   local x=x1+(w1*i)/n
   local y=y1+(h1*j)/n
   if mget(x/8,y/8)==t then
    return true
   end
  end
 end

 return false
end
-->8
-- game loop

--music(0)

p1=player:new({
 x=16,
 y=16,
})

p2=player:new({
 x=96,
 y=96,
 anims={
  move=anim:new({
   sprs={25,27},
   fpi=3
  }),
  idle=anim:new({
   sprs={25,26},
   fpi=10
  })
 }
})

skele=anim:new({
 sprs={8,9,8,10},
 fpi=3
})

gosohs={}
gosoh_timer=120

heart=anim:new({
 sprs={1,2},
 fpi=10
})
 
blofire=anim:new({
 sprs={35,36},
 fpi=10
})

glom=anim:new({
 sprs={51,52,53},
 fpi=5
})

f=0

function _update()
 -- spawn gosohs
 if f % gosoh_timer==0 then
  local a=rnd(1.0)
  gosoh=gosoh:new({
   x=64-4+(128 * cos(a)),
   y=64-4+(128 * sin(a)),
   xvel=-cos(a) * (rnd(1)+0.5),
   yvel=-sin(a) * (rnd(1)+0.5)
  })
  add(gosohs,gosoh)
 end
 
 -- update objects
 p1:update(f,btn(0,0),btn(1,0),btn(2,0),btn(3,0),btn(4,0),btn(5,0))
 p2:update(f,btn(0,1),btn(1,1),btn(2,1),btn(3,1),btn(4,1),btn(5,1))

 for gosoh in all(gosohs) do
  gosoh:update(f)
 end
 
 -- despawn out-of-bounds gosohs
 for gosoh in all(gosohs) do
  if sqrt((gosoh.x-64) * (gosoh.x-64)+(gosoh.y-64) * (gosoh.y-64)) > 256 then
   del(gosohs,gosoh)
  end
 end

 -- gosoh sword collision
 for _,p in ipairs({p1,p2}) do
  for gosoh in all(gosohs) do
   if p.swd_out then
    local swdx = p.x
    local swdy = p.y
    if p.swd_dir=='left' then
     swdx-=8
    elseif p.swd_dir=='right' then
     swdx+=8
    elseif p.swd_dir=='up' then
     swdy-=8
    elseif p.swd_dir=='down' then
     swdy+=8
    end
 
    if intersects(gosoh.x,gosoh.y,8,8,swdx,swdy,8,8) then
     del(gosohs,gosoh)
     p.score+=1
    end
   end
  end
 end

 -- test objects
 skele:update(f)
 heart:update(f)
 blofire:update(f)
 glom:update(f)
end

function _draw()
 cls(1)
 map(0,0,0,0,16,16)

 p1:draw()
 p2:draw()

 for gosoh in all(gosohs) do
  gosoh:draw()
 end

 spr(skele.cur,64,64)
 spr(heart.cur,32,64)
 spr(blofire.cur,96,32)
 spr(glom.cur,32,96)

 -- ui
 print("p1:",10,9,14)
 print(p1.score,22,9,14)
 print("p2:",99,9,14)
 print(p2.score,111,9,14)
 
 f+=1
end
__gfx__
0000000007700ee00000000007760776222200000000000000000000000000000077770000777700007777000000000000000000000000000000000000000000
0000000077eeeeee07e00ee007660766200202200077770000777700007777000660606006606060066060600000000000000000000000000000000000000000
007007007eeeeeee7eeeeeee06660666200202200777777007777770077777700660606006606060066060600000000000000000000000000000000000000000
00077000eeeeeeeeeeeeeeee00000000222200000707707007077070070770700066660000666600006666000000000000000000000000000000000000000000
000770000eeeeee0eeeeeeee77607760000022220707707007077070070770700006060000006000000060000000000000000000000000000000000000000000
0070070000eeee000eeeeee076607660022020020777777007777770077777700000700000070000000007000000000000000000000000000000000000000000
00000000000ee00000eeee0066606660022020020707707000770770077077000007070000707000000070700000000000000000000000000000000000000000
0000000000000000000ee00000000000000022220000000000000000000000000000600000060000000006000000000000000000000000000000000000000000
00000000000000bbbb0000000220000022000000220000000ee00000ee000000ee0000000ee00000ee000000ee00000000000000000620000000000000000000
00000000bbbbbbbbbbbbbbbb226666600220000002200000eeccccc00ee000000ee00000ee6666600ee000000ee0000000600000000620000000000000000000
00000000bbbbbbbbbbbbbbbb00667670006666600066666000cc7c7000ccccc000ccccc000667670006666600066666000d7777006dddd200000000000000000
00000000bbbbbbbbbbbbbbbb00667670006676700066767000cc7c7000cc7c7000cc7c7000667670006676700066767066d66667007662000000000000000000
00000000333333333333333300666660006676700066767000ccccc000cc7c7000cc7c7000666660006676700066767022d66662007662000000000000000000
00000000bbbbbbbbbbbbbbbb000666000066666000666660000ccc0000ccccc000ccccc000066600006666600066666000d22220007662000000000000000000
00000000000000bbbb000000000666000006660000066600000ccc00000ccc00000ccc0000066600000666000006660000200000007662000000000000000000
00000000000000000000000000600060006000600006060000c000c000c000c0000c0c0000600060006000600006060000000000000720000000000000000000
00000000000000000000000008008000000000000000000008800000880000008800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000008808800000000000000000088555550088000000880000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000888800008080000000000000557570005555500055555000000000000000000000000000000000000000000000000000000000
00000000000000000000000008878780008888000000000000557570005575700055757000000000000000000000000000000000000000000000000000000000
00000000000000000000000008878780088787800000000000555550005575700055757000000000000000000000000000000000000000000000000000000000
00000000000000000000000008888880088787800000000000055500005555500055555000000000000000000000000000000000000000000000000000000000
00000000000000000000000000888800008888000000000000055500000555000005550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000500050005000500005050000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000bb000000000003300000330000003300000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000bb000000bbbb00000000033ddddd0033000000330000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000bbbb0000bb7b7b00bbbb0000dd7d7000ddddd000ddddd000000000000000000000000000000000000000000000000000000000
0000000000000000000000000bbb7b700bbb7b7b0bbbbbb000dd7d7000dd7d7000dd7d7000000000000000000000000000000000000000000000000000000000
0000000000000000000000000bbb7b700bbbbbbbbbbb7b7b00ddddd000dd7d7000dd7d7000000000000000000000000000000000000000000000000000000000
0000000000000000000000000bbbbbb00bbbbbb0bbbb7b7b000ddd0000ddddd000ddddd000000000000000000000000000000000000000000000000000000000
00000000000000000000000000bbbb0000bbbb000bbbbbbb000ddd00000ddd00000ddd0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000d000d000d000d0000d0d0000000000000000000000000000000000000000000000000000000000
__map__
0303030303030300000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300040400000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300040400000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000404040400000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000400000400000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000400000400000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000404040400000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000404000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000404000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030300000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011000002653226500265002153020531205002153021500265322650026500295302853128500295302950026532265002650021530205312050021530215002353024530235302453021532215002150021500
011000000c17300000000000c17300000000000c173000000c6550c6000c6000c600000000000000000000000c1730c6000c6000c6550c173000000c655000000c1730c1730c1000c1730c655000000000000000
01100000325322650026500305302f531205002d530215002c5322d5502c5502d5302953129532285302950026532265002650021530205312050021530215001d5301d0001a5321a0001c5311c5322150021500
__music__
01 00014344
00 00014344
00 02014344
02 02014344

