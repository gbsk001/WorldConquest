for _,cells in ipairs({1048576,4194304,8388608}) do
 local g=Grid.new(8192,4096,function()return 128 end)
 local before=gcinfo();local began=os.clock()
 for t=0,cells-1 do g.setOwnerID(t,1) end
 local write=(os.clock()-began)*1000;local dirtyHeap=gcinfo();began=os.clock();local delta=g.drain();local pack=(os.clock()-began)*1000
 local snapshots={};began=os.clock();local pages=g.snapshotPages()
 for i=1,100 do snapshots[i]=pages end
 local snapshot=(os.clock()-began)*1000
 g.setOwnerID(0,2);assert(buffer.readu16(pages[1].Data,0)==1)
 print(string.format('MEMORY %d cells: writes %.1f ms packing %.1f ms snapshot shared by 100 joins %.3f ms; grid %d delta %d B; heap before %.0f dirty %.0f after %.0f KiB.',cells,write,pack,snapshot,g.allocatedBytes(),buffer.len(delta),before,dirtyHeap,gcinfo()))
end
