// Ported from milsymbol src/numbersidc.js and the module objects of
// src/numbersidc/sidc/*.js, MIT (c) Måns Beckman.

import 'iconparts/air.dart';
import 'iconparts/common_modifiers.dart';
import 'iconparts/ground.dart';
import 'ms.dart';
import 'numbersidc/sidc/activites.dart';
import 'numbersidc/sidc/air.dart';
import 'numbersidc/sidc/airmissile.dart';
import 'numbersidc/sidc/common.dart';
import 'numbersidc/sidc/dismountedindividual.dart';
import 'numbersidc/sidc/landcivilian.dart';
import 'numbersidc/sidc/landequipment.dart';
import 'numbersidc/sidc/landinstallation.dart';
import 'numbersidc/sidc/landunit.dart';

// One module per milsymbol file in src/numbersidc/sidc. Modules that are
// not ported yet are listed as comments in the lists below, at their
// milsymbol position; a symbol of their symbol sets draws the frame with
// milsymbol's unknown-icon question mark and is not valid.

/// 2525E common modifiers (3 digit sector 1/2 codes of 30 digit SIDCs).
const common = SymbolSetModule(
  name: 'common',
  symbolSets: [],
  iconParts: commonModifierIconParts,
  icons: commonIcons,
);

/// Symbol set 10, land unit.
const landunit = SymbolSetModule(
  name: 'landunit',
  symbolSets: ['10'],
  iconParts: groundIconParts,
  icons: landunitIcons,
);

/// Symbol set 11, land civilian unit/organization.
const landcivilian = SymbolSetModule(
  name: 'landcivilian',
  symbolSets: ['11'],
  iconParts: groundIconParts,
  icons: landcivilianIcons,
);

/// Symbol set 15, land equipment.
const landequipment = SymbolSetModule(
  name: 'landequipment',
  symbolSets: ['15'],
  iconParts: groundIconParts,
  icons: landequipmentIcons,
);

/// Symbol set 20, land installation.
const landinstallation = SymbolSetModule(
  name: 'landinstallation',
  symbolSets: ['20'],
  iconParts: groundIconParts,
  icons: landinstallationIcons,
);

/// Symbol set 40, activities/events (milsymbol spells the file `activites`).
const activites = SymbolSetModule(
  name: 'activites',
  symbolSets: ['40'],
  iconParts: groundIconParts,
  icons: activitesIcons,
);

/// Symbol set 27, dismounted individual.
const dismountedindividual = SymbolSetModule(
  name: 'dismountedindividual',
  symbolSets: ['27'],
  iconParts: groundIconParts,
  icons: dismountedindividualIcons,
);

/// Symbol set 01, air.
const air = SymbolSetModule(
  name: 'air',
  symbolSets: ['01'],
  iconParts: airIconParts,
  icons: airIcons,
);

/// Symbol set 02, air missile.
const airmissile = SymbolSetModule(
  name: 'airmissile',
  symbolSets: ['02'],
  iconParts: airIconParts,
  icons: airmissileIcons,
);

/// APP-6 D modules, in milsymbol's order.
const List<SymbolSetModule> app6d = [
  air,
  airmissile,
  // space,
  // spacemissile,
  landunit,
  landcivilian,
  landequipment,
  landinstallation,
  // sea,
  // subsurface,
  // minewarfare,
  activites,
  // signalsintelligence,
  dismountedindividual,
  // tacticalpoints,
];

/// MIL-STD-2525 D modules, in milsymbol's order.
const List<SymbolSetModule> std2525d = [
  air,
  airmissile,
  // space,
  // spacemissile,
  landunit,
  landcivilian,
  landequipment,
  landinstallation,
  // sea,
  // subsurface,
  // minewarfare,
  activites,
  // signalsintelligence,
  // cyberspace,
  // tacticalpoints,
];

/// MIL-STD-2525 E modules, in milsymbol's order.
const List<SymbolSetModule> std2525e = [
  common,
  air,
  airmissile,
  // space,
  // spacemissile,
  landunit,
  landcivilian,
  landequipment,
  landinstallation,
  // sea,
  // subsurface,
  // minewarfare,
  activites,
  // signalsintelligence,
  dismountedindividual,
  // cyberspace,
  // tacticalpoints,
];

/// Registers the number SIDC modules like milsymbol's `index.js` does
/// (without the letter SIDC modules): APP-6 D, 2525 D, then 2525 E.
void registerDefaultModules(Ms ms) {
  ms
    ..addIcons(app6d)
    ..addIcons(std2525d)
    ..addIcons(std2525e);
}
