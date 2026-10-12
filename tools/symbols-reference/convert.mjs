// Mechanical JS -> Dart converter for milsymbol data files (icon parts and
// number SIDC tables). The output is a starting point: run `dart format` and
// `dart analyze` on it and hand-fix what is left (string + number
// concatenation, non-bool truthiness, helper calls). The checked-in Dart is
// the source of truth, this script is never run by the build.
//
// Usage:
//   node tools/symbols-reference/convert.mjs iconparts <file.js> <dartFunctionName> > out.dart
//   node tools/symbols-reference/convert.mjs sidc <file.js> <dartFunctionName> > out.dart
//
// It only reads the given file as text, it never imports or executes it.

import { readFileSync } from "node:fs";

const [mode, file, dartName] = process.argv.slice(2);
if (!["iconparts", "sidc"].includes(mode) || !file || !dartName) {
  console.error(
    "usage: convert.mjs iconparts|sidc <file.js> <dartFunctionName>"
  );
  process.exit(2);
}
const src = readFileSync(file, "utf8").replace(/\r\n/g, "\n");

// ---------------------------------------------------------------- tokenizer
function tokenize(s) {
  const out = [];
  let i = 0;
  const isIdStart = (c) => /[A-Za-z_$]/.test(c);
  const isId = (c) => /[A-Za-z0-9_$]/.test(c);
  while (i < s.length) {
    const c = s[i];
    if (/\s/.test(c)) {
      let j = i;
      while (j < s.length && /\s/.test(s[j])) j++;
      out.push({ t: "ws", v: s.slice(i, j) });
      i = j;
    } else if (c === "/" && s[i + 1] === "/") {
      let j = s.indexOf("\n", i);
      if (j < 0) j = s.length;
      out.push({ t: "comment", v: s.slice(i, j) });
      i = j;
    } else if (c === "/" && s[i + 1] === "*") {
      const j = s.indexOf("*/", i + 2) + 2;
      out.push({ t: "comment", v: s.slice(i, j) });
      i = j;
    } else if (c === '"' || c === "'") {
      let j = i + 1;
      while (s[j] !== c) {
        if (s[j] === "\\") j++;
        j++;
      }
      out.push({ t: "string", v: s.slice(i + 1, j), q: c });
      i = j + 1;
    } else if (c === "`") {
      throw new Error("template literal at offset " + i + ", convert by hand");
    } else if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(s[i + 1]))) {
      const m = /^(0[xX][0-9a-fA-F]+|[0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)/.exec(
        s.slice(i)
      );
      out.push({ t: "number", v: m[0] });
      i += m[0].length;
    } else if (isIdStart(c)) {
      let j = i;
      while (j < s.length && isId(s[j])) j++;
      out.push({ t: "ident", v: s.slice(i, j) });
      i = j;
    } else {
      const three = s.slice(i, i + 3);
      const two = s.slice(i, i + 2);
      if (["===", "!=="].includes(three)) {
        out.push({ t: "punct", v: three });
        i += 3;
      } else if (
        ["==", "!=", "<=", ">=", "&&", "||", "=>", "+=", "-=", "++", "--"].includes(
          two
        )
      ) {
        out.push({ t: "punct", v: two });
        i += 2;
      } else {
        out.push({ t: "punct", v: c });
        i += 1;
      }
    }
  }
  return out;
}

function dartString(content, quote) {
  // Keep JS escapes (Dart understands the same ones), escape `$` and quotes.
  let r = "";
  for (let i = 0; i < content.length; i++) {
    const ch = content[i];
    if (ch === "\\") {
      const next = content[i + 1];
      if (next === '"') r += '"';
      else r += "\\" + next;
      i++;
    } else if (ch === "$") r += "\\$";
    else if (ch === "'") r += "\\'";
    else r += ch;
  }
  return "'" + r + "'";
}

const renames = { STD2525: "std2525", _STD2525: "std2525", undefined: "null" };

// ------------------------------------------------------- function extraction
let params = [];
function extractBody(s) {
  const re =
    mode === "iconparts"
      ? /export\s+default\s+function\s*\w*\s*\(([^)]*)\)\s*\{/
      : /icons\s*:\s*function\s*\w*\s*\(([^)]*)\)\s*\{/;
  const m = re.exec(s);
  if (!m) throw new Error("main function not found");
  // Parameter names as milsymbol spells them (e.g. `sidc` instead of `sId`).
  params = m[1]
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean)
    .map((p) => renames[p] ?? p);
  const start = m.index + m[0].length;
  const toks = tokenize(s.slice(start));
  let depth = 1;
  let n = 0;
  for (; n < toks.length; n++) {
    const t = toks[n];
    if (t.t === "punct" && t.v === "{") depth++;
    if (t.t === "punct" && t.v === "}") {
      depth--;
      if (depth === 0) break;
    }
  }
  return toks.slice(0, n);
}

// ---------------------------------------------------------------- converter

function convert(toks) {
  const out = [];
  const stack = []; // {kind: obj|block|arr|paren|index, expectKey}
  let prev = null; // previous significant token
  const sig = (k) => {
    for (let j = k; j < toks.length; j++)
      if (toks[j].t !== "ws" && toks[j].t !== "comment") return j;
    return -1;
  };
  const top = () => stack[stack.length - 1];
  const literalBefore = () =>
    prev === null ||
    (prev.t === "punct" && ![")", "]", "}"].includes(prev.v)) ||
    (prev.t === "ident" && ["return", "in", "of", "typeof"].includes(prev.v));

  for (let i = 0; i < toks.length; i++) {
    const t = toks[i];
    if (t.t === "ws") {
      out.push(t.v);
      continue;
    }
    if (t.t === "comment") {
      // Dart block comments nest, JS ones do not.
      out.push(
        t.v.startsWith("/*")
          ? "/*" + t.v.slice(2, -2).replaceAll("/*", "/ *").replace(/\/$/, "/ ") + "*/"
          : t.v
      );
      continue;
    }
    // Final registration loop of an icon-parts file.
    if (
      mode === "iconparts" &&
      t.t === "ident" &&
      t.v === "for" &&
      /^\s*\(\s*const\s+key\s+in\s+icn\s*\)/.test(
        toks
          .slice(i + 1, i + 12)
          .map((x) => (x.t === "string" ? x.q + x.v + x.q : x.v))
          .join("")
      )
    ) {
      let j = i;
      while (!(toks[j].t === "punct" && toks[j].v === "{")) j++;
      let depth = 0;
      for (; j < toks.length; j++) {
        if (toks[j].t === "punct" && toks[j].v === "{") depth++;
        if (toks[j].t === "punct" && toks[j].v === "}") {
          depth--;
          if (depth === 0) break;
        }
      }
      out.push("registerIconParts(iconParts, icn, iconColor);");
      i = j;
      prev = { t: "punct", v: ";" };
      continue;
    }
    // for (const k in obj) -> for (final k in obj.keys)
    if (t.t === "ident" && t.v === "for") {
      const a = sig(i + 1);
      const b = sig(a + 1);
      const c = sig(b + 1);
      const d = sig(c + 1);
      const e = sig(d + 1);
      if (
        toks[a].v === "(" &&
        ["const", "let", "var"].includes(toks[b].v) &&
        toks[d].v === "in"
      ) {
        out.push(`for (final ${toks[c].v} in ${toks[e].v}.keys`);
        i = e;
        prev = { t: "ident", v: toks[e].v };
        stack.push({ kind: "paren" });
        continue;
      }
    }
    if (t.t === "ident") {
      // ms._scale / ms._translate
      if (t.v === "ms") {
        const a = sig(i + 1);
        const b = sig(a + 1);
        if (toks[a].v === "." && ["_scale", "_translate"].includes(toks[b].v)) {
          out.push(toks[b].v === "_scale" ? "msScale" : "msTranslate");
          i = b;
          prev = { t: "ident", v: "msScale" };
          continue;
        }
      }
      if (top() && top().kind === "obj" && top().expectKey) {
        const a = sig(i + 1);
        if (toks[a].v === ":") {
          out.push(dartString(t.v, '"'));
          top().expectKey = false;
          prev = { t: "string", v: t.v };
          continue;
        }
      }
      let v = t.v;
      if (v === "const") v = "final";
      else if (v === "let") v = "var";
      else if (v === "hasOwnProperty") v = "containsKey";
      else if (Object.hasOwn(renames, v)) v = renames[v];
      if (top() && top().kind === "obj") top().expectKey = false;
      out.push(v);
      prev = t;
      continue;
    }
    if (t.t === "string" || t.t === "number") {
      const isKey =
        top() &&
        top().kind === "obj" &&
        top().expectKey &&
        toks[sig(i + 1)].v === ":";
      if (top() && top().kind === "obj") top().expectKey = false;
      out.push(
        t.t === "string" ? dartString(t.v, t.q) : isKey ? `'${t.v}'` : t.v
      );
      prev = t;
      continue;
    }
    // punctuation
    let v = t.v;
    if (v === "===") v = "==";
    if (v === "!==") v = "!=";
    if (v === "=>") throw new Error("arrow function, convert by hand");
    if (v === "{") {
      if (literalBefore()) {
        stack.push({ kind: "obj", expectKey: true });
        out.push("<String, Object?>{");
      } else {
        stack.push({ kind: "block" });
        out.push("{");
      }
    } else if (v === "[") {
      if (literalBefore()) {
        stack.push({ kind: "arr" });
        out.push("<Object?>[");
      } else {
        stack.push({ kind: "index" });
        out.push("[");
      }
    } else if (v === "(") {
      stack.push({ kind: "paren" });
      out.push("(");
    } else if (v === "}" || v === "]" || v === ")") {
      stack.pop();
      out.push(v);
    } else {
      if (v === "," && top() && top().kind === "obj") top().expectKey = true;
      else if (top() && top().kind === "obj") top().expectKey = false;
      out.push(v);
    }
    prev = { t: "punct", v: t.v };
  }
  return out.join("");
}

// Patterns that are not valid Dart on dynamic maps, fixed on the output text.
function postProcess(dart) {
  return (
    dart
      // icn["X"].push(...) on an array part
      .replace(/(icn\['(?:[^'\\]|\\.)*'\])\.push\(/g, "($1 as JsArray).add(")
      // icn["X"].fill = ... on an object part
      .replace(/(icn\['(?:[^'\\]|\\.)*'\])\.(\w+)(\s*=[^=])/g, "($1 as JsObject)['$2']$3")
      // colors.fillColor.Friend
      .replace(
        /(colors\.\w+)\.(Civilian|Friend|Hostile|Neutral|Unknown|Suspect)\b/g,
        (_, a, b) => `${a}.${b.toLowerCase()}`
      )
      // monoColor is a String in Dart: `!monoColor`, `monoColor ? a : b`, `monoColor && x`
      .replace(/!monoColor\b/g, "!truthy(monoColor)")
      .replace(/(?<![\w.(])monoColor(?=\s*(?:\?(?![?.])|&&|\|\|))/g, "truthy(monoColor)")
      // const affiliation = metadata.affiliation || "Friend";
      .replace(
        "metadata.affiliation || 'Friend'",
        "truthy(metadata.affiliation) ? metadata.affiliation! : 'Friend'"
      )
      // "M" + baseGeometry.bbox.x1: JS number to string
      .replace(/baseGeometry\.bbox\.(x1|x2|y1|y2)(?!!)/g, "baseGeometry.bbox.$1!")
      .replace(/\((200 - baseGeometry\.bbox\.x1!)\) \+/g, "jsString($1) +")
      .replace(
        /(\+\s*)(baseGeometry\.bbox\.(?:x1|x2|y1|y2)!)(\s*\+|\s*[}\]])/g,
        "$1jsString($2)$3"
      )
  );
}

// Dart parameters: fixed types by position, milsymbol's names where given.
function sig(types, defaults) {
  return types.map((t, i) => `  ${t} ${params[i] ?? defaults[i]},`).join("\n");
}

const rel = file.replace(/^.*?\/src\//, "src/");
const body = postProcess(convert(extractBody(src)));
const header = `// Ported from milsymbol ${rel}, MIT (c) Måns Beckman.
// Generated by tools/symbols-reference/convert.mjs and dart format; hand edits: none.
// ignore_for_file: unused_local_variable, prefer_interpolation_to_compose_strings
`;
const msImport = /\bms(Scale|Translate)\(/.test(body);
if (mode === "iconparts") {
  process.stdout.write(`${header}
import '../js.dart';
import '../colors.dart';
import '../metadata.dart';
${msImport ? "import '../ms.dart';\n" : ""}import 'iconparts_functions.dart';

/// Icon parts from \`${rel}\`.
void ${dartName}(
${sig(["JsObject", "SymbolMetadata", "SymbolColors", "bool", "String", "bool"], ["iconParts", "metadata", "colors", "std2525", "monoColor", "alternateMedal"])}
) {${body}}
`);
} else {
  process.stdout.write(`${header}
import '../../js.dart';
${msImport ? "import '../../ms.dart';\n" : ""}
/// SIDC table from \`${rel}\`.
void ${dartName}(
${sig(["JsObject", "JsObject", "JsObject", "JsObject", "String", "JsObject", "bool", "String?"], ["sId", "sIdm1", "sIdm2", "bbox", "symbolSet", "icn", "std2525", "edition"])}
) {${body}}
`);
}
