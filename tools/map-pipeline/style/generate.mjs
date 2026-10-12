// Generates the offline MapLibre style for Horyzontal region packs.
// Placeholders (replaced by the app at runtime):
//   {BASEMAP_URL}  pmtiles://file:///.../<region>.pmtiles
//   {DEM_URL}      pmtiles://file:///.../<region>-dem.pmtiles
//   {ASSETS_URL}   file:///.../map-assets  (contains fonts/ and sprites/)
import { writeFileSync } from "node:fs";
import { layers, namedFlavor } from "@protomaps/basemaps";

const out = process.argv[2] ?? "style-offline.json";
const base = layers("protomaps", namedFlavor("light"), { lang: "uk" });

// Hillshade goes right above landuse polygons and below water/roads/labels.
const hillshade = {
  id: "hillshade",
  type: "hillshade",
  source: "dem",
  paint: {
    "hillshade-exaggeration": 0.35,
    "hillshade-shadow-color": "#5a5a5a",
    "hillshade-highlight-color": "#ffffff",
  },
};
const waterIdx = base.findIndex((l) => l.id === "water");
const all = [...base.slice(0, waterIdx), hillshade, ...base.slice(waterIdx)];

const style = {
  version: 8,
  name: "Horyzontal offline",
  glyphs: "{ASSETS_URL}/fonts/{fontstack}/{range}.pbf",
  sprite: "{ASSETS_URL}/sprites/light",
  sources: {
    protomaps: {
      type: "vector",
      url: "{BASEMAP_URL}",
      attribution: "© OpenStreetMap contributors, Protomaps",
    },
    dem: {
      type: "raster-dem",
      url: "{DEM_URL}",
      encoding: "mapbox",
      tileSize: 256,
      attribution: "Copernicus DEM GLO-30 © ESA/DLR/Airbus",
    },
  },
  layers: all,
};
writeFileSync(out, JSON.stringify(style));
console.log(`wrote ${out}: ${all.length} layers`);
