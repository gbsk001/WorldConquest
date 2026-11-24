local attributes,attributeSignals={},{}
local player={PlayerGui=Instance.new("Frame")}
function player:GetAttribute(key)return attributes[key]end
function player:SetAttribute(key,value)attributes[key]=value;if attributeSignals[key]then attributeSignals[key]:Fire()end end
function player:GetAttributeChangedSignal(key)attributeSignals[key]=attributeSignals[key]or signal();return attributeSignals[key]end
local friendsFail=false
function player:GetFriendsOnlineAsync()if friendsFail then error("presence unavailable")end;return {{VisitorId=2,DisplayName="Friend",IsOnline=true,PlaceId=77},{VisitorId=3,DisplayName="Unavailable",IsOnline=false}}end
local requests={};local lobbyRemote={OnClientEvent=signal()}
function lobbyRemote:FireServer(action,seq,data)table.insert(requests,{Action=action,Sequence=seq,Data=data})end
local prompt=nil
local inviteAllowed=true
local social={CanSendGameInviteAsync=function()return inviteAllowed end,PromptGameInvite=function(_,_,options)prompt=options end}
local originalGet=game.GetService
function game:GetService(name)
 if name=="GuiService"then return {GetGuiInset=function()return Vector2.new(0,36)end}end
 if name=="Players"then return {LocalPlayer=player}end
 if name=="ReplicatedStorage"then return {WaitForChild=function()return lobbyRemote end}end
 if name=="SocialService"then return social end
 return originalGet(self,name)
end
game.PlaceId=77;task.spawn=function(fn)fn()end
local menuConfig={RenderBudgetSeconds=.003}
