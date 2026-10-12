#!/usr/bin/env python3
"""Generates the APP-6D / MIL-STD-2525D symbol catalogue for horyzontal_symbols.

Usage:
  python3 -I tools/symbol-catalog/generate.py JMSML_DIR OUT_DIR [--uk UK_JSON]
  python3 -I tools/symbol-catalog/generate.py JMSML_DIR --missing [--uk UK_JSON]

JMSML_DIR is a checkout of https://github.com/Esri/joint-military-symbology-xml,
OUT_DIR is packages/horyzontal_symbols/lib/src/catalog. The script fails if uk.json lacks a
key, has a key the source no longer has, or stores English text that differs from the source.
With --missing it only prints those lists and writes nothing.

Only the standard library is used. The XML files come from a third-party repository,
so the script never executes anything from it and only reads the instance/*.xml files.
"""

import argparse
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

NS = '{http://disa.mil/JointMilSyML.xsd}'

# Symbol sets of the number SIDC that the catalogue covers, in picker order.
# METOC sets (45, 46, 47) and the internal/unknown sets (00, 98) are left out.
SETS = [
    ('01', 'Air.xml'),
    ('02', 'Air_Missile.xml'),
    ('05', 'Space.xml'),
    ('06', 'Space_Missile.xml'),
    ('10', 'Land_Unit.xml'),
    ('11', 'Land_Civilian.xml'),
    ('15', 'Land_Equipment.xml'),
    ('20', 'Land_Installation.xml'),
    ('25', 'Control_Measure.xml'),
    ('30', 'Sea_Surface.xml'),
    ('35', 'Sea_Subsurface.xml'),
    ('36', 'Mine_Warfare.xml'),
    ('40', 'Activity.xml'),
    ('50', 'SIGINT_Space.xml'),
    ('51', 'SIGINT_Air.xml'),
    ('52', 'SIGINT_Land.xml'),
    ('53', 'SIGINT_Surface.xml'),
    ('54', 'SIGINT_Subsurface.xml'),
    ('60', 'Cyberspace.xml'),
]

LEVEL_ENTITY, LEVEL_TYPE, LEVEL_SUBTYPE = 0, 1, 2


def child(el, name):
    return el.find(NS + name)


def children(el, path):
    found = el.find(NS + path)
    return [] if found is None else list(found)


def code2(el, name):
    c = child(el, name)
    return child(c, 'DigitOne').text.strip() + child(c, 'DigitTwo').text.strip()


def remarks_of(el):
    parts = []
    r = el.get('Remarks')
    if r:
        parts.append(r.strip())
    std = el.get('Standard')
    if std == 'MILSTD_2525':
        parts.append('MIL-STD-2525 only.')
    elif std == 'NATO':
        parts.append('APP-6 only.')
    elif std:
        parts.append('Standard: %s.' % std)
    return ' '.join(parts) or None


def parse_set(path):
    root = ET.parse(path).getroot()
    entities = []
    for e in children(root, 'Entities'):
        ec = code2(e, 'EntityCode')
        entities.append(dict(code=ec + '0000', parent=None, level=LEVEL_ENTITY,
                             en=e.get('Label'), remarks=remarks_of(e)))
        for t in children(e, 'EntityTypes'):
            tc = code2(t, 'EntityTypeCode')
            entities.append(dict(code=ec + tc + '00', parent=ec + '0000', level=LEVEL_TYPE,
                                 en=t.get('Label'), remarks=remarks_of(t)))
            for s in children(t, 'EntitySubTypes'):
                sc = code2(s, 'EntitySubTypeCode')
                entities.append(dict(code=ec + tc + sc, parent=ec + tc + '00',
                                     level=LEVEL_SUBTYPE, en=s.get('Label'),
                                     remarks=remarks_of(s)))
    special = []
    for s in children(root, 'SpecialEntitySubTypes'):
        special.append(dict(code=code2(s, 'EntitySubTypeCode'), en=s.get('Label')))
    modifiers = {1: [], 2: []}
    for sector, tag in ((1, 'SectorOneModifiers'), (2, 'SectorTwoModifiers')):
        for m in children(root, tag):
            modifiers[sector].append(dict(code=code2(m, 'ModifierCode'), en=m.get('Label'),
                                          category=m.get('Category'),
                                          remarks=remarks_of(m)))
    return dict(label=root.get('Label'), entities=entities, special=special,
                modifiers=modifiers)


def parse_base(path):
    root = ET.parse(path).getroot()
    out = {}
    out['contexts'] = [(c.find(NS + 'ContextCode').text.strip(), c.get('Label'))
                       for c in children(root, 'Contexts')]
    out['identities'] = [(c.find(NS + 'StandardIdentityCode').text.strip(), c.get('Label'))
                         for c in children(root, 'StandardIdentities')]
    out['statuses'] = [(c.find(NS + 'StatusCode').text.strip(), c.get('Label'))
                       for c in children(root, 'Statuses')]
    out['hqtfd'] = [(c.find(NS + 'HQTFDummyCode').text.strip(), c.get('Label'))
                    for c in children(root, 'HQTFDummies')]
    amps = []
    for g in children(root, 'AmplifierGroups'):
        gc = g.find(NS + 'AmplifierGroupCode').text.strip()
        for a in children(g, 'Amplifiers'):
            ac = a.find(NS + 'AmplifierCode').text.strip()
            amps.append((gc + ac, g.get('Label'), a.get('Label')))
    out['amplifiers'] = amps
    out['versions'] = [(code2(v, 'VersionCode'), v.get('Name'))
                       for v in children(root, 'Versions')]
    return out


class Uk:
    """Ukrainian names from uk.json: {"names": {key: [English, Ukrainian]}, "aliases": {...}}.

    Every key is looked up exactly; there is no fallback by English label, because the same
    English word often means different things in different sets ("Light", "Space", "Missile").
    The English text stored next to each translation must match the source, so a JMSML update
    that renames an entry is reported instead of silently keeping an outdated translation.
    """

    def __init__(self, path):
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
        self.names = data['names']
        self.aliases = data.get('aliases', {})
        self.used = set()
        self.missing = []
        self.stale = []

    def get(self, key, en):
        entry = self.names.get(key)
        self.used.add(key)
        if not entry:
            self.missing.append((key, en))
            return ''
        if entry[0] != en:
            self.stale.append((key, en, entry[0]))
        return entry[1]


def dart_str(s):
    if s is None:
        return 'null'
    s = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    return "'%s'" % s


def jmsml_commit(jmsml):
    try:
        return subprocess.run(['git', '-C', jmsml, 'rev-parse', 'HEAD'], check=True,
                              capture_output=True, text=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return 'unknown'


HEADER = '''// GENERATED by tools/symbol-catalog/generate.py, do not edit by hand.
// Source: Esri joint-military-symbology-xml (Apache-2.0),
// commit %s.
// Ukrainian names: tools/symbol-catalog/uk.json.
'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('jmsml')
    ap.add_argument('out', nargs='?')
    ap.add_argument('--uk', default=os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                 'uk.json'))
    ap.add_argument('--missing', action='store_true')
    args = ap.parse_args()

    inst = os.path.join(args.jmsml, 'instance')
    base = parse_base(os.path.join(inst, 'Base.xml'))
    sets = [(code, parse_set(os.path.join(inst, f))) for code, f in SETS]
    uk = Uk(args.uk)

    lines = []
    w = lines.append
    w(HEADER % jmsml_commit(args.jmsml))

    w('/// Symbol sets: (code, English, Ukrainian).')
    w('const symbolSetData = <(String, String, String)>[')
    for code, s in sets:
        w('  (%s, %s, %s),' % (dart_str(code), dart_str(s['label']),
                               dart_str(uk.get('set:' + code, s['label']))))
    w('];\n')

    w('/// Entities per set: (code, parent, level, English, Ukrainian, remarks).')
    w('const entityData = <String, List<(String, String?, int, String, String, String?)>>{')
    for code, s in sets:
        w('  %s: [' % dart_str(code))
        for e in s['entities']:
            w('    (%s, %s, %d, %s, %s, %s),' % (
                dart_str(e['code']), dart_str(e['parent']), e['level'], dart_str(e['en']),
                dart_str(uk.get(code + ':' + e['code'], e['en'])), dart_str(e['remarks'])))
        w('  ],')
    w('};\n')

    w('/// Special entity subtypes (positions 15-16 for any entity type): (code, English, '
      'Ukrainian).')
    w('const specialSubtypeData = <String, List<(String, String, String)>>{')
    for code, s in sets:
        if not s['special']:
            continue
        w('  %s: [' % dart_str(code))
        for e in s['special']:
            w('    (%s, %s, %s),' % (dart_str(e['code']), dart_str(e['en']),
                                     dart_str(uk.get(code + ':xxxx' + e['code'], e['en']))))
        w('  ],')
    w('};\n')

    w('/// Sector modifiers per set and sector: (code, English, Ukrainian, category, remarks).')
    w('const modifierData = <String, Map<int, List<(String, String, String, String?, '
      'String?)>>>{')
    for code, s in sets:
        if not s['modifiers'][1] and not s['modifiers'][2]:
            continue
        w('  %s: {' % dart_str(code))
        for sector in (1, 2):
            if not s['modifiers'][sector]:
                continue
            w('    %d: [' % sector)
            for m in s['modifiers'][sector]:
                key = '%s:m%d:%s' % (code, sector, m['code'])
                w('      (%s, %s, %s, %s, %s),' % (
                    dart_str(m['code']), dart_str(m['en']), dart_str(uk.get(key, m['en'])),
                    dart_str(m['category']), dart_str(m['remarks'])))
            w('    ],')
        w('  },')
    w('};\n')

    def simple(name, rows, prefix):
        w('const %s = <(String, String, String)>[' % name)
        for c, en in rows:
            w('  (%s, %s, %s),' % (dart_str(c), dart_str(en), dart_str(uk.get(prefix + c, en))))
        w('];\n')

    w('/// Base tables: (code, English, Ukrainian).')
    simple('contextData', base['contexts'], 'context:')
    simple('identityData', base['identities'], 'identity:')
    simple('statusData', base['statuses'], 'status:')
    simple('hqtfdData', base['hqtfd'], 'hqtfd:')
    w('/// Amplifiers (positions 9-10): (code, English group, English, Ukrainian group, '
      'Ukrainian).')
    w('const amplifierData = <(String, String, String, String, String)>[')
    for c, g, en in base['amplifiers']:
        w('  (%s, %s, %s, %s, %s),' % (dart_str(c), dart_str(g), dart_str(en),
                                       dart_str(uk.get('ampgroup:' + c[0], g)),
                                       dart_str(uk.get('amp:' + c, en))))
    w('];\n')

    w('')
    w('/// Extra search terms (abbreviations, slang) per entity key "SS:EEEEEE".')
    w('const aliasData = <String, List<String>>{')
    for key, terms in uk.aliases.items():
        if key not in uk.used:
            uk.stale.append((key, 'alias for an unknown key', ''))
        w('  %s: [%s],' % (dart_str(key), ', '.join(dart_str(t) for t in terms)))
    w('};')

    unused = sorted(set(uk.names) - uk.used)
    for key, en in uk.missing:
        print('missing\t%s\t%s' % (key, en), file=sys.stderr)
    for key, en, old in uk.stale:
        print('stale\t%s\tsource: %s\tuk.json: %s' % (key, en, old), file=sys.stderr)
    for key in unused:
        print('unused\t%s\t%s' % (key, uk.names[key][0]), file=sys.stderr)
    if args.missing:
        return
    if uk.missing or uk.stale or unused:
        sys.exit('uk.json does not match the source tables, see the list above')
    if not args.out:
        ap.error('OUT_DIR is required')
    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, 'data.g.dart'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
