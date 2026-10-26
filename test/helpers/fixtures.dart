import 'package:ownworth/features/items/domain/item_usage.dart';
import 'package:ownworth/features/items/domain/owned_item.dart';

OwnedItem buildItem({
  String id = 'item-1',
  String name = '降噪耳机',
  int purchasePriceCents = 300000,
  DateTime? purchaseDate,
  ItemCategory category = ItemCategory.digital,
  String? imagePath,
  int? targetDailyCostCents,
  ItemStatus status = ItemStatus.active,
  DateTime? endDate,
  String? note,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 10, 25, 2, 30);
  return OwnedItem(
    id: id,
    name: name,
    purchasePriceCents: purchasePriceCents,
    purchaseDate: purchaseDate ?? DateTime.utc(2026, 10, 25),
    category: category,
    imagePath: imagePath,
    targetDailyCostCents: targetDailyCostCents,
    status: status,
    endDate: endDate,
    note: note,
    createdAt: created,
    updatedAt: updatedAt ?? created,
  );
}

ItemUsage buildUsage({
  String id = 'usage-1',
  String itemId = 'item-1',
  DateTime? usedAt,
}) {
  return ItemUsage(
    id: id,
    itemId: itemId,
    usedAt: usedAt ?? DateTime.utc(2026, 10, 20, 12),
  );
}
