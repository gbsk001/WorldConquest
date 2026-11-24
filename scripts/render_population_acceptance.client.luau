-- Disposable native-renderer benchmark; no gameplay/capacity certification.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Stats=game:GetService("Stats")
local startupClock=os.clock();local startupWorst=0
local startupFrames=Run.RenderStepped:Connect(function(dt)startupWorst=math.max(startupWorst,dt*1000)end)
local Map=require(game.ReplicatedStorage.Shared.Map)
local View=require(Players.LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("MapView"))
local gui=Instance.new("ScreenGui");gui.Name="RendererAcceptance";gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.None;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=Players.LocalPlayer.PlayerGui
local viewport=Instance.new("Frame");viewport.Position=UDim2.fromOffset(0,90);viewport.Size=UDim2.new(1,0,1,-220);viewport.Parent=gui
local label=Instance.new("TextLabel");label.Size=UDim2.new(1,0,0,130);label.Position=UDim2.new(0,0,1,-130);label.BackgroundColor3=Color3.fromRGB(9,18,29);label.TextColor3=Color3.new(1,1,1);label.TextSize=14;label.TextWrapped=true;label.ZIndex=100;label.Parent=gui
local heading=label:Clone();heading.Position=UDim2.fromOffset(0,40);heading.Size=UDim2.new(1,0,0,48);heading.Text="NATIVE RENDER TEST / 500 synthetic participants / 3000 buildings / no server simulation";heading.Parent=gui
local view=View.new(viewport,function()end,function()end);assert(view,"EditableImage unavailable")
local random=Random.new(71);local owners={};local rows={};local buildings={}
for i=1,500 do
 if i%16==0 then task.wait()end
 local x,y,cell
 repeat x=random:NextInteger(0,8191);y=random:NextInteger(0,4095);cell=Map.cell(x,y)until cell and Map.isLand(cell)
 rows[i]={UserId=if i==1 then Players.LocalPlayer.UserId else -i,Username="RenderPlayer"..i,SmallId=i,Color=Color3.fromHSV((i*.618)%1,.65,.9),Spawn=cell,X=x+.5,Y=y+.5,Count=100+i,Troops=25000}
 for d=0,5 do buildings[#buildings+1]={ID=#buildings+1,Type=({"City","Factory","DefensePost","Port","SAMLauncher","MissileSilo"})[d+1],Tile=cell-1+d*20,Owner=i,Level=1}end
 for yy=math.max(0,y-8),math.min(4095,y+8)do for xx=math.max(0,x-8),math.min(8191,x+8)do local c=yy*8192+xx;if Map.isLand(c+1)then owners[c]=i end end end
end
local grid={ownerID=function(c)return owners[c]or 0 end,state=function()return 0 end,isBorder=function(c)local o=owners[c];return o~=nil and (owners[c-1]~=o or owners[c+1]~=o or owners[c-8192]~=o or owners[c+8192]~=o)end}
view.setGrid(grid)
local state={Foundation=true,Stage=11,Phase="Started",MatchID=1,Tick=1,Players=rows,Buildings=buildings,Ships={},Rankings={}}
local allRows,allBuildings=rows,buildings
local counts={20,50,100,200,250,500};local testIndex=1;local setupClock=os.clock()
local function configure()
 rows={};buildings={}
 for i=1,counts[testIndex]do rows[i]=allRows[i]end
 for i=1,counts[testIndex]*6 do buildings[i]=allBuildings[i]end
 state.Players=rows;state.Buildings=buildings;view.clear();view.setGrid(grid);view.render(state)
 heading.Text="NATIVE RENDER / "..counts[testIndex].." synthetic participants / "..#buildings.." buildings"
 setupClock=os.clock()
end
configure()
print(string.format("CLIENT_STARTUP load_seconds %.3f worst_frame_ms %.3f",os.clock()-startupClock,startupWorst));startupFrames:Disconnect()
local results={};local phase=0;local began=os.clock();local times={};local lastUpdate=0;local iterations=0;local memory=0;local heap=0
local function finish()
 if #times==0 then return end
 table.sort(times);local sum=0;for _,v in ipairs(times)do sum+=v end
 local avg=sum/#times;local text=string.format("%s: %.1f FPS / avg %.2f p95 %.2f worst %.2f ms / total %.1f MiB heap %.1f MiB",({"warmup","overview","detail","zoom/pan"})[phase+1],1000/avg,avg,times[math.ceil(#times*.95)],times[#times],memory,heap/1024)
 table.insert(results,text);print("PERFORMANCE_RENDER "..counts[testIndex].." "..text);print("RENDER_OBJECTS",counts[testIndex],#gui:GetDescendants(),viewport.Earth:GetAttribute("IconAtlasEnabled"));label.Text=table.concat(results,"\n");table.clear(times)
end
local connection
connection=Run.RenderStepped:Connect(function(dt)
 local elapsed=os.clock()-began;local nextPhase=math.min(3,math.floor(elapsed/12))
 if nextPhase~=phase then finish();phase=nextPhase end
 times[#times+1]=dt*1000;memory=math.max(memory,Stats:GetTotalMemoryUsageMb());heap=math.max(heap,gcinfo())
 if elapsed-lastUpdate>.25 then
  lastUpdate=elapsed;iterations+=1
  if phase==1 then view.reset()
  elseif phase==2 then view.focus(rows[1].X,rows[1].Y);view.zoomBy(8)
  elseif phase==3 then view.focus(rows[1].X+math.sin(iterations*.25)*200,rows[1].Y);view.zoomBy(if iterations%2==0 then 2 else 8)end
  local packed=buffer.create(1024*6)
  for i=0,1023 do local x=math.clamp(math.floor(rows[1].X)+i%32-16,0,8191);local y=math.clamp(math.floor(rows[1].Y)+math.floor(i/32)-16,0,4095);local c=y*8192+x;local owner=if iterations%2==0 then 1 else 2;if Map.isLand(c+1)then owners[c]=owner end;buffer.writeu32(packed,i*6,c);buffer.writeu16(packed,i*6+4,owner)end
  view.foundationDelta(packed,grid);state.Tick+=2;view.render(state)
 end
 if elapsed>=48 then
  finish();testIndex+=1
  if testIndex>#counts then connection:Disconnect();heading.Text="COMPLETE / synthetic renderer only";return end
  configure();phase=0;began=os.clock();lastUpdate=0;memory=0;heap=0;label.Text="Loading next population..."
 end
end)
