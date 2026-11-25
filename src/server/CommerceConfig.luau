--!strict
-- Owner-supplied pass IDs. Keep prompts off until live acceptance; never invent IDs.
return {
 DataStoreName="WorldConquestProfilesV1",
 EnablePaidPurchasePrompts=false, -- Does not prevent restoring verified existing ownership.
 PurchaseTestUserIDs={}, -- Optional owner-configured live testers only; empty means nobody can bypass the prompt switch.
 StarterPassID=2098697285, -- intended Dashboard price 49 Robux; client reads the actual price
 GeneralPassID=2099891345, -- intended Dashboard price 399 Robux; permanent, NOT a subscription
 -- Amounts are server-authoritative. Intended prices are comments only: Managed Pricing is read on the client.
 StarsProducts={
  {ID=3735920468,Stars=100}, -- intended base price 19 Robux
  {ID=3735920863,Stars=500}, -- intended base price 79 Robux
  {ID=3735920948,Stars=1000}, -- intended base price 149 Robux
  {ID=3735921042,Stars=5000}, -- intended base price 599 Robux
 },
 BadgeIDs={FirstConquest=0,FirstVictory=0,EmpireBuilder=0,WorldDominator=0,Veteran=0,Unstoppable=0,NavalCommander=0},
}
