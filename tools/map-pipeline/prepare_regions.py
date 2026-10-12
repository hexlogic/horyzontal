#!/usr/bin/env python3
"""Builds the 25 region polygons used to cut offline packs.

Source: geoBoundaries gbOpen UKR ADM1 (OpenStreetMap, ODbL 1.0), pinned commit.
Kyiv city is merged into Kyiv oblast, Sevastopol into Crimea. Each polygon is
buffered by BUFFER_M so neighbouring packs overlap and nothing is cut at the
border, then simplified.

Output: regions/<id>.geojson and regions/index.json.
Requires GDAL Python bindings (brew install gdal).
"""
import json
import sys
import urllib.request
from pathlib import Path

from osgeo import ogr, osr

ogr.UseExceptions()
osr.UseExceptions()

SOURCE_URL = (
    "https://github.com/wmgeolab/geoBoundaries/raw/9469f09/"
    "releaseData/gbOpen/UKR/ADM1/geoBoundaries-UKR-ADM1.geojson"
)
BUFFER_M = 2000
SIMPLIFY_M = 100

# id, Ukrainian name, ISO 3166-2 codes merged into the region
REGIONS = [
    ("vinnytsia", "Вінницька", ["UA-05"]),
    ("volyn", "Волинська", ["UA-07"]),
    ("dnipropetrovsk", "Дніпропетровська", ["UA-12"]),
    ("donetsk", "Донецька", ["UA-14"]),
    ("zhytomyr", "Житомирська", ["UA-18"]),
    ("zakarpattia", "Закарпатська", ["UA-21"]),
    ("zaporizhzhia", "Запорізька", ["UA-23"]),
    ("ivano-frankivsk", "Івано-Франківська", ["UA-26"]),
    ("kyiv", "Київська та Київ", ["UA-32", "UA-30"]),
    ("kirovohrad", "Кіровоградська", ["UA-35"]),
    ("luhansk", "Луганська", ["UA-09"]),
    ("lviv", "Львівська", ["UA-46"]),
    ("mykolaiv", "Миколаївська", ["UA-48"]),
    ("odesa", "Одеська", ["UA-51"]),
    ("poltava", "Полтавська", ["UA-53"]),
    ("rivne", "Рівненська", ["UA-56"]),
    ("sumy", "Сумська", ["UA-59"]),
    ("ternopil", "Тернопільська", ["UA-61"]),
    ("kharkiv", "Харківська", ["UA-63"]),
    ("kherson", "Херсонська", ["UA-65"]),
    ("khmelnytskyi", "Хмельницька", ["UA-68"]),
    ("cherkasy", "Черкаська", ["UA-71"]),
    ("chernivtsi", "Чернівецька", ["UA-77"]),
    ("chernihiv", "Чернігівська", ["UA-74"]),
    ("crimea", "АР Крим та Севастополь", ["UA-43", "UA-40"]),
]


def srs(epsg):
    s = osr.SpatialReference()
    s.ImportFromEPSG(epsg)
    s.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
    return s


def main():
    out_dir = Path(__file__).parent / "regions"
    out_dir.mkdir(exist_ok=True)
    with urllib.request.urlopen(SOURCE_URL) as r:
        src = json.load(r)
    by_iso = {f["properties"]["shapeISO"]: f["geometry"] for f in src["features"]}

    wgs84, utm = srs(4326), srs(32636)  # UTM 36N is good enough for buffering
    to_utm = osr.CoordinateTransformation(wgs84, utm)
    to_wgs = osr.CoordinateTransformation(utm, wgs84)

    index = []
    for rid, name, isos in REGIONS:
        geom = None
        for iso in isos:
            g = ogr.CreateGeometryFromJson(json.dumps(by_iso[iso]))
            geom = g if geom is None else geom.Union(g)
        geom.Transform(to_utm)
        area_km2 = geom.GetArea() / 1e6
        geom = geom.Buffer(BUFFER_M).SimplifyPreserveTopology(SIMPLIFY_M)
        geom.Transform(to_wgs)
        minx, maxx, miny, maxy = geom.GetEnvelope()
        feature = {
            "type": "Feature",
            "properties": {"id": rid, "name": name, "iso": isos},
            "geometry": json.loads(geom.ExportToJson(options=["COORDINATE_PRECISION=5"])),
        }
        (out_dir / f"{rid}.geojson").write_text(
            json.dumps({"type": "FeatureCollection", "features": [feature]})
        )
        index.append({
            "id": rid,
            "name": name,
            "area_km2": round(area_km2),
            "bbox": [round(v, 4) for v in (minx, miny, maxx, maxy)],
        })
        print(f"{rid:16} {area_km2:8.0f} km2", file=sys.stderr)
    (out_dir / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
