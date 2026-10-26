/// Item categories offered by the app.
enum ItemCategory {
  digital('digital', '数码'),
  appliance('appliance', '家电'),
  home('home', '家居'),
  clothing('clothing', '衣物'),
  entertainment('entertainment', '娱乐'),
  other('other', '其他');

  const ItemCategory(this.id, this.label);

  /// Stable identifier stored in SQLite and backups.
  final String id;

  /// Chinese label shown in the UI.
  final String label;

  static ItemCategory fromId(String? id) {
    return ItemCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => ItemCategory.other,
    );
  }
}

/// Whether an item is still owned or its cost has been frozen.
enum ItemStatus {
  active('ACTIVE', '使用中'),
  ended('ENDED', '已结束');

  const ItemStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ItemStatus fromStorage(String? value) {
    return value == ItemStatus.ended.storageValue
        ? ItemStatus.ended
        : ItemStatus.active;
  }
}

const Object _unsetValue = Object();

/// A durable possession tracked by the app.
///
/// Calendar dates ([purchaseDate] and [endDate]) are date-only containers.
/// [createdAt] and [updatedAt] are real instants in UTC.
class OwnedItem {
  const OwnedItem({
    required this.id,
    required this.name,
    required this.purchasePriceCents,
    required this.purchaseDate,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.targetDailyCostCents,
    this.endDate,
    this.note,
  });

  final String id;
  final String name;
  final int purchasePriceCents;
  final DateTime purchaseDate;
  final ItemCategory category;

  /// Path relative to the app's data directory, e.g. `images/abc.jpg`.
  final String? imagePath;
  final int? targetDailyCostCents;
  final ItemStatus status;
  final DateTime? endDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == ItemStatus.active;
  bool get hasTarget =>
      targetDailyCostCents != null && targetDailyCostCents! > 0;

  OwnedItem copyWith({
    String? id,
    String? name,
    int? purchasePriceCents,
    DateTime? purchaseDate,
    ItemCategory? category,
    Object? imagePath = _unsetValue,
    Object? targetDailyCostCents = _unsetValue,
    ItemStatus? status,
    Object? endDate = _unsetValue,
    Object? note = _unsetValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OwnedItem(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePriceCents: purchasePriceCents ?? this.purchasePriceCents,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      category: category ?? this.category,
      imagePath: identical(imagePath, _unsetValue)
          ? this.imagePath
          : imagePath as String?,
      targetDailyCostCents: identical(targetDailyCostCents, _unsetValue)
          ? this.targetDailyCostCents
          : targetDailyCostCents as int?,
      status: status ?? this.status,
      endDate: identical(endDate, _unsetValue)
          ? this.endDate
          : endDate as DateTime?,
      note: identical(note, _unsetValue) ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
