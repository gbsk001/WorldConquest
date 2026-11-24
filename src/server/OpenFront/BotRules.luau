--!strict
-- NationExecution / AiAttackBehavior / NationAttackBehavior, OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Rules={}
Rules.Rates={Easy={65,100},Normal={55,70},Hard={45,60}}
Rules.SAMRatio={Easy=0.15,Normal=0.2,Hard=0.25}
function Rules.personality(random,difficulty)
 local rate=assert(Rules.Rates[difficulty],"Unknown bot difficulty")
 local p={Trigger=random.nextInt(50,60)/100,Reserve=random.nextInt(30,40)/100,Expand=random.nextInt(10,20)/100}
 p.Rate=random.nextInt(rate[1],rate[2]);p.Offset=random.nextInt(0,p.Rate);return p
end
function Rules.sendTroops(home,cap,ratio)return math.max(0,home-cap*ratio)end
function Rules.humanTarget(random,difficulty)
 if difficulty=="Easy" then return random.nextInt(0,4)==0 end
 if difficulty=="Normal" then return random.nextInt(0,4)~=0 end
 return true
end
function Rules.threatCap(home,strongest,incoming,difficulty,team)
 if difficulty~="Hard" or team or strongest==0 then return math.huge end
 return math.max(0,home-math.ceil(strongest*0.75),incoming)
end
-- Direct grid-sampled NationNukePlanning.enemyLandBlastCoverage translation.
function Rules.coverage(grid,player,owner,friendly,center,inner,outer)
 local step=math.max(1,math.floor(outer/10));local total,enemy=0,0
 local cx,cy=center%grid.Width,math.floor(center/grid.Width)
 for dy=-outer,outer,step do for dx=-outer,outer,step do
  local distance=dx*dx+dy*dy;if distance>outer*outer then continue end
  local weight=if distance<=inner*inner then 2 else 1;total+=weight
  local x,y=cx+dx,cy+dy
  if x>=0 and y>=0 and x<grid.Width and y<grid.Height then
   local target=owner(grid.ownerID(grid.ref(x,y)))
   if target and not friendly(player,target) then enemy+=weight end
  end
 end end
 return enemy/total
end
function Rules.friendlyBlast(grid,player,owner,friendly,center,outer)
 local cx,cy=center%grid.Width,math.floor(center/grid.Width)
 for dy=-outer,outer do for dx=-outer,outer do
  if dx*dx+dy*dy>outer*outer then continue end
  local x,y=cx+dx,cy+dy
  if x>=0 and y>=0 and x<grid.Width and y<grid.Height then local target=owner(grid.ownerID(grid.ref(x,y)));if target and friendly(player,target) then return true end end
 end end
 return false
end
return Rules
