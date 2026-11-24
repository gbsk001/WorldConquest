do
 local t={Width=8192,Height=4096,MaskHash='recovery',byte=function()return 128 end}
 local g=Grid.new(t.Width,t.Height,t.byte)
 g.setOwnerID(0,1);g.setOwnerID(4096,2)
 local a,b=g.snapshotPages(),g.snapshotPages();assert(a[1].Data==b[1].Data)
 g.setOwnerID(0,3);assert(buffer.readu16(a[1].Data,0)==1 and g.ownerID(0)==3)
 local c=g.snapshotPages();g.setOwnerID(0,0);assert(buffer.readu16(c[1].Data,0)==3)
 g.setOwnerID(0,4);assert(buffer.readu16(a[1].Data,0)==1)
 local r=Replica.new(t)
 assert(r.begin({ID=1,Tick=0,Count=#a,MapHash=t.MaskHash,Meta={Stage=6,Players={}}}))
 for _,p in ipairs(a) do assert(r.chunk({ID=1,Key=p.Key,Data=p.Data}));assert(r.chunk({ID=1,Key=p.Key,Data=p.Data})) end
 assert(r.finish({ID=1}) and r.Grid.ownerID(0)==1)
 local original=r.Grid
 assert(not r.delta({Tick=2,Changes=buffer.create(0)})) -- missing tick
 assert(r.Tick==0 and r.Grid==original)
 assert(r.begin({ID=2,Tick=10,Count=0,MapHash=t.MaskHash,Meta={Stage=6,Players={}}}))
 assert(r.delta({Tick=12,Changes=buffer.create(0)}))
 assert(not r.finish({ID=2}) and r.Grid==original and r.Tick==0)
 assert(r.begin({ID=3,Tick=20,Count=0,MapHash=t.MaskHash,Meta={Stage=6,Players={}}}))
 for i=1,2048 do assert(r.delta({Tick=20+i,Changes=buffer.create(0)})) end
 assert(not r.delta({Tick=2069,Changes=buffer.create(0)}) and not r.loading())
 assert(r.begin({ID=4,Tick=300,Count=0,MapHash=t.MaskHash,Meta={Stage=6,Players={}}}))
 local huge=buffer.create(6*1024*1024)
 assert(r.delta({Tick=301,Changes=huge}));assert(r.delta({Tick=302,Changes=huge}))
 assert(not r.delta({Tick=303,Changes=huge}) and not r.loading() and r.Grid==original)
 assert(not r.delta({Tick=1,Changes=buffer.create(0),Parts=0/0,Part=1}))
 assert(not r.delta({Tick=1,Changes=buffer.create(0),ShipChanges='forged'}))
 assert(r.begin({ID=5,Tick=400,Count=0,MapHash=t.MaskHash,Meta={Stage=6,Players={}}}));assert(r.finish({ID=5}))
 assert(r.delta({Tick=401,Changes=buffer.create(0)}))
 print('Stage 7 copy-on-write snapshots, duplicate pages, gap rollback, bounded catch-up memory, malformed fragments and successful resync passed.')
end
-- Length guard never changes an accepted original path, including shore/turn ties.
do
 local rng=Random32.new(771)
 for case=1,160 do
  local terrain={};for t=0,4095 do terrain[t]=if rng.nextInt(0,8)==0 then 32 else 128 end
  local g=Grid.new(64,64,function(t)return terrain[t] end)
  local a,b=rng.nextInt(0,4096),rng.nextInt(0,4096);local limit=110*1.4142
  local original=RailPath.land(g,a,b);local guarded=RailPath.land(g,a,b,limit)
  if original and #original<limit then
   assert(guarded and #guarded==#original);for i,t in ipairs(original) do assert(guarded[i]==t) end
  elseif guarded then assert(#guarded>=limit) end
 end
 print('Stage 7 160 random guarded rail searches preserve every accepted path and tie order.')
end
-- Culling, reuse and minimal property writes without pretending to emulate the GPU.
do
 local created,destroyed,writes=0,0,0
 local layer=IconLayer.new(8192,function()
  created+=1;return setmetatable({Destroy=function()destroyed+=1 end},{__newindex=function(t,k,v)writes+=1;rawset(t,k,v)end})
 end,function(u,colors,set)set('Tile',u.Tile);set('Color',colors[u.Owner]);set('Kind',u.Type) end)
 local units={};for i=1,10000 do units[i]={ID=i,Tile=i*2,Owner=1,Type='Warship'} end
 layer.set(units,{[1]=1});local began=os.clock();layer.update(0,0,1,200,100);local first=(os.clock()-began)*1000
 assert(layer.Visible<400 and created==layer.Visible)
 local previous=writes;layer.update(0,0,1,200,100);assert(writes==previous)
 layer.update(-500,0,1,200,100);assert(layer.Pooled<=128)
 layer.set({},{});layer.update(0,0,1,200,100);assert(layer.Visible==0 and layer.Pooled<=128)
 layer.destroy();assert(created==destroyed)
 print(string.format('Stage 7 10000-unit icon culling: %.3f ms CPU; stationary frame skips work; visible labels only, bounded pool and cleanup passed (no Roblox GUI/GPU).',first))
end
