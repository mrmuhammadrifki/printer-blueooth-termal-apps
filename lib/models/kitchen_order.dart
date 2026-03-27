class KitchenOrder {
  final String orderId;
  final String? tableName;
  final String? customerName;
  final String? timestamp;
  final List<KitchenOrderItem> items;

  KitchenOrder({
    required this.orderId,
    this.tableName,
    this.customerName,
    this.timestamp,
    required this.items,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      orderId: json['orderId'] ?? 'N/A',
      tableName: json['tableName'] ?? json['tableNumber'] ?? json['tableId'],
      customerName: json['customerName'],
      timestamp: json['timestamp'],
      items:
          (json['items'] as List?)
              ?.map((e) => KitchenOrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class KitchenOrderItem {
  final String name;
  final int quantity;
  final String? notes;

  KitchenOrderItem({required this.name, required this.quantity, this.notes});

  factory KitchenOrderItem.fromJson(Map<String, dynamic> json) {
    return KitchenOrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
    );
  }
}
