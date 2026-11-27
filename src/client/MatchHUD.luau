--!strict
-- Live presentation uses authoritative territory counts; victory remains server-owned.
local Money=require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)
local Ranking=require(game:GetService("ReplicatedStorage").Shared.TerritoryRanking)
local Map=require(game:GetService("ReplicatedStorage").Shared.Map)
local Art=require(script.Parent.InterfaceArt)
local Cosmetic=require(script.Parent.CosmeticArt)
local TweenService=game:GetService("TweenService")
local HUD={}
local crownColors={Color3.fromRGB(239,197,91),Color3.fromRGB(204,216,234),Color3.fromRGB(203,142,91)}
function HUD.new(parent,locate,localUserId)
 local panel=Instance.new("ScrollingFrame");panel.Name="MatchResults";panel.Position=UDim2.new(1,-10,0,8);panel.AnchorPoint=Vector2.new(1,0);panel.Size=UDim2.new(1,-20,1,-16);panel.BackgroundColor3=Color3.fromRGB(16,29,42);panel.BackgroundTransparency=.14;panel.BorderSizePixel=0;panel.ScrollBarThickness=3;panel.Visible=false;panel.ZIndex=45;panel.Parent=parent
 local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(290,500);limit.Parent=panel
 local title=Instance.new("TextLabel");title.Position=UDim2.fromOffset(12,8);title.Size=UDim2.new(1,-52,0,50);title.BackgroundTransparency=1;title.TextSize=15;title.Font=Enum.Font.GothamBold;title.TextColor3=Color3.fromRGB(230,237,244);title.TextXAlignment=Enum.TextXAlignment.Left;title.TextWrapped=true;title.ZIndex=46;title.Parent=panel
 local toggle=Instance.new("TextButton");toggle.Text="Leaderboard";toggle.Size=UDim2.fromOffset(108,26);toggle.Parent=parent
 local rows={};local pool={};local latest=nil;local lastMatch=nil;local previousPhase=nil;local api={}
 toggle.Activated:Connect(function()panel.Visible=not panel.Visible end)
 local function newRow()
  local row=Instance.new("TextButton");row.Name="RankingCard";row.Text="";row.AutoButtonColor=false;row.BorderSizePixel=0;row.BackgroundTransparency=.1;row.ZIndex=46;row.Size=UDim2.new(1,-16,0,35);row.Parent=panel
  local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,7);round.Parent=row
  local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(27,0);t.Size=UDim2.new(1,-96,1,-5);t.Font=Enum.Font.GothamMedium;t.TextSize=12;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextColor3=Color3.fromRGB(229,237,247);t.ZIndex=47;t.Parent=row
  local bar=Instance.new("Frame");bar.BorderSizePixel=0;bar.Position=UDim2.new(0,4,1,-3);bar.Size=UDim2.fromOffset(0,2);bar.ZIndex=47;bar.Parent=row
  t.AutoLocalize=false;t.RichText=false
  t.TextTruncate=Enum.TextTruncate.AtEnd;t.TextWrapped=false
  local function small(name,x,size,align)
   local label=Instance.new("TextLabel");label.Name=name;label.BackgroundTransparency=1;label.Position=x;label.Size=size;label.TextSize=12;label.Font=Enum.Font.GothamBold;label.TextColor3=Color3.fromRGB(231,238,247);label.TextXAlignment=align;label.TextWrapped=false;label.ZIndex=47;label.Parent=row;return label
  end
  local rankLabel=small("Rank",UDim2.fromOffset(2,0),UDim2.fromOffset(24,30),Enum.TextXAlignment.Center)
  local share=small("Territory",UDim2.new(1,-65,0,0),UDim2.fromOffset(59,30),Enum.TextXAlignment.Right)
  local record={Root=row,Text=t,Bar=bar,Rank=rankLabel,Share=share}
  row.Activated:Connect(function()local p=record.Player;if locate and p and p.X then locate(p.LabelX or p.X,p.LabelY or p.Y)end end)
  return record
 end
 local function paint()
  if not latest or not panel.Visible then return end
  local state=latest;local done=state.Phase=="Victory"or state.Phase=="Results"
  local ranked=if done then state.Rankings or {}else Ranking.sorted(state.Players or state.Rankings or {})
  title.Text=if done then (if state.Winner and state.Winner.Draw then "MATCH ENDED"else "VICTORY").." / "..(state.Winner and state.Winner.Name or "").."\nMenu in "..math.max(0,math.ceil(((state.RestartAt or state.Tick)-state.Tick)/10)).."s"else "TERRITORY / TOP 10\n"..#ranked.." remaining"
  local shown={};local ranks={};local own=nil
  for rank,p in ipairs(ranked)do
   if done or rank<=10 then table.insert(shown,p);ranks[p.UserId or p.SmallId or p.Username]=rank end
   if p.UserId==localUserId then own={Player=p,Rank=rank}end
  end
  if not done and own and own.Rank>10 then table.insert(shown,own.Player);ranks[own.Player.UserId]=own.Rank end
  local pitch=if done then 39 else math.clamp(math.floor((panel.AbsoluteSize.Y-64)/math.max(1,#shown)),24,39)
  local wanted={};for _,p in ipairs(shown)do wanted[p.UserId or p.SmallId or p.Username]=true end
  for id,r in pairs(rows)do if not wanted[id]then if r.Tween then r.Tween:Cancel();r.Tween=nil end;r.Root.Visible=false;rows[id]=nil;table.insert(pool,r)end end
  for index,p in ipairs(shown)do
   local id=p.UserId or p.SmallId or p.Username;local rank=ranks[id];local r=rows[id]
   if not r then r=table.remove(pool)or newRow();rows[id]=r;r.Index=nil end
   r.Player=p;r.Root.Visible=true
   r.Root.Size=UDim2.new(1,-16,0,pitch-3)
   local position=UDim2.fromOffset(8,62+(index-1)*pitch)
   if r.Index~=index or r.Pitch~=pitch then
    if r.Tween then r.Tween:Cancel()end
    if r.Index then r.Tween=TweenService:Create(r.Root,TweenInfo.new(.18,Enum.EasingStyle.Quad),{Position=position});r.Tween:Play()else r.Root.Position=position end
    r.Index=index;r.Pitch=pitch
   end
   r.Root.BackgroundColor3=if p.UserId==localUserId then Color3.fromRGB(31,61,78)else Color3.fromRGB(24,35,49)
   local percent=(p.Count or 0)/math.max(1,Map.LandCount)*100
   local text=p.Username;r.Rank.Text=tostring(rank);r.Share.Text=string.format("%.2f%%",percent)
   if r.Text.Text~=text then r.Text.Text=text end
   local flagID=p.Cosmetics and p.Cosmetics.Flag
   if r.FlagID~=flagID then
    if r.Flag then r.Flag:Destroy();r.Flag=nil end
    r.FlagID=flagID;if flagID then r.Flag=Cosmetic.flag(r.Root,flagID,20);if r.Flag then r.Flag.Position=UDim2.fromOffset(27,7)end end
    r.Text.Position=UDim2.fromOffset(if flagID then 51 else 27,0);r.Text.Size=UDim2.new(1,if flagID then -120 else -96,1,-5)
   end
   r.Bar.BackgroundColor3=p.Color or Color3.fromRGB(108,172,207);r.Bar.Size=UDim2.new(math.clamp((p.Count or 0)/math.max(1,ranked[1]and ranked[1].Count or 1),0,1),-8,0,2)
   local crown=if state.Phase=="Started"and rank<=3 then rank else 0;r.Rank.Visible=crown==0
   if r.CrownRank~=crown then
    if r.Crown then r.Crown:Destroy();r.Crown=nil end
    if crown>0 then r.Crown=Art.icon(r.Root,"Crown",18,Cosmetic.tint(p.Cosmetics,"Crown",crownColors[crown]));r.Crown.Position=UDim2.fromOffset(4,5)end
    r.CrownRank=crown
   end
  end
  -- Result rosters may be long; live mode owns at most eleven cards.
  while #pool>11 do table.remove(pool).Root:Destroy()end
  panel.CanvasSize=UDim2.fromOffset(0,66+#shown*pitch)
 end
 panel:GetPropertyChangedSignal("Visible"):Connect(paint)
 panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(paint)
 function api.update(state)
  latest=state
  if state.MatchID~=lastMatch then panel.Visible=false;lastMatch=state.MatchID;previousPhase=nil end
  if state.Phase=="Started"and previousPhase~="Started"then panel.Visible=false end -- Live rankings are opened explicitly; results still open automatically.
  if (state.Phase=="Victory"or state.Phase=="Results")and previousPhase~="Victory"and previousPhase~="Results"then panel.Visible=true end
  if state.Phase=="Victory"and previousPhase~="Victory"and state.Winner and state.Winner.UserId==localUserId then
   for _,p in ipairs(state.Players or {})do if p.UserId==localUserId and p.Cosmetics and p.Cosmetics.Victory then
    title.TextColor3=Cosmetic.tint(p.Cosmetics,"Victory",Color3.fromRGB(230,237,244));title.TextTransparency=.55
    TweenService:Create(title,TweenInfo.new(.6,Enum.EasingStyle.Quad),{TextTransparency=0}):Play()
   end end
  end
  previousPhase=state.Phase;paint()
 end
 api.Panel=panel;api.Toggle=toggle
 return api
end
return HUD
