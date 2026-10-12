#!/usr/bin/env python3
"""Writes packs.json for the `maps` release: every region's basemap and
heights with size and SHA-256. The app downloads this first and verifies
each file against it.

Usage: manifest.py <out dir> <protomaps build, e.g. 20261012>
"""
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

out = Path(sys.argv[1])
build = sys.argv[2]
regions = json.loads((Path(__file__).parent / 'regions' / 'index.json').read_text())


def describe(kind, path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return {'kind': kind, 'name': path.name, 'bytes': path.stat().st_size, 'sha256': h.hexdigest()}


manifest = {
    'version': 1,
    'build': build,
    'generated': datetime.now(timezone.utc).isoformat(timespec='seconds'),
    'regions': [],
}
for r in regions:
    files = []
    for kind, name in (('basemap', f"{r['id']}.pmtiles"), ('dem', f"{r['id']}-dem.pmtiles")):
        p = out / name
        if p.exists():
            files.append(describe(kind, p))
    if files:
        manifest['regions'].append({'id': r['id'], 'files': files})

(out / 'packs.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=1))
print(f"packs.json: {len(manifest['regions'])} regions", file=sys.stderr)
