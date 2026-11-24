local gameVisible=nil;local menu=MainMenu.new(function(active)gameVisible=active end)
local function click(prefix)
 for _,o in ipairs(menu.Gui:GetDescendants())do if o.ClassName=="TextButton"and string.sub(o:GetAttribute("ActionLabel") or o.Text,1,#prefix)==prefix then o.Activated:Fire();return end end
 error("Control missing: "..prefix)
end
assert(not gameVisible and requests[1].Action=="Hello")
click("PLAY");assert(requests[#requests].Action=="Public")
click("PRIVATE MATCH");click("Host a private");assert(requests[#requests].Action=="CreatePrivate")
for _,o in ipairs(menu.Gui:GetDescendants())do if o.ClassName=="TextBox"then o.Text=string.rep("A",32)end end
click("Join private");assert(requests[#requests].Data.Code==string.rep("A",32))
lobbyRemote.OnClientEvent:Fire({Screen="Lobby",MatchType="Private",Host=true,Bots=5,Difficulty="Normal",Code=string.rep("B",32),Players={{UserId=1,Name="Me",Host=true}}})
click("+ Bot");assert(requests[#requests].Data.Count==6)
click("Difficulty:");assert(requests[#requests].Data.Difficulty=="Hard")
click("Invite friends");assert(prompt.LaunchData=="WC10:"..string.rep("B",32))
local previousPrompt=prompt;inviteAllowed=false;click("Invite friends");assert(prompt==previousPrompt);inviteAllowed=true
click("Start match");assert(requests[#requests].Action=="Start")
lobbyRemote.OnClientEvent:Fire({Screen="Game"});assert(gameVisible and not menu.Gui.Enabled)
MainMenu.request("Leave");assert(requests[#requests].Action=="Leave")
lobbyRemote.OnClientEvent:Fire({Screen="Menu"});assert(not gameVisible and menu.Gui.Enabled)
click("Settings");click("Menu UI scale:");assert(player:GetAttribute("MenuScale")==1.1)
click("Map frame budget:");assert(menuConfig.RenderBudgetSeconds==.0015)
for _,size in ipairs({{320,568},{390,844},{844,390},{1366,768},{1920,1080}})do menu.Gui.AbsoluteSize=Vector2.new(size[1],size[2])end
click("Back");click("Tutorial");for _=1,6 do click("Next")end;click("Finish tutorial")
click("Tutorial");click("Skip tutorial")
lobbyRemote.OnClientEvent:Fire({Screen="Lobby",MatchType="Public",Host=true,Bots=5,Difficulty="Normal",Countdown=15,Players={{UserId=1,Name="Me",Host=true}}})
local count=#objects
lobbyRemote.OnClientEvent:Fire({Screen="Lobby",MatchType="Public",Host=true,Bots=5,Difficulty="Normal",Countdown=14,Players={{UserId=1,Name="Me",Host=true}}})
assert(#objects==count,"Countdown must not rebuild lobby GUI")
-- A plain public invitation hint never carries a reserved destination or private code.
lobbyRemote.OnClientEvent:Fire({Screen="Lobby",MatchType="Public",Host=true,Bots=5,Difficulty="Normal",Countdown=14,InviteSession="public-session",Players={{UserId=1,Name="Me",Host=true}}})
click("Invite friends");assert(prompt.LaunchData=="WC10:P:public-session")
click("Leave lobby");assert(requests[#requests].Action=="Leave")
for i,r in ipairs(requests)do assert(r.Sequence==i)end
print("Stage 10 menu: Public/Private/invitations, code/host controls, platform invite request, settings, seven tutorial steps/skip, game/menu transitions, five sizes and allocation-free countdown updates passed (GUI/API stubs, not rendered Studio).")

lobbyRemote.OnClientEvent:Fire({Screen="Lobby",MatchType="Public",Host=false,Bots=2,BotNames={"FrostByte","AlexPro"},Difficulty="Normal",Countdown=10,Players={{UserId=1,Name="Me"}}})
local generated,avatars,counts,disclosure=0,0,false,false
for _,o in ipairs(menu.Gui:GetDescendants())do
 if o.Name=="GeneratedProfile"then generated+=1 end
 if o.ClassName=="ImageLabel"and o.Image and string.find(o.Image,"rbxthumb",1,true)then avatars+=1;assert(string.find(o.Image,"id=1&",1,true))end
 if o.ClassName=="TextLabel"then
  counts=counts or o.Text=="3 PLAYERS"
  disclosure=disclosure or string.find(o.Text,"Matches may include AI opponents",1,true)~=nil
  assert(not string.find(o.Text,"[BOT]",1,true) and not string.find(o.Text,"BOT /",1,true))
 end
end
assert(generated==2 and avatars==1 and counts and disclosure)
print("Participant presentation: original generated profiles, human-only avatar IDs, total player count and general AI disclosure passed.")

for _,o in ipairs(menu.Gui:GetDescendants())do assert(o.Name~="FriendsCard");if o.ClassName=="TextButton"then assert(o.Text~="Friends")end end
