local function step()now+=.1;beat:Fire(.1)end
for _,p in ipairs(list)do remote.OnServerEvent:Fire(p,"Sync")end
for _=1,5 do step()end
for _,p in ipairs(list)do assert(not replicas[p].Meta,"menu player must not receive game data")end
bridge.Allowed[list[1]]=true;bridge.Allowed[list[2]]=true;bridge.OnBegin({list[1],list[2]})
for _,p in ipairs(list)do remote.OnServerEvent:Fire(p,"Sync")end
for _=1,240 do step()end
local meta=replicas[list[1]].Meta;assert(meta and meta.Stage==10 and meta.MatchID==2 and meta.Phase=="Started")
local bots=0;for _,p in ipairs(meta.Players)do if p.IsBot then bots+=1;assert(p.Username==bridge.BotSettings.Names[-p.UserId-1000000],"Lobby identity must survive simulation and replica") else assert(not p.Spectator,"Stage 10 removes legacy solo admission")end end;assert(bots==5)
assert(not replicas[list[3]].Meta,"unadmitted player cannot receive private snapshots/deltas")
for _=1,300 do step()end
assert(finished==1 and phases.Victory and phases.Results and not next(bridge.Allowed),"results must return to menu, not auto restart")
bridge.BotSettings={Enabled=false,Count=0,Difficulty="Easy"};bridge.Allowed[list[3]]=true;bridge.OnBegin({list[3]})
for _,p in ipairs(list)do remote.OnServerEvent:Fire(p,"Sync")end
for _=1,10 do step()end
local fresh=replicas[list[3]].Meta;assert(fresh.MatchID==3 and #fresh.Players==1 and fresh.Players[1].UserId==3)
assert(replicas[list[1]].Meta.MatchID==2,"old members cannot receive new lobby data")
print("Stage 10 production Foundation: admission gates, no menu/private data leakage, five Normal bots, no solo mode, spawn/game/results/menu and fresh authorized rounds passed (two replicas plus outsider).")
