/// Translation between APP-6D / MIL-STD-2525D 20-digit number SIDCs and
/// Cursor-on-Target atom types (`a-{affiliation}-{dimension}-{function…}`),
/// whose function part is the MIL-STD-2525B/C function id that ATAK uses.
///
/// ## SIDC → CoT
///
/// * affiliation from the standard identity (digit 4): 0 pending → `p`,
///   1 unknown → `u`, 2 assumed friend → `a`, 3 friend → `f`, 4 neutral → `n`,
///   5 suspect / joker → `s`, 6 hostile / faker → `h`. Exercise and
///   simulation contexts (digit 3) map to the same letters, which is what
///   ATAK draws; the exact SIDC travels separately in the event's
///   `__horyzontal` detail.
/// * function from [cotTable]: the exact symbol set + entity + modifiers,
///   then the entity without modifiers, then the entity type, then the
///   entity. An HQ (digit 8 = 2, 3, 6, 7) without a table match becomes
///   `G-U-H`.
/// * otherwise the dimension of the symbol set: 01/02 air → `A`, 05/06
///   space → `P`, 10 land unit → `G-U`, 15 land equipment → `G-E`,
///   20 installation → `G-I`, 11 civilian, 25 control measures, 40
///   activities and the rest → `G`, 30 sea surface → `S`, 35/36 subsurface
///   → `U`.
///
/// ## CoT → SIDC
///
/// The longest prefix of the function path found in [cotTable] gives symbol
/// set, entity and modifiers; else the dimension gives the symbol set with
/// entity 000000. `j` (joker) and `k` (faker) become exercise suspect /
/// hostile; `o`, `x` and anything else unknown. Status, echelon and the
/// rest of the SIDC are not in a CoT type and come back as zeros.
///
/// ## The table
///
/// 128 pairs taken from the JMSML 2525C→2525D legacy mapping
/// (github.com/Esri/joint-military-symbology-xml,
/// samples/legacy_support/LegacyMappingTableCtoD.csv): every common land
/// unit (infantry, mechanised and motorised infantry, armour, anti-tank,
/// reconnaissance, field and rocket artillery, mortars, air defence,
/// engineers, EOD, CBRN, military police, signal, EW, UAS, aviation,
/// sustainment, SOF), land equipment (rifles to MLRS, tanks, APC/IFV,
/// trucks, mines, IEDs, sensors) and the top level of air, sea and
/// installations. Each row is `(cot function path, symbol set + entity +
/// modifier 1 + modifier 2)`; both directions are one-to-one.
library;

const cotTable = <(String, String)>[
  ('G-U-C', '101209000000'), // Combat
  ('G-U-C-I', '101211000000'), // Infantry
  ('G-U-C-I-Z', '101211020000'), // Infantry : Armored/Mechanized/Tracked
  ('G-U-C-I-M', '101211040000'), // Infantry : Motorized
  ('G-U-C-I-I', '101211050000'), // Infantry : Infantry Fighting Vehicle
  ('G-U-C-I-A', '101211000001'), // Infantry
  ('G-U-C-I-S', '101211000100'), // Infantry
  ('G-U-C-A', '101205000000'), // Armour
  ('G-U-C-A-W', '101205000051'), // Armour
  ('G-U-C-A-A', '101204000000'), // Antitank/Antiarmor
  ('G-U-C-A-A-A', '101204010000'), // Antitank/Antiarmor : Armored
  ('G-U-C-A-A-O', '101204020000'), // Antitank/Antiarmor : Motorized
  ('G-U-C-R', '101213000000'), // Reconnaissance/Cavalry/Scout
  ('G-U-C-R-V-A', '101205010000'), // Armour : Reconnaissance/Cavalry/Scout
  ('G-U-C-R-V-M', '101213030000'), // Reconnaissance/Cavalry/Scout : Motorized
  ('G-U-C-R-A', '101213000001'), // Reconnaissance/Cavalry/Scout
  ('G-U-C-F', '101303000000'), // Fires : Field Artillery
  ('G-U-C-F-H-E', '101303010000'), // Fires : Field Artillery : Self-propelled
  ('G-U-C-F-R-M', '101303004100'), // Fires : Field Artillery
  ('G-U-C-F-R-M-S', '101303014100'), // Fires : Field Artillery : Self-propelled
  ('G-U-C-F-R-S', '101303005900'), // Fires : Field Artillery
  ('G-U-C-F-M', '101308000000'), // Fires : Mortar
  ('G-U-C-F-M-S', '101308010000'), // Fires : Mortar : Armored/Mechanized/Tracked
  ('G-U-C-F-M-W', '101308020000'), // Fires : Mortar : Self-Propelled Wheeled
  ('G-U-C-F-M-T', '101308030000'), // Fires : Mortar : Towed
  ('G-U-C-F-T-C', '101304000000'), // Fires : Field Artillery Observer
  ('G-U-C-F-T-C-M', '101303020000'), // Fires : Field Artillery : Target Acquisition
  ('G-U-C-M', '101307000000'), // Fires : Missile
  ('G-U-C-D', '101301000000'), // Fires : Air Defense
  ('G-U-C-D-G', '101301010000'), // Fires : Air Defense : Main Gun System
  ('G-U-C-D-M', '101301020000'), // Fires : Air Defense : Missile
  ('G-U-C-E', '101407000000'), // Protection : Engineer
  ('G-U-C-E-C-T', '101407010000'), // Protection : Engineer : Mechanized
  ('G-U-C-E-C-W', '101407020000'), // Protection : Engineer : Motorized
  ('G-U-C-E-C-R', '101407030000'), // Protection : Engineer : Reconnaissance
  ('G-U-U-E', '101408000000'), // Protection : Explosive Ordnance Disposal (EOD)
  ('G-U-U-A', '101401000000'), // Protection : CBRN Defense
  ('G-U-U-L-M', '101412000000'), // Protection : Military Police
  ('G-U-C-S', '101417000000'), // Protection : Security
  ('G-U-U-S', '101110000000'), // Command and Control : Signal
  ('G-U-U-S-R', '101110010000'), // Command and Control : Signal : Radio
  ('G-U-U-S-R-W', '101110020000'), // Command and Control : Signal : Radio Relay
  ('G-U-U-M', '101510000000'), // Intelligence : Military Intelligence
  ('G-U-U-M-S-E', '101505000000'), // Intelligence : Electronic Warfare
  ('G-U-U-M-S-E-J', '101505040000'), // Intelligence : Electronic Warfare : Jamming
  ('G-U-U-M-S-E-I', '101505030000'), // Intelligence : Electronic Warfare : Intercept
  ('G-U-C-V-U', '101219000000'), // Unmanned Aerial Systems
  ('G-U-C-V', '101206000000'), // Army Aviation/Aviation Rotary Wing
  ('G-U-C-V-F', '101208000000'), // Aviation Fixed Wing
  ('G-U-S', '101606000000'), // Sustainment : Combat Service Support
  ('G-U-S-M', '101613000000'), // Sustainment : Medical
  ('G-U-S-M-M', '101614000000'), // Sustainment : Medical Treatment Facility
  ('G-U-S-S', '101634000000'), // Sustainment : Supply
  ('G-U-S-T', '101636000000'), // Sustainment : Transportation
  ('G-U-S-X', '101611000000'), // Sustainment : Maintenance
  ('G-U-S-S-3', '101639000000'), // Sustainment : US Supply Class III
  ('G-U-S-S-5', '101641000000'), // Sustainment : US Supply Class V
  ('F', '101218000000'), // SOF
  ('F-G', '101218020000'), // SOF : Ground
  ('F-G-S', '101217000000'), // Special Forces
  ('G-E-W-R', '151101000000'), // Rifle
  ('G-E-W-Z', '151103000000'), // Grenade Launcher
  ('G-E-W-A', '151105000000'), // Air Defense Gun
  ('G-E-W-G', '151106000000'), // Antitank Gun
  ('G-E-W-H', '151109000000'), // Howitzer
  ('G-E-W-H-L', '151109010000'), // Howitzer : Light
  ('G-E-W-H-M', '151109020000'), // Howitzer : Medium
  ('G-E-W-H-H', '151109030000'), // Howitzer : Heavy
  ('G-E-W-M', '151110000000'), // Missile Launcher
  ('G-E-W-M-A', '151111000000'), // ADML
  ('G-E-W-M-A-S', '151111010000'), // ADML : Light
  ('G-E-W-M-T', '151112000000'), // Antitank Missile Launcher
  ('G-E-W-M-S', '151113000000'), // Surface-to-Surface Missile Launcher
  ('G-E-W-O', '151114000000'), // Mortar
  ('G-E-W-O-L', '151114010000'), // Mortar : Light
  ('G-E-W-O-M', '151114020000'), // Mortar : Medium
  ('G-E-W-O-H', '151114030000'), // Mortar : Heavy
  ('G-E-W-S', '151115000000'), // Single Rocket Launcher
  ('G-E-W-X', '151116000000'), // Multiple Rocket Launcher
  ('G-E-W-X-L', '151116010000'), // Multiple Rocket Launcher : Light
  ('G-E-W-X-M', '151116020000'), // Multiple Rocket Launcher : Medium
  ('G-E-W-X-H', '151116030000'), // Multiple Rocket Launcher : Heavy
  ('G-E-W-T', '151117000000'), // Antitank Rocket Launcher
  ('G-E-V', '151200000000'), // Vehicle
  ('G-E-V-A', '151201000000'), // Vehicle : Armored Vehicle
  ('G-E-V-A-I', '151201010000'), // Vehicle : Armored Vehicle : Armored Fighting Vehicle
  ('G-E-V-A-C', '151201020000'), // Vehicle : Armored Vehicle : Armored Fighting Vehicle C2
  ('G-E-V-A-A', '151201030000'), // Vehicle : Armored Vehicle : Armored Personnel Carrier
  (
    'G-E-V-U-A-A',
    '151201040000',
  ), // Vehicle : Armored Vehicle : Armored Personnel Carrier Ambulance
  ('G-E-V-A-L', '151201100000'), // Vehicle : Armored Vehicle : Light Wheeled Armored Vehicle
  ('G-E-V-A-T', '151202000000'), // Vehicle : Tank
  ('G-E-V-A-T-L', '151202010000'), // Vehicle : Tank : Light
  ('G-E-V-A-T-M', '151202020000'), // Vehicle : Tank : Medium
  ('G-E-V-A-T-H', '151202030000'), // Vehicle : Tank : Heavy
  ('G-E-V-E', '151300000000'), // Engineer Equipment
  ('G-E-V-E-B', '151301000000'), // Engineer Equipment : Bridge
  ('G-E-V-E-A', '151309000000'), // Engineer Equipment : Mine Clearing Equipment
  ('G-E-V-E-M', '151310000000'), // Engineer Equipment : Mine Laying Equipment
  ('G-E-V-U', '151401000000'), // Utility Vehicles : Utility Vehicle
  ('G-E-V-U-A', '151403000000'), // Utility Vehicles : Medical Evacuation
  ('G-E-V-U-S', '151406000000'), // Utility Vehicles : Semi-Trailer and Truck
  ('G-E-V-U-X', '151408000000'), // Utility Vehicles : Cross Country Truck
  ('G-E-V-C-A', '151601000000'), // Civilian Vehicle : Automobile
  ('G-E-V-C-J', '151605000000'), // Civilian Vehicle : Jeep Type Vehicle
  ('G-E-X-M', '152101000000'), // Land Mines : Land Mine
  ('G-E-X-M-C', '152102000000'), // Land Mines : Antipersonnel Land Mine (APL)
  ('G-E-X-I', '152104000000'), // Land Mines : Improvised Explosives Device (IED)
  ('G-E-S', '152201000000'), // Sensors : Sensor
  ('G-E-S-R', '152203000000'), // Sensors : Radar
  ('G-E-X-L', '152010000000'), // Other Equipment : Laser
  ('G-E-X-N', '152004000000'), // Other Equipment : CBRN Equipment
  ('G-I-X', '201207010000'), // Infrastructure : Medical : Medical
  ('G-I-B', '201208020000'), // Infrastructure : Military : Military Base
  ('G-I-T', '201213000000'), // Infrastructure : Transportation
  ('A-M', '011100000000'), // Military (Air)
  ('A-M-F', '011101000000'), // Military (Air) : Fixed-Wing
  ('A-M-H', '011102000000'), // Military (Air) : Rotary-Wing
  ('A-M-F-Q', '011103000000'), // Military (Air) : Unmanned Aircraft
  ('A-C', '011200000000'), // Civilian (Air)
  ('A-C-F', '011201000000'), // Civilian (Air) : Fixed Wing
  ('A-C-H', '011202000000'), // Civilian (Air) : Rotary Wing
  ('A-W', '011300000000'), // Weapon (Air)
  ('S-C', '301200000000'), // Military Combatant
  ('S-C-L', '301202000000'), // Military Combatant : Surface Combatant- Line
  ('S-N', '301300000000'), // Military Noncombatant
  ('S-X-M', '301401000000'), // Civilian (Sea Surface) : Merchant Ship
  ('U-S', '351101000000'), // Military (Sea Subsurface) : Submarine
  ('U-W', '351300000000'), // Weapon (Sea Subsurface)
];

final Map<String, String> _byPath = {for (final (p, s) in cotTable) p: s};
final Map<String, String> _bySidc = {for (final (p, s) in cotTable) s: p};

const _affiliationOf = {'0': 'p', '1': 'u', '2': 'a', '3': 'f', '4': 'n', '5': 's', '6': 'h'};

/// Whether [sidc] is a 20-digit number SIDC (or a 30-digit 2525E one, of
/// which the first 20 digits are read).
bool isNumberSidc(String? sidc) => sidc != null && RegExp(r'^(\d{20}|\d{30})$').hasMatch(sidc);

/// The CoT type for [sidc]; `a-u-G` for anything that is not a number SIDC.
String sidcToCotType(String? sidc) {
  if (!isNumberSidc(sidc)) return 'a-u-G';
  final s = sidc!;
  final affiliation = _affiliationOf[s[3]] ?? 'u';
  final set = s.substring(4, 6), entity = s.substring(10, 16), mods = s.substring(16, 20);
  for (final key in [
    '$set$entity$mods',
    '$set${entity}0000',
    '$set${entity.substring(0, 4)}000000',
    '$set${entity.substring(0, 2)}00000000',
  ]) {
    final path = _bySidc[key];
    if (path != null && !key.endsWith('0000000000')) return 'a-$affiliation-$path';
  }
  if (set == '10' && const {'2', '3', '6', '7'}.contains(s[7])) return 'a-$affiliation-G-U-H';
  final dimension = switch (set) {
    '01' || '02' => 'A',
    '05' || '06' => 'P',
    '10' => 'G-U',
    '15' => 'G-E',
    '20' => 'G-I',
    '30' => 'S',
    '35' || '36' => 'U',
    _ => 'G',
  };
  return 'a-$affiliation-$dimension';
}

/// The SIDC for a CoT atom type, or null when [type] is not an atom
/// (`a-…`). Unknown functions keep the affiliation and dimension.
String? cotTypeToSidc(String? type) {
  if (type == null) return null;
  final parts = type.trim().split('-');
  if (parts.length < 3 || parts[0] != 'a' || parts[1].isEmpty || parts[2].isEmpty) return null;
  final (context, identity) = switch (parts[1].toLowerCase()) {
    'p' => ('0', '0'),
    'u' => ('0', '1'),
    'a' => ('0', '2'),
    'f' => ('0', '3'),
    'n' => ('0', '4'),
    's' => ('0', '5'),
    'h' => ('0', '6'),
    'j' => ('1', '5'),
    'k' => ('1', '6'),
    _ => ('0', '1'),
  };
  final path = [for (final p in parts.skip(2)) p.toUpperCase()];
  var hq = '0';
  String? code;
  for (var n = path.length; n > 0 && code == null; n--) {
    code = _byPath[path.take(n).join('-')];
  }
  if (code == null && path.length >= 3 && path[0] == 'G' && path[1] == 'U' && path[2] == 'H') {
    hq = '2';
    code = '10${'0' * 10}';
  }
  code ??= switch (path[0]) {
    'A' => '01',
    'P' => '05',
    'S' => '30',
    'U' => '35',
    'G' when path.length > 1 && path[1] == 'E' => '15',
    'G' when path.length > 1 && path[1] == 'I' => '20',
    _ => '10',
  }.padRight(12, '0');
  final set = code.substring(0, 2), rest = code.substring(2);
  return '10$context$identity${set}0${hq}00${rest.substring(0, 6)}${rest.substring(6)}';
}
