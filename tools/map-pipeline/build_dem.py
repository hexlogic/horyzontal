#!/usr/bin/env python3
"""Cuts Copernicus DEM GLO-30 for one region into a terrain-RGB PMTiles pack.

    python3 build_dem.py kyiv --maxzoom 12 --format webp --step 1.0

Pipeline per zoom level: mosaic of 1x1 degree COGs (cached in out/cache/cop30)
-> gdalwarp to the Web Mercator tile grid -> Mapbox terrain-RGB encoding
-> lossless WebP/PNG -> MBTiles -> `pmtiles convert`.

--step quantizes heights before encoding (0.1 is the encoding's native
resolution). Copernicus is a surface model (DSM) with ~2-4 m vertical
accuracy, so 1 m steps lose nothing meaningful and compress much better.

Requires GDAL Python bindings + numpy (brew install gdal) and the pmtiles CLI.
"""
import argparse
import json
import math
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np
from osgeo import gdal, ogr

gdal.UseExceptions()
ogr.UseExceptions()

HERE = Path(__file__).parent
COP_URL = "https://copernicus-dem-30m.s3.amazonaws.com/{n}/{n}.tif"
TILE = 256
WORLD = 2 * math.pi * 6378137
ORIGIN = WORLD / 2


def cop_name(lat, lon):
    ns = f"N{lat:02d}" if lat >= 0 else f"S{-lat:02d}"
    ew = f"E{lon:03d}" if lon >= 0 else f"W{-lon:03d}"
    return f"Copernicus_DSM_COG_10_{ns}_00_{ew}_00_DEM"


def fetch_cop_tiles(bbox, cache):
    """Downloads every 1x1 degree tile touching bbox; ocean tiles don't exist."""
    cache.mkdir(parents=True, exist_ok=True)
    minx, miny, maxx, maxy = bbox
    paths = []
    for lat in range(math.floor(miny), math.ceil(maxy)):
        for lon in range(math.floor(minx), math.ceil(maxx)):
            name = cop_name(lat, lon)
            path = cache / f"{name}.tif"
            if not path.exists():
                try:
                    print(f"  downloading {name}", file=sys.stderr)
                    tmp = path.with_suffix(".part")
                    urllib.request.urlretrieve(COP_URL.format(n=name), tmp)
                    tmp.rename(path)
                except urllib.error.HTTPError as e:
                    if e.code in (403, 404):
                        continue  # sea, no tile
                    raise
            paths.append(str(path))
    return paths


def lonlat_to_tile(lon, lat, z):
    n = 2**z
    x = (lon + 180) / 360 * n
    y = (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * n
    return x, y


def tile_bounds_merc(x, y, z):
    size = WORLD / 2**z
    return (-ORIGIN + x * size, ORIGIN - (y + 1) * size, -ORIGIN + (x + 1) * size, ORIGIN - y * size)


def tile_bounds_lonlat(x, y, z):
    n = 2**z
    lon0, lon1 = x / n * 360 - 180, (x + 1) / n * 360 - 180
    lat0 = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * (y + 1) / n))))
    lat1 = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * y / n))))
    return lon0, lat0, lon1, lat1


def bbox_geom(minx, miny, maxx, maxy):
    ring = ogr.Geometry(ogr.wkbLinearRing)
    for px, py in ((minx, miny), (maxx, miny), (maxx, maxy), (minx, maxy), (minx, miny)):
        ring.AddPoint_2D(px, py)
    poly = ogr.Geometry(ogr.wkbPolygon)
    poly.AddGeometry(ring)
    return poly


def encode_terrain_rgb(h, step):
    h = np.nan_to_num(h, nan=0.0)
    if step > 0.1:
        h = np.round(h / step) * step
    v = np.clip(np.round((h + 10000.0) * 10.0), 0, 2**24 - 1).astype(np.uint32)
    rgb = np.empty((3,) + h.shape, dtype=np.uint8)
    rgb[0] = (v >> 16) & 0xFF
    rgb[1] = (v >> 8) & 0xFF
    rgb[2] = v & 0xFF
    return rgb


def image_bytes(rgb, fmt):
    mem = gdal.GetDriverByName("MEM").Create("", TILE, TILE, 3, gdal.GDT_Byte)
    for i in range(3):
        mem.GetRasterBand(i + 1).WriteArray(rgb[i])
    path = f"/vsimem/tile.{fmt}"
    if fmt == "webp":
        gdal.GetDriverByName("WEBP").CreateCopy(path, mem, options=["LOSSLESS=TRUE"])
    else:
        gdal.GetDriverByName("PNG").CreateCopy(path, mem, options=["ZLEVEL=9"])
    f = gdal.VSIFOpenL(path, "rb")
    gdal.VSIFSeekL(f, 0, 2)
    size = gdal.VSIFTellL(f)
    gdal.VSIFSeekL(f, 0, 0)
    data = gdal.VSIFReadL(1, size, f)
    gdal.VSIFCloseL(f)
    gdal.Unlink(path)
    return data


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("region")
    ap.add_argument("--minzoom", type=int, default=6)
    ap.add_argument("--maxzoom", type=int, default=12)
    ap.add_argument("--format", choices=["webp", "png"], default="webp")
    ap.add_argument("--step", type=float, default=1.0, help="height quantization, m")
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    region = json.loads((HERE / "regions" / f"{args.region}.geojson").read_text())
    area = ogr.CreateGeometryFromJson(json.dumps(region["features"][0]["geometry"]))
    minx, maxx, miny, maxy = area.GetEnvelope()

    out_dir = HERE / "out"
    out_dir.mkdir(exist_ok=True)
    tag = f"z{args.maxzoom}-{args.format}-{args.step:g}m"
    out = args.out or out_dir / f"{args.region}-dem-{tag}.pmtiles"
    mbtiles = out.with_suffix(".mbtiles")
    mbtiles.unlink(missing_ok=True)

    t0 = time.time()
    srcs = fetch_cop_tiles((minx, miny, maxx, maxy), out_dir / "cache" / "cop30")
    vrt = str(out_dir / "cache" / f"{args.region}.vrt")
    gdal.BuildVRT(vrt, srcs)

    db = sqlite3.connect(mbtiles)
    db.executescript(
        "CREATE TABLE metadata (name TEXT, value TEXT);"
        "CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);"
    )
    meta = {
        "name": f"horyzontal-dem-{args.region}",
        "format": args.format,
        "type": "baselayer",
        "encoding": "mapbox",
        "minzoom": str(args.minzoom),
        "maxzoom": str(args.maxzoom),
        "bounds": f"{minx:.5f},{miny:.5f},{maxx:.5f},{maxy:.5f}",
        "attribution": "Copernicus DEM GLO-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018, provided under COPERNICUS by the European Union and ESA",
        "description": f"Terrain-RGB (Mapbox encoding), {args.step:g} m height step, surface model incl. vegetation and buildings",
    }
    db.executemany("INSERT INTO metadata VALUES (?, ?)", meta.items())

    total_tiles, total_bytes = 0, 0
    for z in range(args.maxzoom, args.minzoom - 1, -1):
        fx0, fy0 = lonlat_to_tile(minx, maxy, z)
        fx1, fy1 = lonlat_to_tile(maxx, miny, z)
        x0, y0, x1, y1 = int(fx0), int(fy0), int(fx1), int(fy1)
        nx, ny = x1 - x0 + 1, y1 - y0 + 1
        left, _, _, top = tile_bounds_merc(x0, y0, z)
        _, bottom, right, _ = tile_bounds_merc(x1, y1, z)
        warped = gdal.Warp(
            "", vrt, format="MEM", dstSRS="EPSG:3857",
            outputBounds=(left, bottom, right, top),
            width=nx * TILE, height=ny * TILE,
            resampleAlg="bilinear" if z == args.maxzoom else "average",
            srcNodata=-32767, dstNodata=float("nan"), outputType=gdal.GDT_Float32,
            multithread=True,
        )
        arr = warped.GetRasterBand(1).ReadAsArray()
        warped = None
        n, nbytes = 0, 0
        for ty in range(y0, y1 + 1):
            for tx in range(x0, x1 + 1):
                if not area.Intersects(bbox_geom(*tile_bounds_lonlat(tx, ty, z))):
                    continue
                px, py = (tx - x0) * TILE, (ty - y0) * TILE
                block = arr[py:py + TILE, px:px + TILE]
                data = image_bytes(encode_terrain_rgb(block, args.step), args.format)
                db.execute(
                    "INSERT INTO tiles VALUES (?, ?, ?, ?)",
                    (z, tx, (2**z - 1) - ty, data),
                )
                n += 1
                nbytes += len(data)
        db.commit()
        total_tiles += n
        total_bytes += nbytes
        print(f"  z{z}: {n} tiles, {nbytes / 1e6:.1f} MB", file=sys.stderr)
    db.execute("CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row)")
    db.commit()
    db.close()

    out.unlink(missing_ok=True)
    subprocess.run(["pmtiles", "convert", str(mbtiles), str(out)], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    mbtiles.unlink()
    size = out.stat().st_size
    print(f"{out.name}: {total_tiles} tiles, {size / 1e6:.1f} MB, {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
