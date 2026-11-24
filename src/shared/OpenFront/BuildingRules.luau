--!strict
-- Config.unitInfo / EngineConfig.unitCost, pinned OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
local Rules = {}
Rules.Types={"City","DefensePost","Factory","Port","MissileSilo","SAMLauncher"}
Rules.Info={
 MissileSilo={Name="Missile Silo",Glyph="M",Duration=100,Upgradeable=true,Effect="One launch slot per level; reload in 9 seconds"},
 SAMLauncher={Name="SAM Launcher",Glyph="S",Duration=300,Upgradeable=true,Effect="Automatic interception; range and slots grow with level"},
 City={Name="City",Glyph="C",Duration=20,Upgradeable=true,Effect="+250K soldier capacity per completed level"},
 DefensePost={Name="Defense Post",Glyph="D",Duration=50,Upgradeable=false,Effect="30-cell range: defense magnitude x5; capture cost x3"},
 Factory={Name="Factory",Glyph="F",Duration=20,Upgradeable=true,Effect="Trains trade with connected cities/ports; 110-cell range"},
 Port={Name="Port",Glyph="P",Duration=50,Upgradeable=true,Effect="Sea trade, warship launch and repairs; coastal rail stop"},
}
Rules.MinDistance=15
Rules.SearchRadius=15
Rules.DefenseRange=30
Rules.DeleteCooldown=300
Rules.DeleteDelay=300
function Rules.cost(kind,owned,constructed,extra)
 local n=0
 for _,t in ipairs(if kind=="Port" or kind=="Factory" then {"Port","Factory"} else {kind}) do
  n+=math.min(owned[t] or 0,constructed[t] or 0)
 end
 n+=extra or 0
 if kind=="City" or kind=="Port" or kind=="Factory" then return tostring(if n>=3 then 1000000 else 125000*2^n) end
 if kind=="DefensePost" then return tostring(math.min(250000,(n+1)*50000)) end
 if kind=="MissileSilo" then return "1000000" end
 if kind=="SAMLauncher" then return tostring(math.min(3000000,(n+1)*1500000)) end
 error("Building type is not enabled in Stage 5")
end
return Rules
