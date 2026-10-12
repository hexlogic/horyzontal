#!/usr/bin/env python3
"""Reference values for packages/horyzontal_geo tests.

Datum and grid values come from PROJ (cct) with the EPSG parameters spelled
out, MGRS from the NGA GEOTRANS based `mgrs` package, geodesics from Karney's
GeodTest set. See README.md for versions and how to run.
"""
import csv
import gzip
import math
import random
import subprocess
import sys
from pathlib import Path

import mgrs

OUT = Path(sys.argv[1])
GEODTEST = Path(sys.argv[2])  # GeodTest-short.dat.gz

SK42 = '+x=25 +y=-141 +z=-78.5 +rx=0 +ry=-0.35 +rz=-0.736 +s=0 +convention=coordinate_frame'  # EPSG:15865
USK = '+x=24.322 +y=-121.372 +z=-75.847'  # EPSG:7817


def cct(pipeline, rows):
    """Runs `cct` on (a, b) pairs and returns (a, b) results."""
    text = ''.join(f'{a!r} {b!r} 0 0\n' for a, b in rows)
    out = subprocess.run(['cct', '-d', '10', *pipeline.split()], input=text,
                         capture_output=True, text=True, check=True).stdout
    res = []
    for line in out.splitlines():
        f = line.split()
        res.append((float(f[0]), float(f[1])))
    assert len(res) == len(rows), (pipeline, out[:500])
    return res


def from_wgs(helmert):
    """WGS 84 lon/lat degrees -> datum lon/lat degrees on Krassowsky."""
    return ('+proj=pipeline +step +proj=unitconvert +xy_in=deg +xy_out=rad '
            '+step +proj=cart +ellps=WGS84 '
            f'+step +inv +proj=helmert {helmert} '
            '+step +inv +proj=cart +ellps=krass '
            '+step +proj=unitconvert +xy_in=rad +xy_out=deg')


def to_wgs(helmert):
    return ('+proj=pipeline +step +proj=unitconvert +xy_in=deg +xy_out=rad '
            '+step +proj=cart +ellps=krass '
            f'+step +proj=helmert {helmert} '
            '+step +inv +proj=cart +ellps=WGS84 '
            '+step +proj=unitconvert +xy_in=rad +xy_out=deg')


def tmerc(lon0, x0, ellps, k=1.0):
    return f'+proj=tmerc +lon_0={lon0} +x_0={x0} +k={k} +ellps={ellps}'


def ukraine_points(rnd):
    pts = [(rnd.uniform(44.3, 52.4), rnd.uniform(22.1, 40.2)) for _ in range(400)]
    # Zone edges (6° at 24/30/36, 3° at 22.5..37.5) and far corners.
    for lon in (24, 30, 36, 22.5, 25.5, 28.5, 31.5, 34.5, 37.5):
        for d in (-0.3, -1e-4, 1e-4, 0.3):
            pts.append((rnd.uniform(44.5, 52.3), lon + d))
    pts += [(48.1, 22.15), (52.37, 33.4), (44.39, 33.8), (49.2, 40.15),
            (45.2, 29.7), (51.5, 23.6), (50.4501, 30.5234)]
    return pts


def write(name, header, rows):
    with open(OUT / name, 'w', newline='') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(header)
        w.writerows(rows)


def datums(rnd):
    pts = ukraine_points(rnd)
    lonlat = [(lon, lat) for lat, lon in pts]
    sk = cct(from_wgs(SK42), lonlat)
    us = cct(from_wgs(USK), lonlat)
    rows = []
    for (lat, lon), (slon, slat), (ulon, ulat) in zip(pts, sk, us):
        rows.append([f'{lat:.10f}', f'{lon:.10f}', f'{slat:.10f}', f'{slon:.10f}',
                     f'{ulat:.10f}', f'{ulon:.10f}'])
    write('datum_ukraine.csv',
          ['wgs_lat', 'wgs_lon', 'sk42_lat', 'sk42_lon', 'usk_lat', 'usk_lon'], rows)

    # Datum -> WGS 84 direction from points given on the datum.
    dpts = [(lon, lat) for lat, lon in pts[:150]]
    sk_w = cct(to_wgs(SK42), dpts)
    us_w = cct(to_wgs(USK), dpts)
    write('datum_inverse.csv', ['lat', 'lon', 'sk42_wgs_lat', 'sk42_wgs_lon', 'usk_wgs_lat', 'usk_wgs_lon'],
          [[f'{lat:.10f}', f'{lon:.10f}', f'{a[1]:.10f}', f'{a[0]:.10f}', f'{b[1]:.10f}', f'{b[0]:.10f}']
           for (lon, lat), a, b in zip(dpts, sk_w, us_w)])
    return pts, sk, us


def grid(name, datum_pts, width, zone_of, lon0_of, x0_of):
    """Projects datum lon/lat to the zone grid; near a zone edge also to the
    neighbouring zone."""
    rows = []
    for lon, lat in datum_pts:
        z = zone_of(lon)
        near_edge = abs(lon - lon0_of(z)) > width / 2 - 0.5
        for zone in (z - 1, z, z + 1) if near_edge else (z,):
            (e, n), = cct(tmerc(lon0_of(zone), x0_of(zone), 'krass'), [(lon, lat)])
            rows.append([f'{lat:.10f}', f'{lon:.10f}', zone, f'{n:.4f}', f'{e:.4f}'])
    write(name, ['lat', 'lon', 'zone', 'x', 'y'], rows)


def utm_mgrs(rnd):
    m = mgrs.MGRS()
    pts = ukraine_points(rnd)[:200]
    pts += [(rnd.uniform(-79.9, 83.9), rnd.uniform(-180, 180)) for _ in range(400)]
    pts += [(60.5, 4.5), (61, 8), (78, 8.9), (78, 9.1), (78, 20), (78, 33.5),
            (-0.0001, 30.1), (0.0001, 30.1), (-79.99, 10), (83.99, -100),
            (40, -179.9999), (40, 179.9999), (-33.9, 18.4)]
    rows = []
    for lat, lon in pts:
        ref = m.toMGRS(lat, lon, MGRSPrecision=5)
        rows.append([f'{lat:.10f}', f'{lon:.10f}', ref])
    write('mgrs.csv', ['lat', 'lon', 'mgrs5'], rows)

    # UTM via PROJ in the standard zone (Norway/Svalbard via mgrs zone).
    out = []
    for (lat, lon), r in zip(pts, rows):
        zone = int(r[2][:2])
        south = lat < 0
        p = f'+proj=utm +zone={zone} +ellps=WGS84' + (' +south' if south else '')
        (e, n), = cct(p, [(lon, lat)])
        out.append([f'{lat:.10f}', f'{lon:.10f}', zone, f'{e:.4f}', f'{n:.4f}'])
    write('utm.csv', ['lat', 'lon', 'zone', 'easting', 'northing'], out)


def convergence(rnd):
    rows = []
    for lat, lon in ukraine_points(rnd)[:60]:
        z = int(lon // 6) + 1
        lon0 = z * 6 - 3
        out = subprocess.run(['proj', '-V', *tmerc(lon0, 0, 'krass').split()],
                             input=f'{lon!r} {lat!r}\n', capture_output=True, text=True,
                             check=True).stdout
        conv = next(l for l in out.splitlines() if l.startswith('Convergence'))
        k = next(l for l in out.splitlines() if l.startswith('Parallel scale'))
        rows.append([f'{lat:.10f}', f'{lon:.10f}', lon0,
                     conv.split('[')[1].split(']')[0].strip(), k.split(':')[1].split()[0]])
    write('tm_factors.csv', ['lat', 'lon', 'lon0', 'convergence', 'scale'], rows)


def polygons():
    """Polygon perimeter and area and open path length from geographiclib."""
    from geographiclib.geodesic import Geodesic
    g = Geodesic.WGS84
    rnd = random.Random(20261013)  # own seed: the other fixtures stay as they are
    rows = []
    for i in range(40):
        lat0, lon0 = rnd.uniform(44.5, 52.2), rnd.uniform(22.3, 40.0)
        radius = 10 ** rnd.uniform(math.log10(50), math.log10(300_000))
        n = rnd.randint(3, 12)
        angles = sorted(rnd.uniform(0, 360) for _ in range(n))
        pts = []
        for a in angles:
            d = g.Direct(lat0, lon0, a, radius * rnd.uniform(0.4, 1.0))
            # Rounded as written, so the reference matches the CSV exactly.
            pts.append((float(f"{d['lat2']:.10f}"), float(f"{d['lon2']:.10f}")))
        if i % 2:
            pts.reverse()
        poly, line = g.Polygon(False), g.Polygon(True)
        for lat, lon in pts:
            poly.AddPoint(lat, lon)
            line.AddPoint(lat, lon)
        _, perimeter, area = poly.Compute(False, True)
        _, length, _ = line.Compute(False, True)
        rows.append(['|'.join(f'{lat:.10f}:{lon:.10f}' for lat, lon in pts),
                     f'{perimeter:.6f}', f'{area:.4f}', f'{length:.6f}'])
    write('polygons.csv', ['vertices', 'perimeter', 'area', 'line_length'], rows)


def geodtest():
    with gzip.open(GEODTEST, 'rt') as f:
        lines = f.readlines()
    # Every 20th line keeps all the problem classes of the set (it is ordered).
    with open(OUT / 'geodtest_subset.dat', 'w') as f:
        f.writelines(lines[::20])


def main():
    rnd = random.Random(20261012)
    OUT.mkdir(parents=True, exist_ok=True)
    pts, sk, us = datums(rnd)
    grid('gk_sk42.csv', sk, 6, lambda l: int(l // 6) + 1, lambda z: z * 6 - 3, lambda z: z * 1_000_000 + 500_000)
    grid('gk_usk2000.csv', us, 6, lambda l: int(l // 6) + 1, lambda z: z * 6 - 3, lambda z: z * 1_000_000 + 500_000)
    grid('tm3_usk2000.csv', us, 3, lambda l: int((l + 1.5) // 3), lambda z: z * 3, lambda z: 300_000)
    utm_mgrs(rnd)
    convergence(rnd)
    geodtest()
    polygons()


if __name__ == '__main__':
    main()
