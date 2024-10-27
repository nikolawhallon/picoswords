pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- functions and objects

function closer(t,a,b)
 local adx=abs(t.x-a.x)
 local bdx=abs(t.x-b.x)
 local ady=abs(t.y-a.y)
 local bdy=abs(t.y-b.y)
 if adx+ady < bdx+bdy then
  return a
 else
  return b
 end
end

function is_close(x1,y1,x2,y2)
 if x1-x2>2 then
  return false
 end
 
 if y1-y2>2 then
  return false
 end 

 return true
end


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
  if self.health==0 then
   return
  end
  
  if not a and not b then
   self.swd_out=false
  else
   if self.swd_out==false then
    sfx(12)
   end
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
  
  if self.y < -4 then self.y+=128 end
  if self.y > 124 then self.y-=128 end  

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
  if self.health==0 then
   return
  end
  
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
  for h=0,self.health-1 do
   rectfill(self.x+3 * h,self.y-3,self.x+1+3 * h,self.y-2,11)
  end
 end
}

-- gohos by default
-- override for other enemies
enemy={
 typ='gohos',
 spd=1,
 pause=0,
 x=64,
 y=64,
 dst_x=64,
 dst_y=64,
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
  for k,v in pairs(self.anims) do
   v:update(f)
  end

  if self.pause > 0 then
   self.pause-=1
   return
  end
  --if is_close(self.x,self.y,self.dst_x,self.dst_y) then
  -- return
  --end

  local dx=self.dst_x-self.x
  local dy=self.dst_y-self.y
  local a=atan2(dx,dy)
  local vel_x=self.spd * cos(a)
  local vel_y=self.spd * sin(a)

  if self.typ=='gohos' or not intersects_tile(3,self.x+1+vel_x,self.y+1,6,6) then
   self.x+=vel_x
  end
  if self.typ=='gohos' or not intersects_tile(3,self.x+1,self.y+1+vel_y,6,6) then
   self.y+=vel_y
  end
 end,

 draw=function(self)
  cur=self.anims['move'].cur
  if self.dst_x < self.x then
   spr(cur,self.x,self.y,1,1,true)
  else
   spr(cur,self.x,self.y)
  end
 end
}

-->8
-- game loop

music(0)

-- 'start','game','end'
state='start'

p1=player:new({
 x=20,
 y=20,
})

p2=player:new({
 x=100,
 y=100,
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

enemies={}
gosoh_timer=100
glom_timer=120
blofire_timer=140
skele_timer=160

torches={}
t1=anim:new({
 x=96,
 y=24,
 sprs={48,49,50},
 fpi=3
})
add(torches,t1)
t2=anim:new({
 x=24,
 y=96,
 sprs={48,49,50},
 fpi=3
})
add(torches,t2)

f=0

function init()
 enemies={}
 p1.health=3
 p2.health=3
 p1.score=0
 p2.score=0
end

function _update()
 if state=='start' or state=='end' then
  if btn(4,0) and btn(5,0) then
   init()
   state='game'
  elseif btn(4,1) and btn(5,1) then
   init()
   state='game'
  else
   return
  end
 end

 -- spawn gosohs
 if f % gosoh_timer==0 then
  local a=rnd(1.0)
  gosoh=enemy:new({
   x=64-4+(128 * cos(a)),
   y=64-4+(128 * sin(a)),
   dst_x=64-4+(256 * cos(a+0.5)),
   dst_y=64-4+(256 * sin(a+0.5))
  })
  add(enemies,gosoh)
 end

 -- spawn gloms
 if f % glom_timer==0 then
  local p=rnd({{4,40},{4,80},{120,40},{120,80}})
  glom=enemy:new({
   typ='glom',
   spd=0.5,
   x=p[1],
   y=p[2],
   anims={
    move=anim:new({
     sprs={51,52,53},
     fpi=5
    })
   }
  })
  add(enemies,glom)
 end

 -- spawn blofires
 if f % blofire_timer==0 then
  local p=rnd(torches)
  blofire=enemy:new({
   typ='blofire',
   spd=0.25,
   x=p.x,
   y=p.y,
   anims={
    move=anim:new({
     sprs={35,36},
     fpi=10
    })
   }
  })
  add(enemies,blofire)
 end

 -- spawn skeles
 if f % skele_timer==0 then
  local p=rnd({{60,0},{60,120}})
  skele=enemy:new({
   typ='skele',
   spd=0.75,
   x=p[1],
   y=p[2],
   anims={
    move=anim:new({
     sprs={8,9,10},
     fpi=3
    })
   }
  })
  add(enemies,skele)
 end
 
 -- update objects
 p1:update(f,btn(0,0),btn(1,0),btn(2,0),btn(3,0),btn(4,0),btn(5,0))
 p2:update(f,btn(0,1),btn(1,1),btn(2,1),btn(3,1),btn(4,1),btn(5,1))

 for t in all(torches) do
  t:update(f)
 end

 for enemy in all(enemies) do
  if enemy.typ=='glom' or enemy.typ=='blofire' or enemy.typ=='skele' then
   if p1.health > 0 and p2.health > 0 then
    local p=closer(enemy,p1,p2)
    enemy.dst_x=p.x
    enemy.dst_y=p.y
   elseif p1.health > 0 then
    enemy.dst_x=p1.x
    enemy.dst_y=p1.y
   else
    enemy.dst_x=p2.x
    enemy.dst_y=p2.y
   end
  end
  enemy:update(f)
 end
 
 -- despawn out-of-bounds gosohs
 for enemy in all(enemies) do
  if enemy.typ=='gohos' then
   if enemy.x<-196 or enemy.x>324 or enemy.y<-196 or enemy.y>324 then
    del(enemy, enemies)
   end
  end
 end

 -- enemy player collision
 for _,p in ipairs({p1,p2}) do
  if p.health==0 then
   goto continue
  end
  
  for e in all(enemies) do
   if intersects(e.x,e.y,8,8,p.x,p.y,8,8) then
    p.health-=1
    sfx(14)
    local dx=p.x-e.x
    local dy=p.y-e.y
    local a=atan2(dx,dy)
    if not intersects_tile(3,p.x+6 * cos(a),p.y,8,8) then
     p.x+=6 * cos(a)
    end
    if not intersects_tile(3,p.x,p.y+6 * sin(a),8,8) then
     p.y+=6 * sin(a)
    end
    e.x+=6 * cos(a+0.5)
    e.y+=6 * sin(a+0.5)
    e.pause+=60
   end
  end
  
  ::continue::
 end

 if p1.health==0 and p2.health==0 then
  state='end'
  return
 end
 
 -- enemy sword collision
 for _,p in ipairs({p1,p2}) do
  for enemy in all(enemies) do
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
 
    if intersects(enemy.x,enemy.y,8,8,swdx,swdy,8,8) then
     del(enemies,enemy)
     sfx(13)
     p.score+=1
    end
   end
  end
 end
end

function _draw()
 cls(1)
 map(0,0,0,0,16,16)

 if state=='start' then
  print('pico swords',42,41,14)
  print('press a+b to start',28,82,14)
  return
 elseif state=='end' then
  print('game over',46,41,14)
  print('press a+b to restart',24,82,14)
 end
 
 p1:draw()
 p2:draw()

 for t in all(torches) do
  spr(t.cur,t.x,t.y)
 end

 for enemy in all(enemies) do
  enemy:draw()
 end

 -- ui
 print('p1:',10,9,14)
 print(p1.score,22,9,14)
 print('p2:',99,9,14)
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
000880000008800000088000000000000000bb000000000003300000330000003300000000000000000000000000000000000000000000000000000000000000
008800000008800000008800000bb000000bbbb00000000033ddddd0033000000330000000000000000000000000000000000000000000000000000000000000
00888000008888000008880000bbbb0000bb7b7b00bbbb0000dd7d7000ddddd000ddddd000000000000000000000000000000000000000000000000000000000
0088880000888800008888000bbb7b700bbb7b7b0bbbbbb000dd7d7000dd7d7000dd7d7000000000000000000000000000000000000000000000000000000000
00a88a0000a88a0000a88a000bbb7b700bbbbbbbbbbb7b7b00ddddd000dd7d7000dd7d7000000000000000000000000000000000000000000000000000000000
000aa000000aa000000aa0000bbbbbb00bbbbbb0bbbb7b7b000ddd0000ddddd000ddddd000000000000000000000000000000000000000000000000000000000
000cc000000cc000000cc00000bbbb0000bbbb000bbbbbbb000ddd00000ddd00000ddd0000000000000000000000000000000000000000000000000000000000
000aa000000aa000000aa00000000000000000000000000000d000d000d000d0000d0d0000000000000000000000000000000000000000000000000000000000
__label__
17761776177617761776177617761776177617761776177617761776111111111111111117761776177617761776177617761776177617761776177617761776
17661766176617661766176617661766176617661766176617661766111111111111111117661766176617661766176617661766176617661766176617661766
16661666166616661666166616661666166616661666166616661666111111111111111116661666166616661666166616661666166616661666166616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761776177617761776177617761776177617761776177617761111111111111111177617761776177617761776177617761776177617761776177617761
76617661766176617661766176617661766176617661766176617661111111111111111176617661766176617661766176617661766176617661766176617661
66616661666166616661666166616661666166616661666166616661111111111111111166616661666166616661666166616661666166616661666166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117761776
1766176611eee1ee111111eee11111111111111111111111111111111111111111111111111111111111111111111111111eee1eee11111eee11111117661766
1666166611e1e11e111e11e1e11111111111111111111177771111111111111111111111111111111111111111111111111e1e111e11e11e1e11111116661666
1111111111eee11e111111e1e11111111111111111111616166111111111111111111111111111111111111111111111111eee1eee11111e1e11111111111111
7761776111e1111e111e11e1e11111111111111111111616166111111111111111111111111111111111111111111111111e111e1111e11e1e11111177617761
7661766111e111eee11111eee11111111111111111111166661111111111111111111111111111111111111111111111111e111eee11111eee11111176617661
66616661111111111111111111111111111111111111116161111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111112222111122221111111111111111117171111111111111111111111111111111111111111111111111111111111111111111111117761776
17661766111111112112bb2bb1bb1221111111111111111611111111111111111111111111111111111111111111111111111111111111111111111117661766
16661666111111112112bb2bb1bb1221111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116661666
11111111111111112222111122221111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761111111111111222211112222111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177617761
76617661111111111221222212212112111111111111111111111111111111111111111111111111111111111111111111111111111111111111111176617661
66616661111111111221216666612112111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111226676712222111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111112222116676721111111111111111111111111111111111111111111111111111111111111111111111188111111111111111111117761776
17661766111111112112126666621221111111111111111111111111111111111111111111111111111111111111111111881111111111111111111117661766
16661666111111112112122666121221111111111111111111111111111111111111111111111111111111111111111111888111111111111111111116661666
11111111111111112222116122621111111111111111111111111111111111111111111111111111111111111111111111888811111111111111111111111111
77617761111111111111222211112222111111111111111111111111111111111111111111111111111111111111111111a88a11111111111111111177617761
766176611111111112212112122121121111111111111111111111111111111111111111111111111111111111111111111aa111111111111111111176617661
666166611111111112212112122121121111111111111111111111111111111111111111111111111111111111111111111cc111111111111111111166616661
111111111111111111112222111122221111111111111111111111111111111111111111111111111111111111111111111aa111111111111111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
33333333111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111133333333
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111111111111
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
33333333111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111133333333
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb1111111111111111
1776177611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbb111111117761776
176617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111b7b7bb11111117661766
166616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111b7b7bbb1111116661666
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbb1111111111111
7761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbb1111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbb11111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111111111111111188111111111111111111111111111111111111111111111111111111111111111111122221111222211111111111117761776
1766176611111111111111111188111111111111111111111111111111111111111111111111111111111111111111112112bb2bb1bb12211111111117661766
1666166611111111111111111188811111181811111111111111111111111111111111111111111111111111111111112112bb2bb1bb12211111111116661666
11111111111111111111111111888811111888811111111111111111111111111111111111111111111111111111111122221111222211111111111111111111
77617761111111111111111111a88a1111887878111111111111111111111111111111111111111111111111111111111111ee22111122221111111177617761
766176611111111111111111111aa111118878781111111111111111111111111111111111111111111111111111111112212ee2122121121111111176617661
666166611111111111111111111cc111111888811111111111111111111111111111111111111111111111111111111112212166666121121111111166616661
111111111111111111111111111aa111111111111111111111111111111111111111111111111111111111111111111111112266767122221111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111122221166767211111111111117761776
17661766111111111111111111111111111111111111111111111111111111111111111111111111111111111111111121121266666212211111111117661766
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111121121226661212211111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111122221161226211111111111111111111
77617761111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112222111122221111111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112212112122121121111111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112212112122121121111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112222111122221111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776177617761776177617761776177617761776177617761776111111111111111117761776177617761776177617761776177617761776177617761776
17661766176617661766176617661766176617661766176617661766111111111111111117661766176617661766176617661766176617661766176617661766
16661666166616661666166616661666166616661666166616661666111111111111111116661666166616661666166616661666166616661666166616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761776177617761776177617761776177617761776177617761111111111111111177617761776177617761776177617761776177617761776177617761
76617661766176617661766176617661766176617661766176617661111111111111111176617661766176617661766176617661766176617661766176617661
66616661666166616661666166616661666166616661666166616661111111111111111166616661666166616661666166616661666166616661666166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

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
010a00002603018000210302100020030205002103021500260302650029030295002803028500290302950026030265002103021500200302050021030215002303024030230302403021030215002150021500
110a00000c173000000c6550c1000c173000000c655000000c173000000c6550c6000c173000000c655000000c173000000c6550c1000c173000000c655000000c1730c6000c6550c6550c173000000c65500000
010a0000320302650030030300002f030205002d030210002c0302d0302c0302d0302903029000280302900026030260002103021000200302000021030210001d0301d0001a0301a0001c0301c0002100021000
190a00000e0700e0701d7501400009070090701d750210000e0700e0701d7501400009070090701d750210000e0700e0701d7501400009070090701d750210000907009070197501400004070040701975021000
010a000000000000002175021000000000000021750210000000000000217502100000000000002175021000000000000021750210000000000000217502100000000000001c7501c00000000000001c7501c000
010a00000c173000000c6000c1730c1000c1000c173210000c655000000c1730c1730c1730c1000c1730c1000c173000000c6000c1730c1000c1000c173210000c655000000c1730c1730c1730c1000c1730c100
010a00000207002070020700200002000020000207002070020700207002000020001a7261d72621726247261a7261d72621726247261a7261d726217262472626716297162d716307161a7261d7262172624726
010a00001a0300c00015050000001a0500000020050000002105020050210502005021050000001c050000001a050190001905016000160501400015050000001405000000150500000016050000001505000000
010a00001a0300c00015050000001a0500000020050000002105020050210502005021050000001c050000001d050190001c050160001a0501400019050000001a05000000150500000017050000001905000000
010a00001a0300c00015050000001a0500000020050000002105020050210502005021050000001c050000001d050190001c050160001a0501400019050000001a05000000150000000026050000001900000000
010a00001a0320000000000000001d750000000000000000000000000000000000001d750000000000000000000000000000000000001d750000000000000000000000000000000000001d750000000000000000
010a00000000000000000000000021750000000000000000000000000000000000002175000000000000000000000000000000000000217500000000000000000000000000000000000021750000000000000000
010200000e6501a64026630326201d6001d60021600256002a6002f60035600356000160001600016000160000600006000060000600006000060000600006000060000600006000060000600006000060000600
010400001f3501a350153501035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
450200002433627636297362c1362433627636297362c136000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 40010304
00 40010304
01 40010304
00 40010304
00 00010304
00 00010304
00 02010304
00 02010304
00 00010304
00 00010304
00 02010304
00 02010304
00 0a0b0506
00 0a0b0506
00 0a0b0506
00 0a0b0506
00 070b0506
00 080b0506
00 070b0506
00 090b0506
00 070b0506
00 080b0506
00 070b0506
02 090b0506

