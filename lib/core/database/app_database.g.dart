// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemEntriesTable extends ItemEntries
    with TableInfo<$ItemEntriesTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _purchasePriceCentsMeta =
      const VerificationMeta('purchasePriceCents');
  @override
  late final GeneratedColumn<int> purchasePriceCents = GeneratedColumn<int>(
    'purchase_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDailyCostCentsMeta =
      const VerificationMeta('targetDailyCostCents');
  @override
  late final GeneratedColumn<int> targetDailyCostCents = GeneratedColumn<int>(
    'target_daily_cost_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    name,
    purchasePriceCents,
    purchaseDate,
    category,
    imagePath,
    targetDailyCostCents,
    status,
    endDate,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
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
    if (data.containsKey('purchase_price_cents')) {
      context.handle(
        _purchasePriceCentsMeta,
        purchasePriceCents.isAcceptableOrUnknown(
          data['purchase_price_cents']!,
          _purchasePriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasePriceCentsMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('target_daily_cost_cents')) {
      context.handle(
        _targetDailyCostCentsMeta,
        targetDailyCostCents.isAcceptableOrUnknown(
          data['target_daily_cost_cents']!,
          _targetDailyCostCentsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      purchasePriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_cents'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      targetDailyCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_daily_cost_cents'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
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
  $ItemEntriesTable createAlias(String alias) {
    return $ItemEntriesTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final String name;
  final int purchasePriceCents;
  final String purchaseDate;
  final String category;
  final String? imagePath;
  final int? targetDailyCostCents;
  final String status;
  final String? endDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ItemRow({
    required this.id,
    required this.name,
    required this.purchasePriceCents,
    required this.purchaseDate,
    required this.category,
    this.imagePath,
    this.targetDailyCostCents,
    required this.status,
    this.endDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['purchase_price_cents'] = Variable<int>(purchasePriceCents);
    map['purchase_date'] = Variable<String>(purchaseDate);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || targetDailyCostCents != null) {
      map['target_daily_cost_cents'] = Variable<int>(targetDailyCostCents);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ItemEntriesCompanion toCompanion(bool nullToAbsent) {
    return ItemEntriesCompanion(
      id: Value(id),
      name: Value(name),
      purchasePriceCents: Value(purchasePriceCents),
      purchaseDate: Value(purchaseDate),
      category: Value(category),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      targetDailyCostCents: targetDailyCostCents == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDailyCostCents),
      status: Value(status),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      purchasePriceCents: serializer.fromJson<int>(json['purchasePriceCents']),
      purchaseDate: serializer.fromJson<String>(json['purchaseDate']),
      category: serializer.fromJson<String>(json['category']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      targetDailyCostCents: serializer.fromJson<int?>(
        json['targetDailyCostCents'],
      ),
      status: serializer.fromJson<String>(json['status']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      note: serializer.fromJson<String?>(json['note']),
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
      'purchasePriceCents': serializer.toJson<int>(purchasePriceCents),
      'purchaseDate': serializer.toJson<String>(purchaseDate),
      'category': serializer.toJson<String>(category),
      'imagePath': serializer.toJson<String?>(imagePath),
      'targetDailyCostCents': serializer.toJson<int?>(targetDailyCostCents),
      'status': serializer.toJson<String>(status),
      'endDate': serializer.toJson<String?>(endDate),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ItemRow copyWith({
    String? id,
    String? name,
    int? purchasePriceCents,
    String? purchaseDate,
    String? category,
    Value<String?> imagePath = const Value.absent(),
    Value<int?> targetDailyCostCents = const Value.absent(),
    String? status,
    Value<String?> endDate = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    purchasePriceCents: purchasePriceCents ?? this.purchasePriceCents,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    category: category ?? this.category,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    targetDailyCostCents: targetDailyCostCents.present
        ? targetDailyCostCents.value
        : this.targetDailyCostCents,
    status: status ?? this.status,
    endDate: endDate.present ? endDate.value : this.endDate,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemRow copyWithCompanion(ItemEntriesCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      purchasePriceCents: data.purchasePriceCents.present
          ? data.purchasePriceCents.value
          : this.purchasePriceCents,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      category: data.category.present ? data.category.value : this.category,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      targetDailyCostCents: data.targetDailyCostCents.present
          ? data.targetDailyCostCents.value
          : this.targetDailyCostCents,
      status: data.status.present ? data.status.value : this.status,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('purchasePriceCents: $purchasePriceCents, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('category: $category, ')
          ..write('imagePath: $imagePath, ')
          ..write('targetDailyCostCents: $targetDailyCostCents, ')
          ..write('status: $status, ')
          ..write('endDate: $endDate, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    purchasePriceCents,
    purchaseDate,
    category,
    imagePath,
    targetDailyCostCents,
    status,
    endDate,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.purchasePriceCents == this.purchasePriceCents &&
          other.purchaseDate == this.purchaseDate &&
          other.category == this.category &&
          other.imagePath == this.imagePath &&
          other.targetDailyCostCents == this.targetDailyCostCents &&
          other.status == this.status &&
          other.endDate == this.endDate &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemEntriesCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> purchasePriceCents;
  final Value<String> purchaseDate;
  final Value<String> category;
  final Value<String?> imagePath;
  final Value<int?> targetDailyCostCents;
  final Value<String> status;
  final Value<String?> endDate;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ItemEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.purchasePriceCents = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.category = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.targetDailyCostCents = const Value.absent(),
    this.status = const Value.absent(),
    this.endDate = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemEntriesCompanion.insert({
    required String id,
    required String name,
    required int purchasePriceCents,
    required String purchaseDate,
    required String category,
    this.imagePath = const Value.absent(),
    this.targetDailyCostCents = const Value.absent(),
    required String status,
    this.endDate = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       purchasePriceCents = Value(purchasePriceCents),
       purchaseDate = Value(purchaseDate),
       category = Value(category),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? purchasePriceCents,
    Expression<String>? purchaseDate,
    Expression<String>? category,
    Expression<String>? imagePath,
    Expression<int>? targetDailyCostCents,
    Expression<String>? status,
    Expression<String>? endDate,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (purchasePriceCents != null)
        'purchase_price_cents': purchasePriceCents,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (category != null) 'category': category,
      if (imagePath != null) 'image_path': imagePath,
      if (targetDailyCostCents != null)
        'target_daily_cost_cents': targetDailyCostCents,
      if (status != null) 'status': status,
      if (endDate != null) 'end_date': endDate,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? purchasePriceCents,
    Value<String>? purchaseDate,
    Value<String>? category,
    Value<String?>? imagePath,
    Value<int?>? targetDailyCostCents,
    Value<String>? status,
    Value<String?>? endDate,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ItemEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePriceCents: purchasePriceCents ?? this.purchasePriceCents,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      targetDailyCostCents: targetDailyCostCents ?? this.targetDailyCostCents,
      status: status ?? this.status,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
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
    if (purchasePriceCents.present) {
      map['purchase_price_cents'] = Variable<int>(purchasePriceCents.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (targetDailyCostCents.present) {
      map['target_daily_cost_cents'] = Variable<int>(
        targetDailyCostCents.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('ItemEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('purchasePriceCents: $purchasePriceCents, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('category: $category, ')
          ..write('imagePath: $imagePath, ')
          ..write('targetDailyCostCents: $targetDailyCostCents, ')
          ..write('status: $status, ')
          ..write('endDate: $endDate, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageEntriesTable extends UsageEntries
    with TableInfo<$UsageEntriesTable, UsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
    'used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, itemId, usedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_usages';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_usedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}used_at'],
      )!,
    );
  }

  @override
  $UsageEntriesTable createAlias(String alias) {
    return $UsageEntriesTable(attachedDatabase, alias);
  }
}

class UsageRow extends DataClass implements Insertable<UsageRow> {
  final String id;
  final String itemId;
  final DateTime usedAt;
  const UsageRow({
    required this.id,
    required this.itemId,
    required this.usedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['used_at'] = Variable<DateTime>(usedAt);
    return map;
  }

  UsageEntriesCompanion toCompanion(bool nullToAbsent) {
    return UsageEntriesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      usedAt: Value(usedAt),
    );
  }

  factory UsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      usedAt: serializer.fromJson<DateTime>(json['usedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'usedAt': serializer.toJson<DateTime>(usedAt),
    };
  }

  UsageRow copyWith({String? id, String? itemId, DateTime? usedAt}) => UsageRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    usedAt: usedAt ?? this.usedAt,
  );
  UsageRow copyWithCompanion(UsageEntriesCompanion data) {
    return UsageRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('usedAt: $usedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, usedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.usedAt == this.usedAt);
}

class UsageEntriesCompanion extends UpdateCompanion<UsageRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<DateTime> usedAt;
  final Value<int> rowid;
  const UsageEntriesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsageEntriesCompanion.insert({
    required String id,
    required String itemId,
    required DateTime usedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       usedAt = Value(usedAt);
  static Insertable<UsageRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<DateTime>? usedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (usedAt != null) 'used_at': usedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsageEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<DateTime>? usedAt,
    Value<int>? rowid,
  }) {
    return UsageEntriesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      usedAt: usedAt ?? this.usedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageEntriesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('usedAt: $usedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemEntriesTable itemEntries = $ItemEntriesTable(this);
  late final $UsageEntriesTable usageEntries = $UsageEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    itemEntries,
    usageEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_usages', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ItemEntriesTableCreateCompanionBuilder =
    ItemEntriesCompanion Function({
      required String id,
      required String name,
      required int purchasePriceCents,
      required String purchaseDate,
      required String category,
      Value<String?> imagePath,
      Value<int?> targetDailyCostCents,
      required String status,
      Value<String?> endDate,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ItemEntriesTableUpdateCompanionBuilder =
    ItemEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> purchasePriceCents,
      Value<String> purchaseDate,
      Value<String> category,
      Value<String?> imagePath,
      Value<int?> targetDailyCostCents,
      Value<String> status,
      Value<String?> endDate,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ItemEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $ItemEntriesTable, ItemRow> {
  $$ItemEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UsageEntriesTable, List<UsageRow>>
  _usageEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.usageEntries,
    aliasName: 'items__id__item_usages__item_id',
  );

  $$UsageEntriesTableProcessedTableManager get usageEntriesRefs {
    final manager = $$UsageEntriesTableTableManager(
      $_db,
      $_db.usageEntries,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_usageEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ItemEntriesTable> {
  $$ItemEntriesTableFilterComposer({
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

  ColumnFilters<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDailyCostCents => $composableBuilder(
    column: $table.targetDailyCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  Expression<bool> usageEntriesRefs(
    Expression<bool> Function($$UsageEntriesTableFilterComposer f) f,
  ) {
    final $$UsageEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usageEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsageEntriesTableFilterComposer(
            $db: $db,
            $table: $db.usageEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemEntriesTable> {
  $$ItemEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDailyCostCents => $composableBuilder(
    column: $table.targetDailyCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

class $$ItemEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemEntriesTable> {
  $$ItemEntriesTableAnnotationComposer({
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

  GeneratedColumn<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get targetDailyCostCents => $composableBuilder(
    column: $table.targetDailyCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> usageEntriesRefs<T extends Object>(
    Expression<T> Function($$UsageEntriesTableAnnotationComposer a) f,
  ) {
    final $$UsageEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usageEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsageEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.usageEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemEntriesTable,
          ItemRow,
          $$ItemEntriesTableFilterComposer,
          $$ItemEntriesTableOrderingComposer,
          $$ItemEntriesTableAnnotationComposer,
          $$ItemEntriesTableCreateCompanionBuilder,
          $$ItemEntriesTableUpdateCompanionBuilder,
          (ItemRow, $$ItemEntriesTableReferences),
          ItemRow,
          PrefetchHooks Function({bool usageEntriesRefs})
        > {
  $$ItemEntriesTableTableManager(_$AppDatabase db, $ItemEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> purchasePriceCents = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int?> targetDailyCostCents = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemEntriesCompanion(
                id: id,
                name: name,
                purchasePriceCents: purchasePriceCents,
                purchaseDate: purchaseDate,
                category: category,
                imagePath: imagePath,
                targetDailyCostCents: targetDailyCostCents,
                status: status,
                endDate: endDate,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int purchasePriceCents,
                required String purchaseDate,
                required String category,
                Value<String?> imagePath = const Value.absent(),
                Value<int?> targetDailyCostCents = const Value.absent(),
                required String status,
                Value<String?> endDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ItemEntriesCompanion.insert(
                id: id,
                name: name,
                purchasePriceCents: purchasePriceCents,
                purchaseDate: purchaseDate,
                category: category,
                imagePath: imagePath,
                targetDailyCostCents: targetDailyCostCents,
                status: status,
                endDate: endDate,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemEntriesTable, ItemRow>(table),
                  $$ItemEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({usageEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (usageEntriesRefs) db.usageEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (usageEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      ItemRow,
                      $ItemEntriesTable,
                      UsageRow,
                      $UsageEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ItemEntriesTableReferences
                          ._usageEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ItemEntriesTableReferences(
                            db,
                            table,
                            p0,
                          ).usageEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'item_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ItemEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemEntriesTable,
      ItemRow,
      $$ItemEntriesTableFilterComposer,
      $$ItemEntriesTableOrderingComposer,
      $$ItemEntriesTableAnnotationComposer,
      $$ItemEntriesTableCreateCompanionBuilder,
      $$ItemEntriesTableUpdateCompanionBuilder,
      (ItemRow, $$ItemEntriesTableReferences),
      ItemRow,
      PrefetchHooks Function({bool usageEntriesRefs})
    >;
typedef $$UsageEntriesTableCreateCompanionBuilder =
    UsageEntriesCompanion Function({
      required String id,
      required String itemId,
      required DateTime usedAt,
      Value<int> rowid,
    });
typedef $$UsageEntriesTableUpdateCompanionBuilder =
    UsageEntriesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<DateTime> usedAt,
      Value<int> rowid,
    });

final class $$UsageEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $UsageEntriesTable, UsageRow> {
  $$UsageEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemEntriesTable _itemIdTable(_$AppDatabase db) =>
      db.itemEntries.createAlias('item_usages__item_id__items__id');

  $$ItemEntriesTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemEntriesTableTableManager(
      $_db,
      $_db.itemEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UsageEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UsageEntriesTable> {
  $$UsageEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemEntriesTableFilterComposer get itemId {
    final $$ItemEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemEntriesTableFilterComposer(
            $db: $db,
            $table: $db.itemEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageEntriesTable> {
  $$UsageEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemEntriesTableOrderingComposer get itemId {
    final $$ItemEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.itemEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageEntriesTable> {
  $$UsageEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  $$ItemEntriesTableAnnotationComposer get itemId {
    final $$ItemEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.itemEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.itemEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsageEntriesTable,
          UsageRow,
          $$UsageEntriesTableFilterComposer,
          $$UsageEntriesTableOrderingComposer,
          $$UsageEntriesTableAnnotationComposer,
          $$UsageEntriesTableCreateCompanionBuilder,
          $$UsageEntriesTableUpdateCompanionBuilder,
          (UsageRow, $$UsageEntriesTableReferences),
          UsageRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$UsageEntriesTableTableManager(_$AppDatabase db, $UsageEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<DateTime> usedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsageEntriesCompanion(
                id: id,
                itemId: itemId,
                usedAt: usedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required DateTime usedAt,
                Value<int> rowid = const Value.absent(),
              }) => UsageEntriesCompanion.insert(
                id: id,
                itemId: itemId,
                usedAt: usedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsageEntriesTable, UsageRow>(table),
                  $$UsageEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$UsageEntriesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$UsageEntriesTableReferences
                            ._itemIdTable(db)
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

typedef $$UsageEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsageEntriesTable,
      UsageRow,
      $$UsageEntriesTableFilterComposer,
      $$UsageEntriesTableOrderingComposer,
      $$UsageEntriesTableAnnotationComposer,
      $$UsageEntriesTableCreateCompanionBuilder,
      $$UsageEntriesTableUpdateCompanionBuilder,
      (UsageRow, $$UsageEntriesTableReferences),
      UsageRow,
      PrefetchHooks Function({bool itemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemEntriesTableTableManager get itemEntries =>
      $$ItemEntriesTableTableManager(_db, _db.itemEntries);
  $$UsageEntriesTableTableManager get usageEntries =>
      $$UsageEntriesTableTableManager(_db, _db.usageEntries);
}
