--!strict
-- Presentation ranking of authoritative counts; never samples the ownership map.
local Ranking={}
function Ranking.sorted(players)
 local rows={}
 for _,p in ipairs(players)do
  if not p.BasicNation and not p.Eliminated and not p.Spectator and not p.Disconnected and (p.Count or 0)>0 then table.insert(rows,p)end
 end
 table.sort(rows,function(a,b)
  if a.Count~=b.Count then return a.Count>b.Count end
  if (a.SmallId or 0)~=(b.SmallId or 0)then return (a.SmallId or 0)<(b.SmallId or 0)end
  return (a.UserId or 0)<(b.UserId or 0)
 end)
 return rows
end
function Ranking.crowns(players,phase)
 local crowns={}
 if phase~="Started" then return crowns end
 for rank,p in ipairs(Ranking.sorted(players))do if rank>3 then break end;crowns[p.UserId]=rank end
 return crowns
end
return Ranking
