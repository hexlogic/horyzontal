#!/usr/bin/env bash
# Builds the offline pack for one region: basemap + heights.
#
#   ./build_region.sh kyiv            # latest Protomaps daily build
#   BUILD=20261012 ./build_region.sh kyiv
#
# Output: out/<region>.pmtiles (vector, OpenStreetMap via Protomaps)
#         out/<region>-dem.pmtiles (terrain-RGB, Copernicus GLO-30)
set -euo pipefail
cd "$(dirname "$0")"

region="$1"
maxzoom="${MAXZOOM:-15}"
# PYTHON must have the GDAL bindings (Homebrew: PYTHON=python3.14)
[[ -f "regions/$region.geojson" ]] || { echo "unknown region: $region" >&2; exit 1; }

if [[ -z "${BUILD:-}" ]]; then
  BUILD=$(curl -fsSL https://build-metadata.protomaps.dev/builds.json \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)[-1]["key"].removesuffix(".pmtiles"))')
fi
mkdir -p out

echo "== $region: basemap from Protomaps build $BUILD, z0-$maxzoom" >&2
pmtiles extract "https://build.protomaps.com/$BUILD.pmtiles" "out/$region.pmtiles" \
  --region="regions/$region.geojson" --maxzoom="$maxzoom" --download-threads=8 -q

echo "== $region: heights" >&2
"${PYTHON:-python3}" build_dem.py "$region" --maxzoom 12 --format webp --step 1 --out "out/$region-dem.pmtiles"

ls -l "out/$region.pmtiles" "out/$region-dem.pmtiles" >&2
