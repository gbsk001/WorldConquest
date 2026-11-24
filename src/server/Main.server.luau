--!strict
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
if Config.SimulationMode == "Foundation" then
 local session=if Config.PortStage>=10 then require(script.Parent.LobbyServer).new(if Config.PortStage>=11 then Config.Population else nil) else nil
 if session then
  local progression=require(script.Parent.ProgressionServer).new(session)
  require(script.Parent.IdentityServer).new(session,progression.Store)
  require(script.Parent.PartyServer).new(session)
  require(script.Parent.CommunicationServer).new(session)
 end
 require(script.Parent.OpenFront.FoundationServer)(session)
else
 require(script.Parent.LegacyServer)()
end
