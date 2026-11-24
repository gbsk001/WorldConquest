--!strict
-- Original WorldConquest cosmetics. AGPL-3.0. No competitive statistics.
local Catalog={}
Catalog.Daily={25,35,50,65,80,100,150}
Catalog.Rewards={Completion=40,Victory=60,Achievement=50,MinimumSeconds=180,ActiveWindows=6,MinimumTerritory=1000}
Catalog.Categories={"Flag","Missile","Warship","Transport","Building","Attack","Explosion","Color","Pattern","Border","NameTag","Crown","Badge","Victory"}
Catalog.Items={
 {ID="flag_horizon",Name="Horizon Republic",Category="Flag",Price=0,Colors={"285B80","E6BD68","F2EBDD"},Design="Bands",Description="An original tricolour for a new nation."},
 {ID="flag_aurora",Name="Aurora Union",Category="Flag",Price=120,Colors={"153D4B","56C9A7","E9F5EF"},Design="Cross",Description="An original northern cross."},
 {ID="flag_japan",Name="Japan",Category="Flag",Price=80,Colors={"FFFFFF","BC002D","FFFFFF"},Design="Disc",Description="The national flag of Japan."},
 {ID="flag_france",Name="France",Category="Flag",Price=80,Colors={"002654","FFFFFF","ED2939"},Design="Vertical",Description="The national tricolour of France."},
 {ID="flag_victor",Name="Laurel Republic",Category="Flag",Unlock="FirstVictory",Colors={"183C32","E7C873","F5F0DA"},Design="Bands",Description="Awarded for your first eligible public victory."},
 {ID="flag_founder",Name="Golden Horizon",Category="Flag",Offer="Starter",Colors={"10253D","EDC667","FCF1D0"},Design="Cross",Description="An original Starter Pack flag."},
 {ID="flag_general",Name="General's Standard",Category="Flag",Offer="General",Colors={"283451","D5B35E","ECE8DB"},Design="Vertical",Description="Included with WorldConquest General."},
 {ID="missile_pearl",Name="Pearl Vanguard",Category="Missile",Price=140,Tint="D8EEFF",Icon="Missiles",Description="An ice-white missile finish. Identical combat statistics."},
 {ID="missile_founder",Name="Gilded Vanguard",Category="Missile",Offer="Starter",Tint="F2CB76",Icon="Missiles",Description="A gold missile finish. Identical combat statistics."},
 {ID="ship_cobalt",Name="Cobalt Fleet",Category="Warship",Price=140,Tint="7CBCEC",Icon="Navy",Description="A cobalt warship finish. Identical naval statistics."},
 {ID="transport_emerald",Name="Emerald Convoy",Category="Transport",Price=100,Tint="86D5B3",Icon="Navy",Description="An emerald transport finish. Identical capacity and speed."},
 {ID="building_ivory",Name="Ivory Architecture",Category="Building",Price=150,Tint="EADABD",Icon="Buildings",Description="An ivory building finish. Ownership accents remain visible."},
 {ID="color_ocean",Name="Ocean",Category="Color",Price=90,Tint="598EBA",Icon="Territory",Description="A readable ocean-blue territory colour."},
 {ID="color_jade",Name="Jade",Category="Color",Price=90,Tint="61AC8C",Icon="Territory",Description="A readable jade-green territory colour."},
 {ID="tag_gold",Name="Gold Lettering",Category="NameTag",Price=120,Tint="F3D892",Icon="Rank",Description="Soft gold lettering with the existing dark text outline."},
 {ID="crown_pearl",Name="Pearl Crown",Category="Crown",Price=200,Tint="D8EFFF",Icon="Crown",Description="A pearl finish when you earn a live territory crown."},
 {ID="badge_founder",Name="Pathfinder",Category="Badge",Offer="Starter",Tint="F2CB76",Icon="Rank",Description="The permanent Starter Pack profile badge."},
 {ID="badge_general",Name="General",Category="Badge",Offer="General",Tint="D5B35E",Icon="Rank",Description="The WorldConquest General profile badge."},
 {ID="badge_week",Name="Seven Horizons",Category="Badge",Unlock="Daily7",Tint="86D5B3",Icon="Rank",Description="Complete a seven-day reward calendar."},
 {ID="victory_gold",Name="Golden Victory",Category="Victory",Price=180,Tint="F2CB76",Icon="Leaderboard",Description="A restrained gold victory banner pulse on your results screen."},
 {ID="attack_signal",Name="Azure Signal",Category="Attack",Price=100,Tint="83BDEB",Icon="Army",Description="A brief azure pulse at your nation when a new attack starts."},
 {ID="impact_amber",Name="Amber Shockwave",Category="Explosion",Price=180,Tint="EDC47C",Icon="Missiles",Description="An amber ring at a confirmed missile impact. Identical damage and fallout."},
 {ID="pattern_weave",Name="Cartographer's Weave",Category="Pattern",Price=120,Tint="B4CFCD",Icon="Territory",Description="Subtle diagonal shading, visible at close zoom. Ownership colours remain clear."},
 {ID="border_ink",Name="Ink Border",Category="Border",Price=100,Tint="718696",Icon="Territory",Description="A darker fine territory border at maximum zoom."},
}
Catalog.ByID={};for _,item in ipairs(Catalog.Items)do Catalog.ByID[item.ID]=item end
Catalog.Achievements={
 {ID="FirstConquest",Name="First Conquest",Metric="Territory",Target=10000},
 {ID="FirstVictory",Name="First Victory",Metric="Wins",Target=1,Item="flag_victor"},
 {ID="EmpireBuilder",Name="Empire Builder",Metric="Territory",Target=100000},
 {ID="WorldDominator",Name="World Dominator",Metric="Territory",Target=1000000},
 {ID="Veteran",Name="Veteran",Metric="Matches",Target=25},
 {ID="NavalCommander",Name="Naval Commander",Metric="Ships",Target=1},
 {ID="Unstoppable",Name="Unstoppable",Metric="BestStreak",Target=3},
}
Catalog.Metrics={"Wins","Matches","Territory","HumanEliminations","BestStreak","Soldiers"}
function Catalog.featured(now)
 local flags={"flag_aurora","flag_japan","flag_france"};local day=math.floor(now/86400)
 return flags[day%#flags+1],(day+1)*86400
end
return Catalog
