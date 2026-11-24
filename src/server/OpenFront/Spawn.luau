--!strict
-- OpenFront Util.getSpawnTiles / GameMapImpl.euclDistFN and BFS order.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Spawn={}
function Spawn.tiles(grid,root,requireAllValid)
 local cx,cy=root%grid.Width-0.5,math.floor(root/grid.Width)-0.5
 local queue,seen,out,neighbors={root},{[root]=true},{},{}
 local head=1
 while head<=#queue do
  local ref=queue[head];head+=1
  if grid.ownerID(ref)==0 and grid.isLand(ref) and not grid.isImpassable(ref) then table.insert(out,ref)
  elseif requireAllValid then return nil end
  local n=grid.neighbors4(ref,neighbors)
  for i=1,n do local t=neighbors[i]
   local dx,dy=t%grid.Width-cx,math.floor(t/grid.Width)-cy
   if not seen[t] and dx*dx+dy*dy<=16 then seen[t]=true;table.insert(queue,t) end
  end
 end
 return out
end
return Spawn
