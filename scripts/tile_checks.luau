-- Production tile scheduler, mocked image uploads; no GPU/Studio emulation.
do
 local images, heartbeat = {}, nil
 local settings={MaxImageTiles=4,RenderBudgetSeconds=0}
 local folder={DirtyTiles=DirtyTiles}
 local modules={Map=WorldMap,Config=settings,TilePainter=TilePainter}
 function folder:WaitForChild(name) return modules[name] or folder end
 local asset={}
 function asset:CreateEditableImage(options)
  local img={Size=options.Size,Pixels=buffer.create(258*258*4),Writes=0}
  function img:WritePixelsBuffer(position,size,pixels)
   assert(buffer.len(pixels)==size.X*size.Y*4)
   assert(position.X>=0 and position.Y>=0 and position.X+size.X<=258 and position.Y+size.Y<=258)
   self.Writes+=1; self.LastSize=size
   for row=0,size.Y-1 do buffer.copy(self.Pixels,((position.Y+row)*258+position.X)*4,pixels,row*size.X*4,size.X*4) end
  end
  function img:Destroy() end
  table.insert(images,img); return img
 end
 local services={AssetService=asset,ReplicatedStorage=folder,RunService={Heartbeat={Connect=function(_,f) heartbeat=f; return {Disconnect=function() end} end}}}
 local vectors={new=function(x,y) return {X=x,Y=y} end,zero={X=0,Y=0}}
 local tilesModule=makeTiles({GetService=function(_,name) return services[name] end},{Parent=folder},function(v) return v end,
  {new=function() return {Destroy=function() end} end},vectors,{fromScale=function(x,y) return {X=x,Y=y} end},
  {ResamplerMode={Pixelated=1}},{fromObject=function(v) return v end})
 local raster=OwnershipRaster.new(); raster.setColor(1,220,80,40)
 local tiles=assert(tilesModule.new({},raster))
 tiles.update(0,0,1,250,250)
 for _=1,100 do heartbeat() end
 assert(tiles.ready())
 local image=images[2]
 local cell=WorldMap.cell(100,100)
 raster.set(cell,1,0,false); tiles.invalidate(cell,false); heartbeat()
 assert(image.LastSize.X==1 and image.LastSize.Y==1,"Single-cell changes upload one pixel")
 assert(buffer.readu32(image.Pixels,(101*258+101)*4)==4278190080+220+80*256+40*65536)
 -- A new delta arriving mid-job must survive completion of that job.
 tiles.invalidateAll(); heartbeat()
 raster.set(cell,0,0,false); tiles.invalidate(cell,false)
 for _=1,100 do heartbeat() end
 local expected={Level=0,X=0,Y=0,Pixels=buffer.create(258*258*4),Coverage=buffer.create(258*258)}
 TilePainter.paint(expected,raster,0,true)
 assert(buffer.tostring(image.Pixels)==buffer.tostring(expected.Pixels),"Mid-job delta must reach uploaded image")
 -- Cancel a partial repaint by panning, then return to the same tile.
 tiles.invalidateAll(); heartbeat()
 tiles.update(-2048,0,1,250,250); heartbeat()
 tiles.update(0,0,1,250,250)
 for _=1,150 do heartbeat() end
 assert(tiles.ready() and buffer.tostring(image.Pixels)==buffer.tostring(expected.Pixels))
 local changed=buffer.create(6);buffer.writeu32(changed,0,cell-1)
 raster.set(cell,1,0,false);tiles.invalidateChanges(changed)
 for _=1,100 do heartbeat() end
 TilePainter.paint(expected,raster,0,true)
 assert(buffer.tostring(image.Pixels)==buffer.tostring(expected.Pixels),"Batched border invalidation preserves pixels")
 local many=buffer.create(10000*6)
 for i=0,9999 do buffer.writeu32(many,i*6,(50+i%100)*WorldMap.Width+50+math.floor(i/100)) end
 local began=os.clock()
 for i=0,9999 do local ref=buffer.readu32(many,i*6)
  for _,t in ipairs({ref,ref-1,ref+1,ref-WorldMap.Width,ref+WorldMap.Width}) do tiles.invalidate(t+1,false) end
 end
 local old=(os.clock()-began)*1000;began=os.clock();tiles.invalidateChanges(many)
 print(string.format("10000 ownership changes / visible tile invalidation: five-walk %.3f ms, batched %.3f ms (CPU only).",old,(os.clock()-began)*1000))
 local recovered=false;tiles.OnFailure=function()recovered=true end
 image.WritePixelsBuffer=function()error("simulated device upload failure")end
 tiles.invalidateAll();for _=1,100 do heartbeat()end;assert(recovered,"Runtime upload errors must select recovery renderer")
 tiles.destroy()
 local create=asset.CreateEditableImage
 asset.CreateEditableImage=function()return nil end;assert(tilesModule.new({},raster)==nil)
 asset.CreateEditableImage=function()error("Mesh/Image APIs unavailable")end;assert(tilesModule.new({},raster)==nil)
 asset.CreateEditableImage=function(self,options)local img=create(self,options);img.WritePixelsBuffer=function()error("initial upload unavailable")end;return img end
 assert(tilesModule.new({},raster)==nil)
 asset.CreateEditableImage=create
 print("Image permission denial, allocation exhaustion, initial upload failure and runtime upload recovery passed.")
 print("Tile scheduler passed: one-pixel uploads, concurrent dirty changes, cancelled-job recovery.")
end
