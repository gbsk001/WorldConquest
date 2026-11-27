do
 local mover=UnitMotion.new(8192);local icon=Instance.new("Frame");icon.Visible=true
 local trace=buffer.create(12);buffer.writeu32(trace,0,10*8192+10);buffer.writeu32(trace,4,10*8192+11);buffer.writeu32(trace,8,11*8192+11)
 icon.Position=UDim2.fromScale(10.5/8192,10.5/4096)
 assert(mover.start(icon,{Motion=trace},icon.Position));mover.step(.05)
 assert(icon.Position.X.Scale==11.5/8192 and icon.Position.Y.Scale==10.5/4096,"Rail movement follows the turn, not a diagonal shortcut")
 mover.step(.05);assert(icon.Position.Y.Scale==11.5/4096)
 mover.cancel(icon);mover.step(1)
 print("Authoritative rail-waypoint interpolation, corner traversal and cancellation passed.")
end
do
 local root=Instance.new("Frame");local status=MatchStatus.new(root)
 for _,size in ipairs({{320,568},{390,844},{844,390},{768,1024},{1024,768},{1920,1080}})do
  root.AbsoluteSize=Vector2.new(size[1],size[2])
  status.update({Phase="Started",Tick=102000,StartTick=0},4095,11014740,11014740)
  local panel=status.Panel
  assert(panel.BackgroundTransparency==0 and panel.ZIndex==80)
  assert(panel.Size.X.Offset<=size[1]-16,"Status must fit the safe width even at maximum values")
  assert(panel:FindFirstChild("Timer")and panel:FindFirstChild("Rank")and panel:FindFirstChild("Territory"))
  for _,child in ipairs(panel:GetChildren())do if child.ClassName=="Frame"and child:FindFirstChild("Value")then
   local label=child:FindFirstChild("Value");assert(label.TextSize>=13 and not label.TextWrapped and not label.TextScaled)
   assert(not string.find(label.Text,"WORLD CONQUEST",1,true))
  end end
 end
 local toasts=ToastStack.new(root);toasts.layout(status.Bottom)
 assert(toasts.Root.Position.Y.Offset==status.Bottom+8 and not toasts.Root.Active)
 toasts.push("Expanding along all eligible neutral borders.");assert(#toasts.Root:GetChildren()==0)
 toasts.push("City constructed.","Reward");toasts.push("City constructed.","Reward")
 assert(#toasts.Root:GetChildren()==1 and toasts.Root:GetChildren()[1]:FindFirstChild("Message").Text=="City constructed. ×2")
 for i=1,7 do toasts.push("Warning "..i,"Error")end;assert(#toasts.Root:GetChildren()==3)
 toasts.Root:GetChildren()[1]:FindFirstChild("Dismiss").Activated:Fire();assert(#toasts.Root:GetChildren()==2)
 toasts.preference("Minimal");toasts.push("Routine selection","Info");assert(#toasts.Root:GetChildren()==0)
 toasts.push("Verified purchase","Reward");assert(#toasts.Root:GetChildren()==1)
 toasts.obscured(true);assert(not toasts.Root.Visible);toasts.clear();assert(#toasts.Root:GetChildren()==0)
 print("Stage 15 UI: six safe widths, separate long-value statistic slots, opaque layering, compact toast anchoring, cap, dedupe, dismissal and preferences passed (no rendered verification).")
end
do
 local parent=Instance.new("Frame");local layer=RailLayer.new(parent,8192,false)
 local points=buffer.create(12);buffer.writeu32(points,0,8192*10+10);buffer.writeu32(points,4,8192*10+20);buffer.writeu32(points,8,8192*20+20)
 local function packet(id,version,part,first,last)return {MatchID=id,Version=version,Part=part,First=first,Last=last,Routes={{ID=1,Owner=1,Points=points}}}end
 assert(not layer.receive(packet(1,1,1,true,true),2))
 assert(not layer.receive(packet(2,1,1,true,false),2));layer.update(0,0,1,100,100);assert(#parent:GetChildren()==0)
 assert(layer.receive(packet(2,1,2,false,true),2));layer.update(0,0,1,100,100);assert(#parent:GetChildren()==2)
 layer.update(-1000,-1000,1,100,100);for _,line in ipairs(parent:GetChildren())do assert(not line.Visible)end
 layer.update(0,0,1,100,100);assert(#parent:GetChildren()==2,"Rail objects are pooled")
 layer.clear();for _,line in ipairs(parent:GetChildren())do assert(not line.Visible)end
 print("Stage 15 railway geometry: round validation, atomic cohort install, path turns, offscreen culling, pooling and reset passed.")
end
