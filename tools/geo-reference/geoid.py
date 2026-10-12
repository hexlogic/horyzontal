#!/usr/bin/env python3
"""EGM2008 geoid heights for Ukraine and around, 5' grid, for the app's
altitude above sea level. Samples PROJ's us_nga_egm08_25.tif (NGA, 2.5')
at the grid nodes, and writes random check points for the tests.

Usage: geoid.py <dart output> <fixture csv>
"""
import base64
import random
import struct
import subprocess
import sys

LON0, LAT0, STEP = 21.5, 43.5, 1 / 12
NLON, NLAT = 235, 121  # 21.5..41.0, 43.5..53.5
PIPE = '+proj=vgridshift +grids=us_nga_egm08_25.tif +multiplier=1'.split()


def undulation(points):
    text = ''.join(f'{lon!r} {lat!r} 0 0\n' for lon, lat in points)
    out = subprocess.run(['cct', '-d', '4', *PIPE], input=text, capture_output=True,
                         text=True, check=True).stdout
    return [float(l.split()[2]) for l in out.splitlines() if l.strip()]


def main():
    dart_out, fixture = sys.argv[1], sys.argv[2]
    nodes = [(LON0 + i * STEP, LAT0 + j * STEP) for j in range(NLAT) for i in range(NLON)]
    n = undulation(nodes)
    assert len(n) == NLON * NLAT
    data = struct.pack(f'<{len(n)}h', *[round(v * 100) for v in n])  # centimetres
    b64 = base64.b64encode(data).decode()
    with open(dart_out, 'w') as f:
        f.write('// EGM2008 geoid undulation, NGA (public domain), sampled by\n')
        f.write('// tools/geo-reference/geoid.py. Little-endian int16 centimetres,\n')
        f.write(f'// rows from {LAT0}°N northwards, {NLON} nodes from {LON0}°E, step 5\'.\n')
        f.write('// dart format off\n\n')
        f.write(f'const egm2008Lon0 = {LON0};\nconst egm2008Lat0 = {LAT0};\n')
        f.write(f'const egm2008Columns = {NLON};\nconst egm2008Rows = {NLAT};\n\n')
        f.write('const egm2008Data =\n')
        for i in range(0, len(b64), 76):
            f.write(f"    '{b64[i:i + 76]}'\n")
        f.write(';\n')

    rnd = random.Random(20261012)
    pts = [(rnd.uniform(22, 40.5), rnd.uniform(44, 53)) for _ in range(300)]
    pts += [(24.2, 48.2), (24.5, 48.1), (34.1, 44.7)]  # Carpathians, Crimean mountains
    with open(fixture, 'w') as f:
        f.write('lat,lon,n\n')
        for (lon, lat), v in zip(pts, undulation(pts)):
            f.write(f'{lat:.8f},{lon:.8f},{v:.4f}\n')


if __name__ == '__main__':
    main()
