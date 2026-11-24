# Real Earth geography and licensing

The active map is generated from **Natural Earth 1:10 million, version 5.1.2**, land polygons with lake polygons subtracted. The dataset names use `10m` to mean **1:10 million cartographic scale**, not ten-metre spatial resolution.

- [Original land GeoJSON](https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_land.geojson)
- [Original lakes GeoJSON](https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_lakes.geojson)
- [Natural Earth project](https://www.naturalearthdata.com/)
- [Public-domain terms](https://www.naturalearthdata.com/about/terms-of-use/)

Both original files are vendored here, downloaded 2026-11-17. Exact source SHA-256 hashes and the generated mask hash are recorded in [earth-manifest.json](earth-manifest.json). The old `ne_110m_land.geojson` is retained as historical input only; it is **not used** by the current generator or game.

## Generation

Run `python scripts/generate_earth.py`. It scans the original detailed polygons at cell centres, respects polygon holes, and subtracts the detailed lake layer. It does not scale up the old map.

The simulation mask is **8192 x 4096**, with 11,014,740 land cells. Each cell spans 0.0439453125 degrees of longitude/latitude, about 4.9 km north/south. The former map was 720 x 360. The new mask therefore has roughly 129 times as many simulation cells and uses a more detailed geographical source.

Projection remains equirectangular: longitude -180 to +180 and latitude +90 to -90, with a fixed 2:1 world rectangle. Zoom and pan preserve that rectangle's aspect ratio. Positions follow the source longitude/latitude; equirectangular projection necessarily stretches polar areas and is not equal-area.

This is still a finite-resolution strategy map, not survey/navigation data. Features narrower than a cell can disappear, some narrow channels can close, and high magnification eventually reveals cells. Natural Earth simplifies source coastlines and its lake data is a historical snapshot. No political boundary interpretation is used.

## Runtime rendering

The generated `EarthData.luau` contains losslessly packed simulation land runs and pre-averaged display levels. Only the full-resolution mask validates claims. Display levels preserve land coverage for zoomed-out rendering; they never determine whether a cell is claimable.

The client renders visible image tiles from this data. Zooming selects new higher-detail samples, rather than stretching the overview indefinitely. Neighbouring tiles have matching one-pixel gutters. All rendering stays in ScreenGui; no Roblox terrain, 3D map, uploaded image asset, or runtime web request is used.

**No manual map-asset import is required.** The runtime renderer uses EditableImage. For published experiences, enable **Experience Settings > Security > Allow Mesh / Image APIs**, or **Creator Dashboard > Configure > Settings > Enable Mesh / Image APIs**. See [Roblox's EditableImage documentation](https://create.roblox.com/docs/reference/engine/classes/EditableImage). If allocation fails because access is disabled or memory is insufficient, the game displays a setup message instead of starting a match over an invisible map.


## Elevation added 2026-11-18

The runtime terrain now includes NOAA NCEI ETOPO 2022 v1 60 arc-second ice-surface
heights, released under CC0-1.0. See [elevation-manifest.json](elevation-manifest.json)
for source URL, DOI, licence source, pinned hash, sample locations and class counts.
The original Natural Earth mask is unchanged, including low land and all mapped lakes.

This is a documented data adaptation: upstream classifies authored PNG colours;
our measured DEM heights use <1000 m plains, 1000..<2000 m highland, >=2000 m mountain.
Those metre thresholds are not claimed upstream constants. Existing source combat
and priority formulas consume the resulting classes unchanged. The map is still
8192×4096, with finite cell resolution and equirectangular polar distortion.

Run generate_elevation.py **after** generate_topology.py to bake the classes into
compressed terrain. Full regeneration details, verified licence links and remaining
acceptance limits are in [the Stage 3 report](../docs/STAGE3_CONNECTIVITY_ACCEPTANCE.md).
The original 466 MB GeoTIFF and decoder packages stay under build; they are not Rojo
runtime assets. The class RLE is a provenance artifact, not a second runtime layer.
No manual asset import or runtime network data access is required.
