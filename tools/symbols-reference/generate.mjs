// Reference fixtures for packages/horyzontal_symbols, rendered by milsymbol.
//
//   node tools/symbols-reference/generate.mjs <milsymbol package dir> <fixtures dir>
//
// <milsymbol package dir> is an unpacked npm `milsymbol` 3.0.4 (the folder
// with package.json, index.mjs and src/). Only the number SIDC modules that
// the Dart port has (PORTED below) are registered, in milsymbol's own order,
// so the reference is "milsymbol with exactly these modules loaded".
//
// Output: <name>.jsonl.gz per corpus group, manifest.json, js_number.json.

import { createHash } from "node:crypto";
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { gzipSync } from "node:zlib";

const [pkgArg, outArg] = process.argv.slice(2);
if (!pkgArg || !outArg) {
  console.error("usage: generate.mjs <milsymbol package dir> <fixtures dir>");
  process.exit(2);
}
const pkg = pathToFileURL(resolve(pkgArg)).href;
const outDir = resolve(outArg);
const { ms } = await import(pkg + "/index.mjs");
const N = await import(pkg + "/src/numbersidc.js");

// ---------------------------------------------------------------- modules
// Number SIDC modules ported to Dart. Keep in sync with
// packages/horyzontal_symbols/lib/src/numbersidc.dart. Add a module name
// here when its Dart port lands, then regenerate ALL fixtures.
const PORTED = [
  "common",
  "landunit",
  "landcivilian",
  "landequipment",
  "landinstallation",
  "activites",
  "dismountedindividual",
  "air",
  "airmissile",
];
const ported = PORTED.map((n) => {
  if (!N[n]) throw new Error("unknown module " + n);
  return N[n];
});
// Same as index.js minus the letter modules: app6d, std2525d, std2525e.
for (const list of [N.app6d, N.std2525d, N.std2525e]) {
  ms.addIcons(list.filter((m) => ported.includes(m)));
}

// ------------------------------------------------------------- rendering
const metaSkip = new Set(["baseGeometry"]);
function render(sidc, options) {
  // A cold cache for every symbol: milsymbol scales cached icon parts in
  // place, so warm-cache output depends on the rendering order.
  ms._iconCache = {};
  ms._labelCache = {};
  const opts = options ? JSON.parse(JSON.stringify(options)) : {};
  try {
    const s = new ms.Symbol(sidc, opts);
    const svg = s.asSVG();
    const size = s.getSize();
    const a = s.getAnchor();
    const o = s.getOctagonAnchor();
    const metadata = {};
    for (const k of Object.keys(s.metadata)) {
      if (!metaSkip.has(k)) metadata[k] = s.metadata[k];
    }
    return {
      svg,
      size: [size.width, size.height],
      anchor: [a.x, a.y],
      octagonAnchor: [o.x, o.y],
      isValid: s.isValid(),
      validity: s.isValid(true),
      metadata,
      colors: s.getColors(),
    };
  } catch (e) {
    return { error: String(e) };
  }
}

// Deterministic PRNG (mulberry32).
function prng(seed) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// 20 digit SIDC: version, context, identity, set, status, HQ/TF/FD,
// echelon/mobility, entity (6), modifier 1, modifier 2.
function sidc20({ v = "10", ctx = "0", si = "3", set = "10", st = "0", hq = "0", ech = "00", ent = "000000", m1 = "00", m2 = "00" }) {
  return v + ctx + si + set + st + hq + ech + ent + m1 + m2;
}
// 30 digit SIDC (2525E): adds modifier 1/2 first digits, frame shape and
// 7 reserved/country digits.
function sidc30(p, { m1x = "0", m2x = "0", frame = "0", rest = "0000000" } = {}) {
  return sidc20(p) + m1x + m2x + frame + rest;
}

const AFF = ["3", "6", "4", "1"]; // friend, hostile, neutral, unknown
const groups = {};
function add(group, sets, sidc, options) {
  (groups[group] ??= []).push({ sets, sidc, options: options ?? {} });
}

// ------------------------------------------------------ symbol set families
// One group of fixture files per family of ported modules: every entity in
// four affiliations, every sector modifier code. Add a family here when its
// modules are ported (and its module names to PORTED above).
const FAMILIES = [
  { name: "land", sets: ["10", "11", "15", "20", "27", "40"] },
  { name: "air", sets: ["01"] },
  { name: "airmissile", sets: ["02"] },
  // { name: "space", sets: ["05"] },
  // { name: "spacemissile", sets: ["06"] },
  // { name: "sea", sets: ["30"] },
  // { name: "subsurface", sets: ["35"] },
  // { name: "minewarfare", sets: ["36"] },
  // { name: "signalsintelligence", sets: ["50", "51", "52", "53", "54"] },
  // { name: "cyberspace", sets: ["60"] },
  // { name: "tacticalpoints", sets: ["25"] },
];
// Entity used for the modifier fixtures of a set; default: first entity
// code that draws something.
const REPRESENTATIVE = { 10: "121100", 11: "110100", 15: "110100", 20: "110000", 27: "110100", 40: "110100" };
// Sets whose icon milsymbol shrinks when sector modifiers are present (icon.js).
const SCALED_SETS = ["15", "27"];

const probe = new ms.Symbol("10031000000000000000");

// Codes defined by the registered tables for a set (2525 and APP-6, D and E).
function tableKeys(set) {
  const icons = new Set(), m1 = new Set(), m2 = new Set();
  for (const std of [true, false]) {
    for (const ed of ["D", "E"]) {
      const parts = ms._getIconParts(probe.metadata, probe.colors, std, "", false);
      const t = ms._getIcons.number(ms, set, parts, std, ed);
      Object.keys(t.icons).forEach((k) => icons.add(k));
      Object.keys(t.m1).forEach((k) => m1.add(k));
      Object.keys(t.m2).forEach((k) => m2.add(k));
    }
  }
  const sort = (x) => [...x].sort();
  return { icons: sort(icons).filter((k) => /^\d{6}$/.test(k)), m1: sort(m1), m2: sort(m2) };
}

// Icon part keys the ported tables use but no ported icon-parts file
// defines: they end up as `undefined` (invalid symbol) or, inside
// ms._scale(..., true), as an exception.
{
  const warn = console.warn;
  console.warn = () => {};
  const missing = new Set();
  for (const std of [true, false]) {
    const parts = ms._getIconParts(probe.metadata, probe.colors, std, "", false);
    const icn = new Proxy(parts, {
      get(t, k) {
        if (typeof k === "string" && !(k in t)) missing.add(k);
        return t[k];
      },
    });
    for (const set of FAMILIES.flatMap((f) => f.sets)) {
      for (const f of ms._iconSIDC.number) {
        try {
          f.call(ms, {}, {}, {}, {}, set, icn, std, "D");
        } catch (e) {
          missing.add(`(exception for set ${set}: ${e})`);
        }
      }
    }
  }
  console.warn = warn;
  if (missing.size) console.log("icon parts referenced but not defined:", [...missing]);
}

{
  let k = 0;
  for (const fam of FAMILIES) {
    const g = fam.name;
    for (const set of fam.sets) {
      const t = tableKeys(set);
      // Every entity, all four affiliations in 2525 and one rotating
      // affiliation in APP-6.
      for (const ent of t.icons) {
        for (const si of AFF) add(g, [set], sidc20({ si, set, ent }));
        add(g, [set], sidc20({ si: AFF[k++ % 4], set, ent }), { standard: "APP6" });
      }
      // Sector modifiers: every 2 digit code with a representative entity,
      // every 3 digit (2525E common) code via 30 digit SIDCs.
      const rep = REPRESENTATIVE[set] ?? t.icons.find((e) => e !== "000000") ?? "000000";
      const gm = `${g}-modifiers`;
      for (const code of t.m1) {
        if (/^\d{2}$/.test(code)) {
          add(gm, [set], sidc20({ si: AFF[k++ % 4], set, ent: rep, m1: code }));
        } else if (/^\d{3}$/.test(code)) {
          add(gm, [set], sidc30({ v: "13", si: AFF[k++ % 4], set, ent: rep, m1: code.slice(1) }, { m1x: code[0] }));
        }
      }
      for (const code of t.m2) {
        if (/^\d{2}$/.test(code)) {
          add(gm, [set], sidc20({ si: AFF[k++ % 4], set, ent: rep, m2: code }), k % 3 ? {} : { standard: "APP6" });
        } else if (/^\d{3}$/.test(code)) {
          add(gm, [set], sidc30({ v: "13", si: AFF[k++ % 4], set, ent: rep, m2: code.slice(1) }, { m2x: code[0] }));
        }
      }
      // Unknown modifier codes.
      add(gm, [set], sidc20({ set, ent: rep, m1: "99" }));
      add(gm, [set], sidc20({ set, ent: rep, m2: "99" }));
      add(gm, [set], sidc30({ v: "13", set, ent: rep, m1: "99" }, { m1x: "9" }));
      // Special entity subtypes 95-98 (headquarters element, support
      // levels) and an unknown subtype that falls back to the entity.
      for (const ent of [rep, ...t.icons.filter((e) => e.endsWith("00") && e !== "000000").slice(0, 3)]) {
        for (const sub of ["95", "96", "97", "98", "99"]) {
          add(gm, [set], sidc20({ si: AFF[k++ % 4], set, ent: ent.slice(0, 4) + sub }));
        }
      }
      // Icons that shrink with sector modifiers: every entity with modifier
      // 1, 2 and both.
      if (SCALED_SETS.includes(set)) {
        const m1 = t.m1.find((c) => /^\d{2}$/.test(c));
        const m2 = t.m2.find((c) => /^\d{2}$/.test(c));
        for (const ent of t.icons) {
          const si = AFF[k++ % 4];
          add(`${g}-scaled`, [set], sidc20({ si, set, ent, m1 }));
          add(`${g}-scaled`, [set], sidc20({ si, set, ent, m2 }));
          add(`${g}-scaled`, [set], sidc20({ si, set, ent, m1, m2 }), k % 2 ? { outlineWidth: 2, monoColor: "black" } : {});
        }
      }
    }
  }
}

// ------------------------------------------------------------- amplifiers
// Frame, status, HQ/TF/FD, echelon, mobility: entity 000000 except where an
// icon matters, so these depend only on the core.
{
  const allSets = ["00", "01", "02", "05", "06", "10", "11", "15", "20", "27", "30", "35", "36", "39", "40", "50", "51", "52", "53", "54", "60"];
  for (const set of allSets) {
    for (const si of ["0", "1", "2", "3", "4", "5", "6"]) {
      for (const ctx of ["0", "1", "2"]) {
        add("core-frames", ["core"], sidc20({ ctx, si, set }));
      }
      add("core-frames", ["core"], sidc20({ v: "13", si, set }));
    }
  }
  // Exercise joker/faker, simulation and 2525E suspect.
  for (const [ctx, si] of [["1", "5"], ["1", "6"], ["2", "5"], ["0", "5"]]) {
    for (const v of ["10", "13"]) add("core-frames", ["core"], sidc20({ v, ctx, si }));
  }
  // 2525E frame shape override (position 23) on land unit and equipment.
  for (const frame of ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A"]) {
    for (const si of AFF) {
      add("core-frames", ["core"], sidc30({ v: "13", si, set: "10" }, { frame }));
    }
    add("core-frames", ["core"], sidc30({ v: "10", si: "3", set: "15" }, { frame }));
  }
  for (const si of AFF) {
    for (const st of ["0", "1", "2", "3", "4", "5"]) {
      for (const set of ["10", "15"]) add("core-amplifiers", ["core"], sidc20({ si, set, st }));
      add("core-amplifiers", ["core"], sidc20({ si, set: "10", st, hq: "2" }), { headquartersElement: "TOC" });
    }
    for (const hq of ["0", "1", "2", "3", "4", "5", "6", "7"]) {
      for (const set of ["10", "20", "01", "30", "35"]) add("core-amplifiers", ["core"], sidc20({ si, set, hq }));
      add("core-amplifiers", ["core"], sidc20({ si, set: "10", hq, ech: "23" }));
    }
    for (const ech of ["11", "12", "13", "14", "15", "16", "17", "18", "21", "22", "23", "24", "25", "26"]) {
      add("core-amplifiers", ["core"], sidc20({ si, ech }));
      add("core-amplifiers", ["core"], sidc20({ si, set: "20", ech, hq: "4" }));
    }
    for (const ech of ["31", "32", "33", "34", "35", "36", "37", "41", "42", "51", "52", "61", "62"]) {
      add("core-amplifiers", ["core"], sidc20({ si, set: "15", ech }));
      add("core-amplifiers", ["core"], sidc20({ si, set: "10", ech, st: "3" }));
      add("core-amplifiers", ["core"], sidc20({ si, set: "15", ech }), { frame: false });
    }
    for (const ech of ["71", "72"]) add("core-amplifiers", ["core"], sidc20({ si, set: "27", ech }));
    for (const ech of ["19", "27", "38", "45", "69", "99"]) add("core-amplifiers", ["core"], sidc20({ si, ech }));
  }
}

// ---------------------------------------------------------------- options
{
  const bases = [
    sidc20({ ent: "121100" }), // friend infantry
    sidc20({ si: "6", ent: "120500", hq: "2", ech: "16" }), // hostile armour battalion HQ
    sidc20({ si: "4", set: "15", ent: "110100", ech: "33" }), // neutral equipment tracked
    sidc20({ si: "1", set: "20", ent: "110500" }), // unknown installation
    sidc20({ si: "3", set: "27", ent: "110101" }), // dismounted individual
    sidc20({ si: "6", set: "40", ent: "110100", st: "1" }), // hostile planned activity
    sidc20({ si: "3", set: "11", ent: "110100", st: "2" }), // civilian, fully capable
    sidc20({ si: "2", ent: "121100", hq: "6", ech: "22" }), // assumed friend HQ task force corps
    sidc20({ si: "3", set: "01" }), // air frame
    sidc20({ si: "5", set: "30", st: "4" }), // suspect sea, destroyed
    sidc20({ si: "3", set: "35", ech: "61" }), // subsurface, towed array
    sidc20({ si: "6", set: "36", st: "1" }), // hostile planned sea mine (MEDAL)
  ];
  const aff = (f, h, n, u, c, s) => ({ Friend: f, Hostile: h, Neutral: n, Unknown: u, Civilian: c, Suspect: s });
  const texts = {
    quantity: "200",
    reinforcedReduced: "(+)",
    staffComments: "SC",
    additionalInformation: "AI",
    evaluationRating: "A1",
    combatEffectiveness: "CE",
    signatureEquipment: "!",
    higherFormation: "1-23",
    hostile: "ENY",
    iffSif: "IFF",
    sigint: "SIG",
    uniqueDesignation: "A",
    type: "T-80",
    dtg: "301200ZOCT26",
    altitudeDepth: "FL300",
    location: "38TLN1234",
    speed: "20KPH",
    specialHeadquarters: "MA",
    country: "UA",
    platformType: "PT",
    equipmentTeardownTime: "ETT",
    commonIdentifier: "CI",
    auxiliaryEquipmentIndicator: "AUX",
    headquartersElement: "TOC",
    installationComposition: "IC",
    guardedUnit: "GU",
    specialDesignator: "SD",
  };
  const variants = [
    {},
    { size: 35 },
    { size: 5 },
    { size: 100.5, strokeWidth: 2 },
    { strokeWidth: 6.5 },
    { fill: false },
    { frame: false },
    { icon: false },
    { frame: false, icon: false },
    { fill: false, frame: false },
    { fill: false, frame: false, icon: false },
    { monoColor: "black" },
    { monoColor: "rgb(0, 0, 0)", outlineWidth: 3 },
    { colorMode: "Light" },
    { colorMode: "Medium" },
    { colorMode: "Dark" },
    { colorMode: aff("red", "blue", "green", "yellow", "purple", "orange") },
    { outlineWidth: 4 },
    { outlineWidth: 2, outlineColor: "white" },
    { outlineWidth: 3, outlineColor: aff("#111", "#222", "#333", "#444", "#555", "#666") },
    { outlineWidth: 2, fill: false },
    { fillOpacity: 0.5 },
    { fillOpacity: 2 },
    { fillColor: "pink" },
    { frameColor: aff("navy", "maroon", "olive", "teal", "purple", "gold") },
    { iconColor: aff("navy", "maroon", "olive", "teal", "purple", "gold") },
    { frameColor: "red" },
    { standard: "APP6" },
    { standard: "2525" },
    { padding: 10 },
    { square: true },
    { square: true, padding: 5, uniqueDesignation: "LONG NAME" },
    { hqStaffLength: 50 },
    { civilianColor: false },
    { simpleStatusModifier: true },
    { alternateMedal: true },
    { styleFill: true },
    { fontfamily: "Verdana" },
    { infoFields: false, uniqueDesignation: "A", direction: 90 },
    { ...texts },
    { ...texts, infoBackground: "white" },
    { ...texts, infoBackground: "rgba(255,255,255,0.6)", infoBackgroundFrame: "black", stack: 2 },
    { ...texts, infoColor: "red", infoSize: 60 },
    { ...texts, infoColor: aff("a", "b", "c", "d", "e", "f"), outlineWidth: 2 },
    { ...texts, infoOutlineWidth: 2 },
    { ...texts, infoOutlineColor: "yellow", outlineWidth: 2 },
    { ...texts, infoOutlineColor: "", outlineWidth: 2, outlineColor: aff("1", "2", "3", "4", "5", "6") },
    { uniqueDesignation: "Батальйон", higherFormation: "Їжак ґанок" },
    { uniqueDesignation: '<&>"\'', staffComments: "a\nnull" },
    { uniqueDesignation: "null" },
    { country_flag: true, higherFormation: "X", additionalInformation: "Y" },
    { full_frame_flag: true, country_flag: true, higherFormation: "X" },
    { signature: "!", evaluationRating: "B2" },
    { direction: 0 },
    { direction: 45 },
    { direction: 200.5, outlineWidth: 2 },
    { direction: "120" },
    { direction: 270, speedLeader: 50 },
    { direction: 30, speedLeader: 40, size: 50, outlineWidth: 1 },
    { engagementBar: "A:FIRE:12", engagementType: "TARGET" },
    { engagementBar: "B", engagementType: "non-target" },
    { engagementBar: "LONG ENGAGEMENT BAR", engagementType: "EXPIRED", outlineWidth: 2 },
    { engagementBar: "X", monoColor: "blue" },
    { stack: 1 },
    { stack: 3, outlineWidth: 2 },
    { stack: 2, frame: false },
  ];
  for (const v of variants) {
    for (const b of bases) add("core-options", ["core"], b, v);
  }
  // Text fields alone, on land unit, equipment and dismounted.
  for (const [k, val] of Object.entries(texts)) {
    for (const b of [bases[0], bases[2], bases[4], bases[5], bases[8], bases[9], bases[10], bases[11]]) {
      add("core-options", ["core"], b, { [k]: val });
    }
  }
}

// ---------------------------------------------------------------- invalid
{
  const bad = [
    sidc20({ si: "7" }),
    sidc20({ si: "9", ent: "121100" }),
    sidc20({ set: "99", ent: "121100" }),
    sidc20({ set: "99" }),
    sidc20({ ent: "129900" }),
    sidc20({ ent: "999999" }),
    sidc20({ set: "15", ent: "999900", m1: "01" }),
    sidc20({ set: "27", ent: "999900", m2: "01" }),
    sidc20({ ctx: "5" }),
    sidc20({ v: "09" }),
    sidc20({ v: "99", ent: "121100" }),
    sidc20({ st: "9" }),
    sidc20({ hq: "8" }),
    "1003100000121100000A",
    "10031000001211000*00",
    "1003 1000 0012 1100 0000",
    "10031000001211",
    "1003100000",
    "1003",
    "10",
    "1",
    "",
    "10031000001211000000123",
    "1003100000121100000000000000000000",
    sidc20({ ent: "1211A0" }),
    sidc20({ set: "15", ent: "12A000" }),
  ];
  for (const s of bad) {
    add("core-invalid", ["core"], s);
    add("core-invalid", ["core"], s, { outlineWidth: 2, uniqueDesignation: "U" });
  }
}

// ------------------------------------------------------------------ write
mkdirSync(outDir, { recursive: true });
// Hash of milsymbol's src/ tree, to tell a different copy from a port bug.
function srcHash(dir) {
  const h = createHash("sha256");
  const walk = (d) => {
    for (const e of readdirSync(d, { withFileTypes: true }).sort((a, b) => (a.name < b.name ? -1 : 1))) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else h.update(p.slice(dir.length) + "\0").update(readFileSync(p));
    }
  };
  walk(dir);
  return h.digest("hex");
}
const manifest = {
  milsymbol: ms.version,
  milsymbolSrcSha256: srcHash(join(resolve(pkgArg), "src")),
  modules: PORTED,
  files: [],
};
let id = 0;
for (const [group, items] of Object.entries(groups)) {
  const lines = [];
  const sets = new Set();
  let errors = 0;
  for (const it of items) {
    const r = render(it.sidc, it.options);
    if (r.error) errors++;
    if (!group.startsWith("core-options")) delete r.colors;
    it.sets.forEach((s) => sets.add(s));
    lines.push(JSON.stringify({ id: id++, sets: it.sets, sidc: it.sidc, options: it.options, ...r }));
  }
  const name = `${group}.jsonl.gz`;
  writeFileSync(join(outDir, name), gzipSync(lines.join("\n") + "\n", { level: 9 }));
  manifest.files.push({ name, sets: [...sets].sort(), count: items.length, errors });
  console.log(`${name}: ${items.length} symbols, ${errors} milsymbol errors`);
}
writeFileSync(join(outDir, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");

// JS number formatting reference: [IEEE-754 bits as hex, String(x)].
{
  const rnd = prng(42);
  const vals = [0, -0, 1, -1, 0.1, 0.2, 0.1 + 0.2, 1 / 3, 2 / 3, 100, 54.99999999999999, 1e21, 1e-7, 1.5e-7, 123e-20, 1e300, 5e-324, 2 ** 53, 2 ** 53 + 2, 1e20, 123456789012345680000, NaN, Infinity, -Infinity];
  for (let i = 0; i < 2000; i++) {
    const e = Math.floor(rnd() * 60) - 30;
    vals.push((rnd() - 0.5) * 10 ** e, Math.round(rnd() * 1e6) / 10 ** Math.floor(rnd() * 8));
  }
  const buf = new DataView(new ArrayBuffer(8));
  const rows = vals.map((v) => {
    buf.setFloat64(0, v);
    return [buf.getBigUint64(0).toString(16).padStart(16, "0"), String(v)];
  });
  writeFileSync(join(outDir, "js_number.json"), JSON.stringify(rows) + "\n");
}
