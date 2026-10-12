// Ported from milsymbol src/numbersidc/metadata.js, MIT (c) Måns Beckman.

import '../js.dart';
import '../metadata.dart';
import '../ms.dart';
import '../symbol.dart';

const _affiliationMapping = {
  '0': 'Unknown',
  '1': 'Unknown',
  '2': 'Friend',
  '3': 'Friend',
  '4': 'Neutral',
  '5': 'Hostile',
  '6': 'Hostile',
};

const _dimensionMapping = {
  '00': 'Sea',
  '01': 'Air',
  '02': 'Air',
  '05': 'Air',
  '06': 'Air',
  '10': 'Ground',
  '11': 'Ground',
  '12': 'Ground',
  '15': 'Ground',
  '20': 'Ground',
  '30': 'Sea',
  '35': 'Subsurface',
  '36': 'Subsurface',
  '39': 'Subsurface',
  '40': 'Ground',
  '50': 'Air',
  '51': 'Air',
  '52': 'Ground',
  '53': 'Sea',
  '54': 'Subsurface',
  '60': 'Ground',
};

/// Metadata of a number based (20/30 digit) SIDC.
SymbolMetadata numberMetadata(
  MilSymbol symbol,
  Ms ms,
  SymbolMetadata metadata,
  MetadataMapping mapping,
) {
  final sidc = symbol.sidc;
  final version = substr(sidc, 0, 2);
  final standardIdentity1 = substr(sidc, 2, 1);
  final standardIdentity2 = substr(sidc, 3, 1);
  final symbolSet = substr(sidc, 4, 2);
  final status = substr(sidc, 6, 1);
  final headquartersTaskForceDummy = substr(sidc, 7, 1);
  final echelonMobility = substr(sidc, 8, 2);
  final frameshape = _or(substr(sidc, 22, 1), '0');

  if (version == '10' || version == '11' || version == '12') {
    metadata.edition = 'D';
  }
  if (version == '13' || version == '14') {
    metadata.edition = 'E';
  }

  if (looseEquals(version, 13) && looseEquals(standardIdentity2, 5)) {
    metadata.suspect = true;
  }

  final functionid = metadata.functionid = substr(sidc, 10, 10);
  metadata.modifier1 = _or(substr(sidc, 20, 1), '0') + _or(substr(functionid, 6, 2), '00');
  metadata.modifier2 = _or(substr(sidc, 21, 1), '0') + _or(substr(functionid, 8, 2), '00');

  final ctx = parseInt(substr(sidc, 2, 1));
  metadata.context = ctx is int && ctx >= 0 && ctx < mapping.context.length
      ? mapping.context[ctx]
      : null;
  metadata.affiliation = _affiliationMapping[standardIdentity2];
  metadata.dimension = _dimensionMapping[symbolSet] ?? '';

  // Not equipment symbolsets
  if (symbolSet == '10' ||
      symbolSet == '11' ||
      symbolSet == '25' ||
      symbolSet == '27' ||
      symbolSet == '40') {
    metadata.unit = true;
  }

  //SymbolSets in Space
  if (symbolSet == '05' || symbolSet == '06' || symbolSet == '50') metadata.space = true;
  //SymbolSets that are Activities
  if (symbolSet == '40') metadata.activity = true;
  //SymbolSets that are landequipment
  if (symbolSet == '15') metadata.landequipment = true;
  //SymbolSets that are Installations
  if (symbolSet == '20') metadata.installation = true;
  //SymbolSets that are control-measure
  if (symbolSet == '25') metadata.controlMeasure = true;
  //SymbolSets in Cyberpace
  if (symbolSet == '60') metadata.cyberspace = true;
  //Sea Mines with MEDAL icn
  if (symbolSet == '36' && symbol.options.alternateMedal == false) metadata.fill = false;
  //Sea own track
  if (symbolSet == '30' && looseEquals(substr(functionid, 0, 6), 150000)) {
    metadata.frame = false;
  }

  //Planned/Anticipated/Suspect symbols should have a dashed outline
  if (status == '1') metadata.notpresent = ms.dashArrays.anticipated;
  if (standardIdentity2 == '0' || standardIdentity2 == '2' || standardIdentity2 == '5') {
    metadata.notpresent = ms.dashArrays.pending;
  }

  //All ETC/POSCON tracks shall have a pending standard identity frame.
  //All fused tracks shall have a pending standard identity frame.
  if (symbolSet == '30' && looseEquals(substr(functionid, 0, 6), 160000)) {
    metadata.notpresent = ms.dashArrays.pending;
  }
  if (symbolSet == '35' && looseEquals(substr(functionid, 0, 6), 140000)) {
    metadata.notpresent = ms.dashArrays.pending;
  }
  if (symbolSet == '35' && looseEquals(substr(functionid, 0, 6), 150000)) {
    metadata.notpresent = ms.dashArrays.pending;
  }

  //Should it have a Condition Bar
  if (status == '2' || status == '3' || status == '4' || status == '5') {
    metadata.condition = mapping.status[int.parse(status)];
  }

  //First save the dimensionType and affiliationType before we modifies it...
  metadata.baseDimension = metadata.dimension;
  metadata.baseAffilation = metadata.affiliation;

  //Joker and faker should have the shape of friendly
  if (standardIdentity2 == '5' && standardIdentity1 == '1') metadata.joker = true;
  if (standardIdentity2 == '6' && standardIdentity1 == '1') metadata.faker = true;
  if (metadata.joker || metadata.faker) {
    metadata.affiliation = mapping.affiliation[1];
  }

  if (symbolSet == '00') metadata.dimensionUnknown = true;

  //If battle dimension is unknown, standard identity is Exersize and other than Unknown we should not have a symbol
  if (symbolSet == '00' && standardIdentity1 == '1' && metadata.affiliation != 'Unknown') {
    metadata.affiliation = '';
  }

  //Land Dismounted Individual should have special icons
  if (symbolSet == '27') {
    metadata.dimension = 'LandDismountedIndividual';
    metadata.dismounted = true;
  }

  //Ground Equipment should have the same geometry as sea Friend...
  //Signal INTELLIGENCE Ground should have the same geometry as sea Friend...
  if (symbolSet == '15' || symbolSet == '52') metadata.dimension = mapping.dimension[2];

  //Civilian stuff
  final f2 = substring(functionid, 0, 2);
  if ((symbolSet == '01' && f2 == '12') ||
      (symbolSet == '05' && f2 == '12') ||
      symbolSet == '11' ||
      (symbolSet == '12' && f2 == '12') ||
      (symbolSet == '15' && f2 == '16') ||
      (symbolSet == '30' && f2 == '14') ||
      (symbolSet == '35' && f2 == '12')) {
    metadata.civilian = true;
  }

  // Frame shape overrides 2525E
  if (frameshape != '0' && metadata.edition == 'E') {
    metadata.civilian = false;
    metadata.cyberspace = false;
    metadata.installation = false;
    metadata.landequipment = false;
    metadata.activity = false;
    metadata.space = false;
    metadata.unit = false;
    metadata.cyberspace = false;
    switch (frameshape) {
      case '1': // Space
        metadata.dimension = 'Air';
        metadata.space = true;
      case '2': // Air
        metadata.dimension = 'Air';
      case '3': // Land Unit
        metadata.dimension = 'Ground';
        metadata.unit = true;
      case '4': // Land Equipment/Sea Surface
        metadata.dimension = 'Sea';
        metadata.landequipment = true;
      case '5': // Land Installation
        metadata.dimension = 'Ground';
        metadata.installation = true;
      case '6': // Dismounted Individuals
        metadata.dimension = 'LandDismountedIndividual';
        metadata.dismounted = true;
      case '7': // Sea Subsurface
        metadata.dimension = 'Subsurface';
      case '8': // Activity/Event
        metadata.dimension = 'Ground';
        metadata.activity = true;
        metadata.unit = true;
      case '9': // Cyberspace
        metadata.dimension = 'Ground';
        metadata.cyberspace = false;
        metadata.unit = true;
    }
  }
  if (frameshape == 'A') metadata.frame = false;

  //Setting up Headquarters/task force/dummy
  if (['1', '3', '5', '7'].contains(headquartersTaskForceDummy)) metadata.feintDummy = true;
  if (['2', '3', '6', '7'].contains(headquartersTaskForceDummy)) metadata.headquarters = true;
  if (['4', '5', '6', '7'].contains(headquartersTaskForceDummy)) metadata.taskForce = true;

  //Setting up Echelon/Mobility/Towed Array Amplifier
  if (le(echelonMobility, 30)) {
    metadata.echelon = mapping.echelonMobility[echelonMobility];
  }
  if (ge(echelonMobility, 30) && lt(echelonMobility, 70)) {
    metadata.mobility = mapping.echelonMobility[echelonMobility];
  }
  if (ge(echelonMobility, 70) && lt(echelonMobility, 80)) {
    metadata.leadership = mapping.echelonMobility[echelonMobility];
  }

  return metadata;
}

String _or(String a, String b) => a.isEmpty ? b : a;
