--!strict

-- Shared settings are visible to both the server and every client.
local Config = {
	GameName = "WorldConquest",
	PremiumEnabled = true, -- Stage 13 menus; paid products require server configuration.
	SimulationMode = "Foundation", -- "Legacy" restores the previous free-growth prototype.
	SimulationSeed = 12345,
	PortStage = 11, -- Staggered spawn selection; conservative live cap over Stage 1–9.
	Population = {PublicTarget=20, SafeParticipants=20, MaximumParticipants=500}, -- Raise only after staging acceptance.
 -- Stage 15 balance is explicit; the pinned upstream rule functions remain unchanged.
 Balance = {StartingSoldiers=5000, DefaultAllocation=.2, RecruitmentMultiplier=.5, BasicRecruitmentMultiplier=.2, ProactiveAI=true, BoundedPaths=true, InfrastructurePresentation=true},
 -- Requested population is available for staging. Zero public grey nations until authorised load acceptance.
 BasicNations = {Enabled=true, Count=350, SafeCount=0, MinSoldiers=500, MaxSoldiers=1500, DecisionsPerTick=4, DecisionTicks=120},
	Bots = {Enabled=true, Count=5, Difficulty="Normal", FillEmptySlots=false, TargetPlayers=10, DecisionsPerTick=2, SampleCells=64, TerrainCachePages=8192, Buildings=true, Naval=true, Missiles=true},
	Match = {Mode="FFA", WinThresholdTenths=800},
	Buildings = {InstantBuild=false},
	Economy = {StartingGold="0", GoldMultiplier=1, DonateGold=false},
	SourceURL = "https://github.com/gbsk001/WorldConquest", -- Upload matching source before release; never the upstream-only repository.
	SpawnSeconds = 20,
	MaxZoom = 64,
	MaxImageTiles = 32,
	ExpansionCooldown = 0.25, -- Optional manual single-cell claim rate.
	GrowthTickSeconds = 0.1,
	ClaimsPerPlayerPerTick = 16,
	ClaimsPerTick = 256,
	FrontierChecksPerTick = 4096,
	FrontierChecksPerPlayer = 128,
	MaxOwnedCells = 1048576, -- Explicit prototype memory ceiling; shown in the UI.
	RenderBudgetSeconds = 0.003,
	RequestCooldown = 0.12,
	NeutralColor = Color3.fromRGB(115, 139, 128),
	PlayerColors = {
		Color3.fromRGB(75, 165, 255),
		Color3.fromRGB(255, 111, 111),
		Color3.fromRGB(255, 205, 86),
		Color3.fromRGB(160, 117, 255),
		Color3.fromRGB(66, 211, 172),
		Color3.fromRGB(255, 146, 65),
		Color3.fromRGB(244, 127, 206),
		Color3.fromRGB(170, 215, 75),
	},
}

return Config
