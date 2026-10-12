// Helpers shared by the symbol parts (not a milsymbol file).

import '../symbol.dart';

/// `typeof style.outlineColor === "object" ? style.outlineColor[affiliation] : style.outlineColor`.
Object? outlineColorOf(MilSymbol s) => colorFor(s.options.outlineColor, s.metadata.affiliation);

/// `modifier[affiliation]` for the frame modifier tables.
T? byAffiliation<T>(Map<String, T> table, String? affiliation) =>
    affiliation == null ? null : table[affiliation];
