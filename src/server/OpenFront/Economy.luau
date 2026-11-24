--!strict
-- EngineConfig gold rules, PlayerImpl accounting, GameImpl conquest; revision 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; modified 2026-11-18.
local Gold = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Gold)
local Economy={}
function Economy.initial(kind,config,host)
 if kind=="Bot" then return "0" end
 local base=Gold.from(config.StartingGold or "0")
 if host and config.HostStartingGold then base=Gold.add(base,Gold.from(config.HostStartingGold)) end
 return base
end
function Economy.rate(kind,config,host)
 local multiplier=config.GoldMultiplier or 1
 if host and config.HostGoldMultiplier and config.HostGoldMultiplier~=0 then multiplier=config.HostGoldMultiplier end
 assert(typeof(multiplier)=="number" and multiplier>=0 and multiplier<math.huge)
 return Gold.from(math.floor((if kind=="Bot" then 50 else 100)*multiplier))
end
function Economy.add(p,amount)
 assert(Gold.valid(amount));p.Gold=Gold.add(p.Gold,amount);p.GoldEarned=Gold.add(p.GoldEarned,amount)
end
function Economy.remove(p,amount)
 assert(Gold.valid(amount));local actual=if Gold.compare(p.Gold,amount)<0 then p.Gold else amount
 p.Gold=Gold.subtract(p.Gold,actual);return actual
end
function Economy.new(sim,config)
 config=config or {}
 local start=Gold.from(config.StartingGold or "0");assert(Gold.compare(start,"1000000000")<=0,"startingGold schema maximum")
 for _,key in ipairs({"GoldMultiplier","HostGoldMultiplier"}) do local v=config[key];if v~=nil then assert(typeof(v)=="number" and v==v and v>=0.1 and v<=1000,"goldMultiplier schema bounds") end end
 local api={};local products={};local sequences={};local receipts={};local donations={}
 local function live(p)return p and sim.Players[p.UserId]==p and not p.Spectator and (sim.Grid.Counts[p.SmallId] or 0)>0 end
 function api.init(p)
  p.IsHost=config.HostUserId~=nil and p.UserId==config.HostUserId
  p.Gold=Economy.initial(p.Kind,config,p.IsHost);p.GoldEarned="0";p.AttacksSent="0"
 end
 function api.attackSent(p,n)
  local value=p.AttacksSent;local negative=string.sub(value,1,1)=="-";local a=if negative then string.sub(value,2) else value
  local delta=math.floor(n);local b=Gold.from(math.abs(delta));local sign=delta<0
  if negative==sign then local v=Gold.add(a,b);p.AttacksSent=(if negative and v~="0" then "-" else "")..v
  else local compare=Gold.compare(a,b);local v=if compare>=0 then Gold.subtract(a,b) else Gold.subtract(b,a)
   p.AttacksSent=(if v~="0" and (if compare>=0 then negative else sign) then "-" else "")..v end
 end
 function api.income(p)return Economy.rate(p.Kind,config,p.IsHost) end
 function api.multiplier(p)
  if p.IsHost and config.HostGoldMultiplier and config.HostGoldMultiplier~=0 then return config.HostGoldMultiplier end
  return config.GoldMultiplier or 1
 end
 function api.tick(p)Economy.add(p,api.income(p)) end
 function api.death(p)Economy.remove(p,p.Gold) end
 function api.conquest(winner,loser)
  if loser.Kind=="Human" and (loser.AttacksSent or "0")=="0" then return "0" end
  local loot=if loser.Kind=="Human" then Gold.half(loser.Gold) else loser.Gold
  Economy.add(winner,loot);Economy.remove(loser,loser.Gold);return loot
 end
 function api.isFree(p)return p.Kind=="Human" and (config.InfiniteGold==true or (config.HostInfiniteGold==true and p.IsHost)) end
 -- Server-owned catalog and prices; clients never supply prices or balances.
 function api.register(key,cost,validate)
  assert(typeof(key)=="string" and products[key]==nil and typeof(cost)=="function")
  products[key]={Cost=cost,Validate=validate}
 end
 function api.purchase(p,sequence,key,context)
  if not p or sim.Players[p.UserId]~=p then return {OK=false,Reason="player"},false end
  if typeof(key)~="string" then return {OK=false,Reason="product"},false end
  if typeof(sequence)~="number" or sequence%1~=0 or sequence<1 or sequence>9007199254740991 then return {OK=false,Reason="sequence"},false end
  local last=sequences[p] or 0
  if sequence==last then if key~=receipts[p].Product then return {OK=false,Reason="sequence_reused"},false end;return table.clone(receipts[p]),false end
  if sequence<last then return {OK=false,Reason="stale"},false end
  local receipt={OK=false,Sequence=sequence,Product=key,Tick=sim.Tick,Reason="invalid"}
  local product=if typeof(key)=="string" then products[key] else nil
  if sim.Phase=="Started" and live(p) and product and (not product.Validate or product.Validate(p,sim,context)) then
   local free=p.Kind=="Human" and (config.InfiniteGold==true or (config.HostInfiniteGold==true and p.IsHost))
   local cost=if free then "0" else product.Cost(p,sim,context)
   if Gold.valid(cost) and Gold.compare(p.Gold,cost)>=0 then
    Economy.remove(p,cost);receipt.OK=true;receipt.Cost=cost;receipt.Reason=nil;receipt.Balance=p.Gold
   else receipt.Reason="funds_or_cost" end
  end
  sequences[p]=sequence;receipts[p]=receipt
  return table.clone(receipt),true
 end
 function api.donate(sender,recipient,amount)
  if sim.Phase~="Started" or not live(sender) or not live(recipient) or sender==recipient or not sim.friendly(sender,recipient) then return false end
  if recipient.Kind=="Human" and config.DonateGold==false then return false end
  if not Gold.valid(amount) or amount=="0" then return false end
  local sent=donations[sender] or {};local last=sent[recipient]
  if last and sim.Tick-last<100 then return false end
  local removed=Economy.remove(sender,amount);if removed=="0" then return false end
  Economy.add(recipient,removed);sent[recipient]=sim.Tick;donations[sender]=sent;return true,removed
 end
 function api.leave(p)sequences[p]=nil;receipts[p]=nil;donations[p]=nil;for _,sent in pairs(donations) do sent[p]=nil end end
 return api
end
return Economy
