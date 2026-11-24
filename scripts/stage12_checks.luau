for _,name in ipairs({"United Isles","日本国","République française","المملكة العربية","भारत","대한민국","Україна","São Paulo"})do assert(Names.validate(name)==name,name)end
for _,bad in ipairs({"a","",string.rep("a",33),"aa\nxx","<b>Hi</b>","###",utf8.char(0x202E).."secret","\255\255","https://example.com","  ",utf8.char(0x200B).."Name"})do assert(not Names.validate(bad),"invalid name accepted")end
assert(Names.validate("  United   Isles  ")=="United Isles")
local calls=0;local filter={FilterStringAsync=function(_,text,user,context)
 calls+=1;assert(user==17 and context=="PublicChat")
 return {GetNonChatStringForBroadcastAsync=function()return if text=="Rejected"then "########"else text end}
end}
assert(Names.filter("日本国",17,filter)=="日本国");assert(not Names.filter("Rejected",17,filter));assert(calls==2)
assert(not Names.filter("Name",17,{FilterStringAsync=function()error("Roblox outage")end}))
assert(Policy.allowed(1,2,{"group-a"},{"group-a","group-b"},"public-a","public-a"))
assert(not Policy.allowed(1,1,{"a"},{"a"},"same","same"))
assert(not Policy.allowed(1,2,{"a"},{"b"},"same","same"))
assert(not Policy.allowed(1,2,{"a"},{"a"},"private","menu"))
assert(not Policy.allowed(1,2,nil,{"a"},"same","same"))
assert(Strings.translate("PLAY","es-es")=="JUGAR")
assert(Strings.translate("PLAY","fr-fr")=="JOUER")
assert(Strings.translate("6 PLAYERS","fr-fr")=="6 JOUEURS")
assert(Strings.translate("123 Stars","es-es")=="123 estrellas")
for _,row in ipairs(Strings.Rows)do assert(#row==3 and utf8.len(row[1])and utf8.len(row[2])and utf8.len(row[3]))end
for _,item in ipairs(Catalog.Items)do
 for _,key in ipairs({"Name","Description"})do local _,known=Strings.translate(item[key],"es-es");assert(known,"Missing cosmetic translation: "..item[key])end
end
assert(Strings.translate("City  $125K\n+250K soldier capacity per completed level","fr-fr")=="Ville  $125K\n+250K de capacité de soldats par niveau terminé")
assert(Strings.translate("Allocate 73%","es-es")=="Asignar 73%")
local disk={};local now=1000000;local fail=false
local ds={UpdateAsync=function(_,key,fn)if fail then error("offline")end;disk[key]=fn(disk[key]);return disk[key]end}
local a=Store.new(ds,function()return now end);local b=Store.new(ds,function()return now end)
local p=a.transact(17,"Daily");assert(p.Stars==25)
p=b.transact(17,"Daily");assert(p.Stars==25)
assert(a.transact(17,"Nation","日本国").NationName=="日本国")
assert(b.transact(17,nil).NationName=="日本国")
local match={ID="real-session-id",Time=now,Eligible=true,Won=true,Territory=20000,Soldiers=5000,HumanEliminations=2}
p=a.transact(17,"Match",match);assert(p.RankingDirty)
local scores={};local outage=true
local data={GetOrderedDataStore=function(_,metric)return {UpdateAsync=function(_,key,fn)if outage then error("index unavailable")end;scores[metric]=scores[metric]or{};scores[metric][key]=fn(scores[metric][key]);return scores[metric][key]end}end}
local w1=Writer.new(data,"profiles",a);assert(not w1.flush(17,p));assert(disk.u17.RankingDirty)
outage=false;local w2=Writer.new(data,"profiles",b);p=b.transact(17,nil);assert(w2.flush(17,p));assert(not disk.u17.RankingDirty)
assert(scores.profiles_Wins["17"]==1 and scores.profiles_HumanEliminations["17"]==2)
local balance=disk.u17.Stars;p=a.transact(17,"Match",match);assert(p.Stars==balance and p.Stats.Wins==1)
local staleRevision=p.StatsRevision;match.ID="next-session";p=b.transact(17,"Match",match);a.transact(17,"Ranked",staleRevision);assert(disk.u17.RankingDirty,"stale indexing acknowledgement")
assert(w2.flush(17,p));assert(scores.profiles_Wins["17"]==2)
fail=true;assert(not b.transact(17,"Buy","flag_aurora"));fail=false;assert(not disk.u17.Owned.flag_aurora)
local fresh=b.transact(17,"Receipt",{ID="receipt-1",Stars=500});assert(a.transact(17,"Receipt",{ID="receipt-1",Stars=500}).Stars==fresh.Stars)
assert(a.transact(17,"Buy","flag_aurora"));assert(b.transact(17,"Equip","flag_aurora").Equipped.Flag=="flag_aurora")
assert(a.transact(17,nil).Owned.flag_aurora)
print("Stage 12: Unicode names in eight scripts, malformed/control/markup/link rejection, filtered-name rejection/outage, scoped voice permissions, bundled ES/FR interface strings passed.")
print("Two independent profile/leaderboard adapters sharing simulated storage: daily and match deduplication, names, receipt deduplication, Stars, inventory/equip, failed purchase, indexing outage recovery and stale-ack protection passed. NOT live Roblox/DataStore/filtering/voice verification.")
