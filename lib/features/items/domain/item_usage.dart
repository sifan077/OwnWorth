/// A single recorded use of an item.
///
/// Usage is stored as an event rather than a counter so the app can show when
/// an item was last used and let the user correct a mistaken record.
class ItemUsage {
  const ItemUsage({
    required this.id,
    required this.itemId,
    required this.usedAt,
  });

  final String id;
  final String itemId;

  /// The instant of the use, in UTC. Display code converts it to local time.
  final DateTime usedAt;
}
