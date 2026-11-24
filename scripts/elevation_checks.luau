assert(EarthTerrain.ElevationKnown,"NOAA elevation not enabled")
for _,sample in ipairs(ElevationOracle.samples) do
 local value=EarthTerrain.byte(sample.cell)
 assert((bit32.band(value,128)~=0)==sample.land,sample.name.." land mask")
 if sample.land then assert(bit32.band(value,31)==sample.magnitude,sample.name.." geographic terrain class") end
end
assert(EarthTerrain.cacheBytes()<=524288)
print("Live EarthTerrain NOAA samples, terrain classes, coast preservation and bounded decoded cache passed.")
