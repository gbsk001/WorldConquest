--!strict
-- Create products in THIS experience. Zero means disabled. Never invent IDs.
return {
 DataStoreName="WorldConquestProfilesV1",
 StarterPassID=0, -- one-time permanent pass, suggested price 49 Robux in Dashboard
 GeneralPassID=0, -- permanent cosmetic membership, NOT a recurring subscription
 StarsProductID=0, StarsPerPurchase=500, EnableStarsProduct=false,
 BadgeIDs={FirstConquest=0,FirstVictory=0,EmpireBuilder=0,WorldDominator=0,Veteran=0,Unstoppable=0,NavalCommander=0},
}
