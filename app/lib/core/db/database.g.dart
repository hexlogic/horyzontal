// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  const SettingsEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? key, String? value}) =>
      SettingsEntry(key: key ?? this.key, value: value ?? this.value);
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LayersTable extends Layers with TableInfo<$LayersTable, LayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF1565C0),
  );
  static const VerificationMeta _visibleMeta = const VerificationMeta(
    'visible',
  );
  @override
  late final GeneratedColumn<bool> visible = GeneratedColumn<bool>(
    'visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    visible,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'layers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('visible')) {
      context.handle(
        _visibleMeta,
        visible.isAcceptableOrUnknown(data['visible']!, _visibleMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LayerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      visible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}visible'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LayersTable createAlias(String alias) {
    return $LayersTable(attachedDatabase, alias);
  }
}

class LayerRow extends DataClass implements Insertable<LayerRow> {
  final String id;
  final String name;
  final int color;
  final bool visible;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LayerRow({
    required this.id,
    required this.name,
    required this.color,
    required this.visible,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['visible'] = Variable<bool>(visible);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LayersCompanion toCompanion(bool nullToAbsent) {
    return LayersCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      visible: Value(visible),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LayerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      visible: serializer.fromJson<bool>(json['visible']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'visible': serializer.toJson<bool>(visible),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LayerRow copyWith({
    String? id,
    String? name,
    int? color,
    bool? visible,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LayerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    visible: visible ?? this.visible,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LayerRow copyWithCompanion(LayersCompanion data) {
    return LayerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      visible: data.visible.present ? data.visible.value : this.visible,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LayerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('visible: $visible, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, visible, archived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.visible == this.visible &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LayersCompanion extends UpdateCompanion<LayerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<bool> visible;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.visible = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LayersCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.visible = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LayerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<bool>? visible,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (visible != null) 'visible': visible,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LayersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? color,
    Value<bool>? visible,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      visible: visible ?? this.visible,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (visible.present) {
      map['visible'] = Variable<bool>(visible.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('visible: $visible, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeaturesTable extends Features
    with TableInfo<$FeaturesTable, FeatureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeaturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layerIdMeta = const VerificationMeta(
    'layerId',
  );
  @override
  late final GeneratedColumn<String> layerId = GeneratedColumn<String>(
    'layer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES layers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sidcMeta = const VerificationMeta('sidc');
  @override
  late final GeneratedColumn<String> sidc = GeneratedColumn<String>(
    'sidc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _radiusMeta = const VerificationMeta('radius');
  @override
  late final GeneratedColumn<double> radius = GeneratedColumn<double>(
    'radius',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geometryMeta = const VerificationMeta(
    'geometry',
  );
  @override
  late final GeneratedColumn<String> geometry = GeneratedColumn<String>(
    'geometry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    layerId,
    kind,
    name,
    description,
    author,
    sidc,
    color,
    radius,
    geometry,
    extra,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'features';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeatureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('layer_id')) {
      context.handle(
        _layerIdMeta,
        layerId.isAcceptableOrUnknown(data['layer_id']!, _layerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_layerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('sidc')) {
      context.handle(
        _sidcMeta,
        sidc.isAcceptableOrUnknown(data['sidc']!, _sidcMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('radius')) {
      context.handle(
        _radiusMeta,
        radius.isAcceptableOrUnknown(data['radius']!, _radiusMeta),
      );
    }
    if (data.containsKey('geometry')) {
      context.handle(
        _geometryMeta,
        geometry.isAcceptableOrUnknown(data['geometry']!, _geometryMeta),
      );
    } else if (isInserting) {
      context.missing(_geometryMeta);
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeatureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeatureRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      layerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      sidc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sidc'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      radius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius'],
      ),
      geometry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geometry'],
      )!,
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FeaturesTable createAlias(String alias) {
    return $FeaturesTable(attachedDatabase, alias);
  }
}

class FeatureRow extends DataClass implements Insertable<FeatureRow> {
  final String id;
  final String layerId;
  final String kind;
  final String name;
  final String description;

  /// Callsign of whoever created the object.
  final String author;

  /// APP-6 symbol code (number SIDC) of a point.
  final String? sidc;
  final int? color;

  /// Radius shown around a point, metres.
  final double? radius;
  final String geometry;

  /// JSON with fields kept from imports (CoT uid, KML style...).
  final String? extra;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FeatureRow({
    required this.id,
    required this.layerId,
    required this.kind,
    required this.name,
    required this.description,
    required this.author,
    this.sidc,
    this.color,
    this.radius,
    required this.geometry,
    this.extra,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['layer_id'] = Variable<String>(layerId);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || sidc != null) {
      map['sidc'] = Variable<String>(sidc);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || radius != null) {
      map['radius'] = Variable<double>(radius);
    }
    map['geometry'] = Variable<String>(geometry);
    if (!nullToAbsent || extra != null) {
      map['extra'] = Variable<String>(extra);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FeaturesCompanion toCompanion(bool nullToAbsent) {
    return FeaturesCompanion(
      id: Value(id),
      layerId: Value(layerId),
      kind: Value(kind),
      name: Value(name),
      description: Value(description),
      author: Value(author),
      sidc: sidc == null && nullToAbsent ? const Value.absent() : Value(sidc),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      radius: radius == null && nullToAbsent
          ? const Value.absent()
          : Value(radius),
      geometry: Value(geometry),
      extra: extra == null && nullToAbsent
          ? const Value.absent()
          : Value(extra),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FeatureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeatureRow(
      id: serializer.fromJson<String>(json['id']),
      layerId: serializer.fromJson<String>(json['layerId']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      author: serializer.fromJson<String>(json['author']),
      sidc: serializer.fromJson<String?>(json['sidc']),
      color: serializer.fromJson<int?>(json['color']),
      radius: serializer.fromJson<double?>(json['radius']),
      geometry: serializer.fromJson<String>(json['geometry']),
      extra: serializer.fromJson<String?>(json['extra']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'layerId': serializer.toJson<String>(layerId),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'author': serializer.toJson<String>(author),
      'sidc': serializer.toJson<String?>(sidc),
      'color': serializer.toJson<int?>(color),
      'radius': serializer.toJson<double?>(radius),
      'geometry': serializer.toJson<String>(geometry),
      'extra': serializer.toJson<String?>(extra),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FeatureRow copyWith({
    String? id,
    String? layerId,
    String? kind,
    String? name,
    String? description,
    String? author,
    Value<String?> sidc = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<double?> radius = const Value.absent(),
    String? geometry,
    Value<String?> extra = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FeatureRow(
    id: id ?? this.id,
    layerId: layerId ?? this.layerId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    description: description ?? this.description,
    author: author ?? this.author,
    sidc: sidc.present ? sidc.value : this.sidc,
    color: color.present ? color.value : this.color,
    radius: radius.present ? radius.value : this.radius,
    geometry: geometry ?? this.geometry,
    extra: extra.present ? extra.value : this.extra,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FeatureRow copyWithCompanion(FeaturesCompanion data) {
    return FeatureRow(
      id: data.id.present ? data.id.value : this.id,
      layerId: data.layerId.present ? data.layerId.value : this.layerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      author: data.author.present ? data.author.value : this.author,
      sidc: data.sidc.present ? data.sidc.value : this.sidc,
      color: data.color.present ? data.color.value : this.color,
      radius: data.radius.present ? data.radius.value : this.radius,
      geometry: data.geometry.present ? data.geometry.value : this.geometry,
      extra: data.extra.present ? data.extra.value : this.extra,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeatureRow(')
          ..write('id: $id, ')
          ..write('layerId: $layerId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('author: $author, ')
          ..write('sidc: $sidc, ')
          ..write('color: $color, ')
          ..write('radius: $radius, ')
          ..write('geometry: $geometry, ')
          ..write('extra: $extra, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    layerId,
    kind,
    name,
    description,
    author,
    sidc,
    color,
    radius,
    geometry,
    extra,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeatureRow &&
          other.id == this.id &&
          other.layerId == this.layerId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.description == this.description &&
          other.author == this.author &&
          other.sidc == this.sidc &&
          other.color == this.color &&
          other.radius == this.radius &&
          other.geometry == this.geometry &&
          other.extra == this.extra &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FeaturesCompanion extends UpdateCompanion<FeatureRow> {
  final Value<String> id;
  final Value<String> layerId;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> description;
  final Value<String> author;
  final Value<String?> sidc;
  final Value<int?> color;
  final Value<double?> radius;
  final Value<String> geometry;
  final Value<String?> extra;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FeaturesCompanion({
    this.id = const Value.absent(),
    this.layerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
    this.sidc = const Value.absent(),
    this.color = const Value.absent(),
    this.radius = const Value.absent(),
    this.geometry = const Value.absent(),
    this.extra = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeaturesCompanion.insert({
    required String id,
    required String layerId,
    required String kind,
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
    this.sidc = const Value.absent(),
    this.color = const Value.absent(),
    this.radius = const Value.absent(),
    required String geometry,
    this.extra = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       layerId = Value(layerId),
       kind = Value(kind),
       geometry = Value(geometry),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FeatureRow> custom({
    Expression<String>? id,
    Expression<String>? layerId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? author,
    Expression<String>? sidc,
    Expression<int>? color,
    Expression<double>? radius,
    Expression<String>? geometry,
    Expression<String>? extra,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (layerId != null) 'layer_id': layerId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
      if (sidc != null) 'sidc': sidc,
      if (color != null) 'color': color,
      if (radius != null) 'radius': radius,
      if (geometry != null) 'geometry': geometry,
      if (extra != null) 'extra': extra,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeaturesCompanion copyWith({
    Value<String>? id,
    Value<String>? layerId,
    Value<String>? kind,
    Value<String>? name,
    Value<String>? description,
    Value<String>? author,
    Value<String?>? sidc,
    Value<int?>? color,
    Value<double?>? radius,
    Value<String>? geometry,
    Value<String?>? extra,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FeaturesCompanion(
      id: id ?? this.id,
      layerId: layerId ?? this.layerId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      sidc: sidc ?? this.sidc,
      color: color ?? this.color,
      radius: radius ?? this.radius,
      geometry: geometry ?? this.geometry,
      extra: extra ?? this.extra,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (layerId.present) {
      map['layer_id'] = Variable<String>(layerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (sidc.present) {
      map['sidc'] = Variable<String>(sidc.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (radius.present) {
      map['radius'] = Variable<double>(radius.value);
    }
    if (geometry.present) {
      map['geometry'] = Variable<String>(geometry.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeaturesCompanion(')
          ..write('id: $id, ')
          ..write('layerId: $layerId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('author: $author, ')
          ..write('sidc: $sidc, ')
          ..write('color: $color, ')
          ..write('radius: $radius, ')
          ..write('geometry: $geometry, ')
          ..write('extra: $extra, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TileSourcesTable extends TileSources
    with TableInfo<$TileSourcesTable, TileSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TileSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemeMeta = const VerificationMeta('scheme');
  @override
  late final GeneratedColumn<String> scheme = GeneratedColumn<String>(
    'scheme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('xyz'),
  );
  static const VerificationMeta _subdomainsMeta = const VerificationMeta(
    'subdomains',
  );
  @override
  late final GeneratedColumn<String> subdomains = GeneratedColumn<String>(
    'subdomains',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fileMeta = const VerificationMeta('file');
  @override
  late final GeneratedColumn<String> file = GeneratedColumn<String>(
    'file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minZoomMeta = const VerificationMeta(
    'minZoom',
  );
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
    'min_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxZoomMeta = const VerificationMeta(
    'maxZoom',
  );
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
    'max_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(19),
  );
  static const VerificationMeta _tileSizeMeta = const VerificationMeta(
    'tileSize',
  );
  @override
  late final GeneratedColumn<int> tileSize = GeneratedColumn<int>(
    'tile_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(256),
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _opacityMeta = const VerificationMeta(
    'opacity',
  );
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
    'opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    url,
    scheme,
    subdomains,
    file,
    minZoom,
    maxZoom,
    tileSize,
    attribution,
    enabled,
    opacity,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tile_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<TileSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('scheme')) {
      context.handle(
        _schemeMeta,
        scheme.isAcceptableOrUnknown(data['scheme']!, _schemeMeta),
      );
    }
    if (data.containsKey('subdomains')) {
      context.handle(
        _subdomainsMeta,
        subdomains.isAcceptableOrUnknown(data['subdomains']!, _subdomainsMeta),
      );
    }
    if (data.containsKey('file')) {
      context.handle(
        _fileMeta,
        file.isAcceptableOrUnknown(data['file']!, _fileMeta),
      );
    }
    if (data.containsKey('min_zoom')) {
      context.handle(
        _minZoomMeta,
        minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta),
      );
    }
    if (data.containsKey('max_zoom')) {
      context.handle(
        _maxZoomMeta,
        maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta),
      );
    }
    if (data.containsKey('tile_size')) {
      context.handle(
        _tileSizeMeta,
        tileSize.isAcceptableOrUnknown(data['tile_size']!, _tileSizeMeta),
      );
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('opacity')) {
      context.handle(
        _opacityMeta,
        opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TileSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TileSourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      scheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheme'],
      )!,
      subdomains: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subdomains'],
      )!,
      file: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file'],
      ),
      minZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_zoom'],
      )!,
      maxZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_zoom'],
      )!,
      tileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tile_size'],
      )!,
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      opacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opacity'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TileSourcesTable createAlias(String alias) {
    return $TileSourcesTable(attachedDatabase, alias);
  }
}

class TileSourceRow extends DataClass implements Insertable<TileSourceRow> {
  final String id;
  final String name;

  /// `url` or `file`.
  final String kind;

  /// URL template with {z} {x} {y} (or {-y}), {s}, {bbox-epsg-3857}.
  final String? url;

  /// `xyz` or `tms` (rows counted from the south).
  final String scheme;

  /// Comma-separated values for {s}.
  final String subdomains;

  /// File name in Documents/sources for `file` sources.
  final String? file;
  final int minZoom;
  final int maxZoom;
  final int tileSize;
  final String attribution;
  final bool enabled;
  final double opacity;
  final DateTime createdAt;
  const TileSourceRow({
    required this.id,
    required this.name,
    required this.kind,
    this.url,
    required this.scheme,
    required this.subdomains,
    this.file,
    required this.minZoom,
    required this.maxZoom,
    required this.tileSize,
    required this.attribution,
    required this.enabled,
    required this.opacity,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['scheme'] = Variable<String>(scheme);
    map['subdomains'] = Variable<String>(subdomains);
    if (!nullToAbsent || file != null) {
      map['file'] = Variable<String>(file);
    }
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    map['tile_size'] = Variable<int>(tileSize);
    map['attribution'] = Variable<String>(attribution);
    map['enabled'] = Variable<bool>(enabled);
    map['opacity'] = Variable<double>(opacity);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TileSourcesCompanion toCompanion(bool nullToAbsent) {
    return TileSourcesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      scheme: Value(scheme),
      subdomains: Value(subdomains),
      file: file == null && nullToAbsent ? const Value.absent() : Value(file),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      tileSize: Value(tileSize),
      attribution: Value(attribution),
      enabled: Value(enabled),
      opacity: Value(opacity),
      createdAt: Value(createdAt),
    );
  }

  factory TileSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TileSourceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      url: serializer.fromJson<String?>(json['url']),
      scheme: serializer.fromJson<String>(json['scheme']),
      subdomains: serializer.fromJson<String>(json['subdomains']),
      file: serializer.fromJson<String?>(json['file']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      tileSize: serializer.fromJson<int>(json['tileSize']),
      attribution: serializer.fromJson<String>(json['attribution']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      opacity: serializer.fromJson<double>(json['opacity']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'url': serializer.toJson<String?>(url),
      'scheme': serializer.toJson<String>(scheme),
      'subdomains': serializer.toJson<String>(subdomains),
      'file': serializer.toJson<String?>(file),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'tileSize': serializer.toJson<int>(tileSize),
      'attribution': serializer.toJson<String>(attribution),
      'enabled': serializer.toJson<bool>(enabled),
      'opacity': serializer.toJson<double>(opacity),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TileSourceRow copyWith({
    String? id,
    String? name,
    String? kind,
    Value<String?> url = const Value.absent(),
    String? scheme,
    String? subdomains,
    Value<String?> file = const Value.absent(),
    int? minZoom,
    int? maxZoom,
    int? tileSize,
    String? attribution,
    bool? enabled,
    double? opacity,
    DateTime? createdAt,
  }) => TileSourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    url: url.present ? url.value : this.url,
    scheme: scheme ?? this.scheme,
    subdomains: subdomains ?? this.subdomains,
    file: file.present ? file.value : this.file,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    tileSize: tileSize ?? this.tileSize,
    attribution: attribution ?? this.attribution,
    enabled: enabled ?? this.enabled,
    opacity: opacity ?? this.opacity,
    createdAt: createdAt ?? this.createdAt,
  );
  TileSourceRow copyWithCompanion(TileSourcesCompanion data) {
    return TileSourceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      url: data.url.present ? data.url.value : this.url,
      scheme: data.scheme.present ? data.scheme.value : this.scheme,
      subdomains: data.subdomains.present
          ? data.subdomains.value
          : this.subdomains,
      file: data.file.present ? data.file.value : this.file,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      tileSize: data.tileSize.present ? data.tileSize.value : this.tileSize,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TileSourceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('url: $url, ')
          ..write('scheme: $scheme, ')
          ..write('subdomains: $subdomains, ')
          ..write('file: $file, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('tileSize: $tileSize, ')
          ..write('attribution: $attribution, ')
          ..write('enabled: $enabled, ')
          ..write('opacity: $opacity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    url,
    scheme,
    subdomains,
    file,
    minZoom,
    maxZoom,
    tileSize,
    attribution,
    enabled,
    opacity,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileSourceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.url == this.url &&
          other.scheme == this.scheme &&
          other.subdomains == this.subdomains &&
          other.file == this.file &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.tileSize == this.tileSize &&
          other.attribution == this.attribution &&
          other.enabled == this.enabled &&
          other.opacity == this.opacity &&
          other.createdAt == this.createdAt);
}

class TileSourcesCompanion extends UpdateCompanion<TileSourceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String?> url;
  final Value<String> scheme;
  final Value<String> subdomains;
  final Value<String?> file;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<int> tileSize;
  final Value<String> attribution;
  final Value<bool> enabled;
  final Value<double> opacity;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TileSourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.url = const Value.absent(),
    this.scheme = const Value.absent(),
    this.subdomains = const Value.absent(),
    this.file = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.tileSize = const Value.absent(),
    this.attribution = const Value.absent(),
    this.enabled = const Value.absent(),
    this.opacity = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TileSourcesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    this.url = const Value.absent(),
    this.scheme = const Value.absent(),
    this.subdomains = const Value.absent(),
    this.file = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.tileSize = const Value.absent(),
    this.attribution = const Value.absent(),
    this.enabled = const Value.absent(),
    this.opacity = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<TileSourceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? url,
    Expression<String>? scheme,
    Expression<String>? subdomains,
    Expression<String>? file,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<int>? tileSize,
    Expression<String>? attribution,
    Expression<bool>? enabled,
    Expression<double>? opacity,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (url != null) 'url': url,
      if (scheme != null) 'scheme': scheme,
      if (subdomains != null) 'subdomains': subdomains,
      if (file != null) 'file': file,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (tileSize != null) 'tile_size': tileSize,
      if (attribution != null) 'attribution': attribution,
      if (enabled != null) 'enabled': enabled,
      if (opacity != null) 'opacity': opacity,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TileSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String?>? url,
    Value<String>? scheme,
    Value<String>? subdomains,
    Value<String?>? file,
    Value<int>? minZoom,
    Value<int>? maxZoom,
    Value<int>? tileSize,
    Value<String>? attribution,
    Value<bool>? enabled,
    Value<double>? opacity,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TileSourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      url: url ?? this.url,
      scheme: scheme ?? this.scheme,
      subdomains: subdomains ?? this.subdomains,
      file: file ?? this.file,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      tileSize: tileSize ?? this.tileSize,
      attribution: attribution ?? this.attribution,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (scheme.present) {
      map['scheme'] = Variable<String>(scheme.value);
    }
    if (subdomains.present) {
      map['subdomains'] = Variable<String>(subdomains.value);
    }
    if (file.present) {
      map['file'] = Variable<String>(file.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (tileSize.present) {
      map['tile_size'] = Variable<int>(tileSize.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TileSourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('url: $url, ')
          ..write('scheme: $scheme, ')
          ..write('subdomains: $subdomains, ')
          ..write('file: $file, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('tileSize: $tileSize, ')
          ..write('attribution: $attribution, ')
          ..write('enabled: $enabled, ')
          ..write('opacity: $opacity, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $LayersTable layers = $LayersTable(this);
  late final $FeaturesTable features = $FeaturesTable(this);
  late final $TileSourcesTable tileSources = $TileSourcesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingsEntries,
    layers,
    features,
    tileSources,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'layers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('features', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsEntry,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsEntriesTable, SettingsEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsEntriesTable,
                    SettingsEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsEntry,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;
typedef $$LayersTableCreateCompanionBuilder = LayersCompanion Function({
  required String id,
  required String name,
  Value<int> color,
  Value<bool> visible,
  Value<bool> archived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LayersTableUpdateCompanionBuilder = LayersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> color,
  Value<bool> visible,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$LayersTableReferences
    extends BaseReferences<_$AppDatabase, $LayersTable, LayerRow> {
  $$LayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FeaturesTable, List<FeatureRow>>
  _featuresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.features,
    aliasName: 'layers__id__features__layer_id',
  );

  $$FeaturesTableProcessedTableManager get featuresRefs {
    final manager = $$FeaturesTableTableManager(
      $_db,
      $_db.features,
    ).filter((f) => f.layerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_featuresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LayersTableFilterComposer
    extends Composer<_$AppDatabase, $LayersTable> {
  $$LayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> featuresRefs(
    Expression<bool> Function($$FeaturesTableFilterComposer f) f,
  ) {
    final $$FeaturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.features,
      getReferencedColumn: (t) => t.layerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeaturesTableFilterComposer(
            $db: $db,
            $table: $db.features,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LayersTableOrderingComposer
    extends Composer<_$AppDatabase, $LayersTable> {
  $$LayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LayersTable> {
  $$LayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get visible =>
      $composableBuilder(column: $table.visible, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> featuresRefs<T extends Object>(
    Expression<T> Function($$FeaturesTableAnnotationComposer a) f,
  ) {
    final $$FeaturesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.features,
      getReferencedColumn: (t) => t.layerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeaturesTableAnnotationComposer(
            $db: $db,
            $table: $db.features,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LayersTable,
          LayerRow,
          $$LayersTableFilterComposer,
          $$LayersTableOrderingComposer,
          $$LayersTableAnnotationComposer,
          $$LayersTableCreateCompanionBuilder,
          $$LayersTableUpdateCompanionBuilder,
          (LayerRow, $$LayersTableReferences),
          LayerRow,
          PrefetchHooks Function({bool featuresRefs})
        > {
  $$LayersTableTableManager(_$AppDatabase db, $LayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> visible = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LayersCompanion(
                id: id,
                name: name,
                color: color,
                visible: visible,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> color = const Value.absent(),
                Value<bool> visible = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LayersCompanion.insert(
                id: id,
                name: name,
                color: color,
                visible: visible,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LayersTable, LayerRow>(table),
                  $$LayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({featuresRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (featuresRefs) db.features],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (featuresRefs)
                    await $_getPrefetchedData<
                      LayerRow,
                      $LayersTable,
                      FeatureRow
                    >(
                      currentTable: table,
                      referencedTable: $$LayersTableReferences
                          ._featuresRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LayersTableReferences(db, table, p0).featuresRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.layerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LayersTable,
      LayerRow,
      $$LayersTableFilterComposer,
      $$LayersTableOrderingComposer,
      $$LayersTableAnnotationComposer,
      $$LayersTableCreateCompanionBuilder,
      $$LayersTableUpdateCompanionBuilder,
      (LayerRow, $$LayersTableReferences),
      LayerRow,
      PrefetchHooks Function({bool featuresRefs})
    >;
typedef $$FeaturesTableCreateCompanionBuilder = FeaturesCompanion Function({
  required String id,
  required String layerId,
  required String kind,
  Value<String> name,
  Value<String> description,
  Value<String> author,
  Value<String?> sidc,
  Value<int?> color,
  Value<double?> radius,
  required String geometry,
  Value<String?> extra,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FeaturesTableUpdateCompanionBuilder = FeaturesCompanion Function({
  Value<String> id,
  Value<String> layerId,
  Value<String> kind,
  Value<String> name,
  Value<String> description,
  Value<String> author,
  Value<String?> sidc,
  Value<int?> color,
  Value<double?> radius,
  Value<String> geometry,
  Value<String?> extra,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$FeaturesTableReferences
    extends BaseReferences<_$AppDatabase, $FeaturesTable, FeatureRow> {
  $$FeaturesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LayersTable _layerIdTable(_$AppDatabase db) =>
      db.layers.createAlias('features__layer_id__layers__id');

  $$LayersTableProcessedTableManager get layerId {
    final $_column = $_itemColumn<String>('layer_id')!;

    final manager = $$LayersTableTableManager(
      $_db,
      $_db.layers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_layerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FeaturesTableFilterComposer
    extends Composer<_$AppDatabase, $FeaturesTable> {
  $$FeaturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sidc => $composableBuilder(
    column: $table.sidc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LayersTableFilterComposer get layerId {
    final $$LayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layerId,
      referencedTable: $db.layers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayersTableFilterComposer(
            $db: $db,
            $table: $db.layers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeaturesTableOrderingComposer
    extends Composer<_$AppDatabase, $FeaturesTable> {
  $$FeaturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sidc => $composableBuilder(
    column: $table.sidc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LayersTableOrderingComposer get layerId {
    final $$LayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layerId,
      referencedTable: $db.layers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayersTableOrderingComposer(
            $db: $db,
            $table: $db.layers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeaturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeaturesTable> {
  $$FeaturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get sidc =>
      $composableBuilder(column: $table.sidc, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get radius =>
      $composableBuilder(column: $table.radius, builder: (column) => column);

  GeneratedColumn<String> get geometry =>
      $composableBuilder(column: $table.geometry, builder: (column) => column);

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LayersTableAnnotationComposer get layerId {
    final $$LayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layerId,
      referencedTable: $db.layers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayersTableAnnotationComposer(
            $db: $db,
            $table: $db.layers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeaturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeaturesTable,
          FeatureRow,
          $$FeaturesTableFilterComposer,
          $$FeaturesTableOrderingComposer,
          $$FeaturesTableAnnotationComposer,
          $$FeaturesTableCreateCompanionBuilder,
          $$FeaturesTableUpdateCompanionBuilder,
          (FeatureRow, $$FeaturesTableReferences),
          FeatureRow,
          PrefetchHooks Function({bool layerId})
        > {
  $$FeaturesTableTableManager(_$AppDatabase db, $FeaturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeaturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeaturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeaturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> layerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> sidc = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<double?> radius = const Value.absent(),
                Value<String> geometry = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeaturesCompanion(
                id: id,
                layerId: layerId,
                kind: kind,
                name: name,
                description: description,
                author: author,
                sidc: sidc,
                color: color,
                radius: radius,
                geometry: geometry,
                extra: extra,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String layerId,
                required String kind,
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> sidc = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<double?> radius = const Value.absent(),
                required String geometry,
                Value<String?> extra = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FeaturesCompanion.insert(
                id: id,
                layerId: layerId,
                kind: kind,
                name: name,
                description: description,
                author: author,
                sidc: sidc,
                color: color,
                radius: radius,
                geometry: geometry,
                extra: extra,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeaturesTable, FeatureRow>(table),
                  $$FeaturesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({layerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (layerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.layerId,
                        referencedTable: $$FeaturesTableReferences
                            ._layerIdTable(db),
                        referencedColumn: $$FeaturesTableReferences
                            ._layerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FeaturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeaturesTable,
      FeatureRow,
      $$FeaturesTableFilterComposer,
      $$FeaturesTableOrderingComposer,
      $$FeaturesTableAnnotationComposer,
      $$FeaturesTableCreateCompanionBuilder,
      $$FeaturesTableUpdateCompanionBuilder,
      (FeatureRow, $$FeaturesTableReferences),
      FeatureRow,
      PrefetchHooks Function({bool layerId})
    >;
typedef $$TileSourcesTableCreateCompanionBuilder =
    TileSourcesCompanion Function({
      required String id,
      required String name,
      required String kind,
      Value<String?> url,
      Value<String> scheme,
      Value<String> subdomains,
      Value<String?> file,
      Value<int> minZoom,
      Value<int> maxZoom,
      Value<int> tileSize,
      Value<String> attribution,
      Value<bool> enabled,
      Value<double> opacity,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TileSourcesTableUpdateCompanionBuilder =
    TileSourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String?> url,
      Value<String> scheme,
      Value<String> subdomains,
      Value<String?> file,
      Value<int> minZoom,
      Value<int> maxZoom,
      Value<int> tileSize,
      Value<String> attribution,
      Value<bool> enabled,
      Value<double> opacity,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TileSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $TileSourcesTable> {
  $$TileSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheme => $composableBuilder(
    column: $table.scheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subdomains => $composableBuilder(
    column: $table.subdomains,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get file => $composableBuilder(
    column: $table.file,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tileSize => $composableBuilder(
    column: $table.tileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TileSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $TileSourcesTable> {
  $$TileSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheme => $composableBuilder(
    column: $table.scheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subdomains => $composableBuilder(
    column: $table.subdomains,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get file => $composableBuilder(
    column: $table.file,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tileSize => $composableBuilder(
    column: $table.tileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TileSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TileSourcesTable> {
  $$TileSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get scheme =>
      $composableBuilder(column: $table.scheme, builder: (column) => column);

  GeneratedColumn<String> get subdomains => $composableBuilder(
    column: $table.subdomains,
    builder: (column) => column,
  );

  GeneratedColumn<String> get file =>
      $composableBuilder(column: $table.file, builder: (column) => column);

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<int> get tileSize =>
      $composableBuilder(column: $table.tileSize, builder: (column) => column);

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TileSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TileSourcesTable,
          TileSourceRow,
          $$TileSourcesTableFilterComposer,
          $$TileSourcesTableOrderingComposer,
          $$TileSourcesTableAnnotationComposer,
          $$TileSourcesTableCreateCompanionBuilder,
          $$TileSourcesTableUpdateCompanionBuilder,
          (
            TileSourceRow,
            BaseReferences<_$AppDatabase, $TileSourcesTable, TileSourceRow>,
          ),
          TileSourceRow,
          PrefetchHooks Function()
        > {
  $$TileSourcesTableTableManager(_$AppDatabase db, $TileSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TileSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TileSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TileSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> scheme = const Value.absent(),
                Value<String> subdomains = const Value.absent(),
                Value<String?> file = const Value.absent(),
                Value<int> minZoom = const Value.absent(),
                Value<int> maxZoom = const Value.absent(),
                Value<int> tileSize = const Value.absent(),
                Value<String> attribution = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TileSourcesCompanion(
                id: id,
                name: name,
                kind: kind,
                url: url,
                scheme: scheme,
                subdomains: subdomains,
                file: file,
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileSize: tileSize,
                attribution: attribution,
                enabled: enabled,
                opacity: opacity,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                Value<String?> url = const Value.absent(),
                Value<String> scheme = const Value.absent(),
                Value<String> subdomains = const Value.absent(),
                Value<String?> file = const Value.absent(),
                Value<int> minZoom = const Value.absent(),
                Value<int> maxZoom = const Value.absent(),
                Value<int> tileSize = const Value.absent(),
                Value<String> attribution = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TileSourcesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                url: url,
                scheme: scheme,
                subdomains: subdomains,
                file: file,
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileSize: tileSize,
                attribution: attribution,
                enabled: enabled,
                opacity: opacity,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TileSourcesTable, TileSourceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TileSourcesTable,
                    TileSourceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TileSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TileSourcesTable,
      TileSourceRow,
      $$TileSourcesTableFilterComposer,
      $$TileSourcesTableOrderingComposer,
      $$TileSourcesTableAnnotationComposer,
      $$TileSourcesTableCreateCompanionBuilder,
      $$TileSourcesTableUpdateCompanionBuilder,
      (
        TileSourceRow,
        BaseReferences<_$AppDatabase, $TileSourcesTable, TileSourceRow>,
      ),
      TileSourceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$LayersTableTableManager get layers =>
      $$LayersTableTableManager(_db, _db.layers);
  $$FeaturesTableTableManager get features =>
      $$FeaturesTableTableManager(_db, _db.features);
  $$TileSourcesTableTableManager get tileSources =>
      $$TileSourcesTableTableManager(_db, _db.tileSources);
}
