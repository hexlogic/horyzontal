"""Reference positions and events of the Sun and the Moon from skyfield and
the JPL DE440 ephemeris, for packages/horyzontal_geo/test/astro_test.dart.
Times in the CSVs are UT1.

Usage: astro.py <out_dir> <de440.bsp>
"""
import csv
import random
import sys
from pathlib import Path

from skyfield import almanac
from skyfield.api import load, load_file, wgs84

OUT = Path(sys.argv[1])
EPH = load_file(sys.argv[2])
TS = load.timescale()
EARTH, SUN, MOON = EPH['earth'], EPH['sun'], EPH['moon']


def places(rnd):
    pts = [(rnd.uniform(44.5, 52.3), rnd.uniform(22.3, 40.1), rnd.uniform(0, 2000)) for _ in range(12)]
    # Far from Ukraine: the tropics, the south, beyond the polar circles.
    pts += [(0.2, -78.5, 2800), (-33.9, 18.4, 0), (69.65, 18.96, 10), (78.22, 15.65, 0), (-54.8, -68.3, 0)]
    return pts


def iso(t):
    # UT1: civil time follows the Earth's rotation (leap seconds keep UTC
    # within a second of it). skyfield's own UTC has no leap seconds before
    # 1972 or after the last announced one, and drifts away from UT1 by
    # minutes over centuries.
    y, mo, d, h, mi, s = t.ut1_calendar()
    return f'{int(y):04d}-{int(mo):02d}-{int(d):02d}T{int(h):02d}:{int(mi):02d}:{s:06.3f}Z'


def positions(rnd):
    rows = []
    pts = places(rnd)
    # Most samples near the present; some across the whole span of DE440.
    years = [rnd.uniform(1900, 2100) for _ in range(300)] + [rnd.uniform(1600, 2600) for _ in range(100)]
    for i, year in enumerate(years):
        lat, lon, h = pts[i % len(pts)]
        y = int(year)
        t = TS.ut1(y, 1, 1 + (year - y) * 365.2425)
        # Whole milliseconds, as a Dart DateTime holds them.
        c = t.ut1_calendar()
        t = TS.ut1(*c[:5], round(c[5], 3))
        obs = EARTH + wgs84.latlon(lat, lon, elevation_m=h)
        row = [iso(t), f'{lat:.6f}', f'{lon:.6f}', f'{h:.1f}']
        for body in (SUN, MOON):
            alt, az, dist = obs.at(t).observe(body).apparent().altaz()
            row += [f'{az.degrees:.6f}', f'{alt.degrees:.6f}', f'{dist.km:.3f}']
        row.append(f'{almanac.fraction_illuminated(EPH, "moon", t):.6f}')
        rows.append(row)
    write('astro_positions.csv',
          ['time', 'lat', 'lon', 'h', 'sun_az', 'sun_alt', 'sun_km', 'moon_az', 'moon_alt', 'moon_km', 'moon_lit'],
          rows)


def events(rnd):
    rows = []
    pts = places(rnd)
    for i in range(60):
        lat, lon, h = pts[i % len(pts)]
        year = rnd.uniform(1950, 2080) if i < 50 else rnd.uniform(1700, 2500)
        y = int(year)
        t0 = TS.ut1(y, 1, 1 + int((year - y) * 365))
        t1 = TS.tt_jd(t0.tt + 2)
        place = wgs84.latlon(lat, lon, elevation_m=h)
        obs = EARTH + place
        found = []
        for body, name in ((SUN, 'sun'), (MOON, 'moon')):
            for f, kind in ((almanac.find_risings, 'rise'), (almanac.find_settings, 'set')):
                ts, real = f(obs, body, t0, t1)
                found += [(t, name, kind) for t, r in zip(ts, real) if r]
            found += [(t, name, 'transit') for t in almanac.find_transits(obs, body, t0, t1)]
        for deg, dawn, dusk in ((-6, 'civilDawn', 'civilDusk'), (-12, 'nauticalDawn', 'nauticalDusk'),
                                (-18, 'astronomicalDawn', 'astronomicalDusk')):
            for f, kind in ((almanac.find_risings, dawn), (almanac.find_settings, dusk)):
                ts, real = f(obs, SUN, t0, t1, horizon_degrees=deg)
                found += [(t, 'sun', kind) for t, r in zip(ts, real) if r]
        for t, name, kind in sorted(found, key=lambda e: e[0].tt):
            rows.append([i, iso(t0), f'{lat:.6f}', f'{lon:.6f}', f'{h:.1f}', name, kind, iso(t)])
    write('astro_events.csv', ['case', 'from', 'lat', 'lon', 'h', 'body', 'kind', 'time'], rows)


def write(name, header, rows):
    with open(OUT / name, 'w', newline='') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(header)
        w.writerows(rows)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    positions(random.Random(20261014))  # own seeds: the other fixtures stay as they are
    events(random.Random(20261015))


if __name__ == '__main__':
    main()
