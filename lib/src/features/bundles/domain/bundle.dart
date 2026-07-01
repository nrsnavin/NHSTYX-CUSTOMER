/// One product line within a bundle, priced for the shopper's store.
class BundleLine {
  const BundleLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.available,
    this.brand,
    this.imageUrl,
    this.pricePaise,
    this.lineTotalPaise,
  });

  final String productId;
  final String name;
  final String? brand;
  final String? imageUrl;
  final int quantity;
  final int? pricePaise;
  final int? lineTotalPaise;
  final bool available;

  factory BundleLine.fromJson(Map<String, dynamic> json) => BundleLine(
        productId: json['productId'] as String,
        name: (json['name'] ?? '') as String,
        brand: json['brand'] as String?,
        imageUrl: json['imageUrl'] as String?,
        quantity: (json['quantity'] ?? 1) as int,
        pricePaise: json['pricePaise'] as int?,
        lineTotalPaise: json['lineTotalPaise'] as int?,
        available: json['available'] == true,
      );
}

/// A curated set of products the shop can add to their cart in one tap.
class Bundle {
  const Bundle({
    required this.id,
    required this.name,
    required this.items,
    required this.totalPaise,
    required this.allAvailable,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<BundleLine> items;
  final int totalPaise;
  final bool allAvailable;

  factory Bundle.fromJson(Map<String, dynamic> json) => Bundle(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => BundleLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPaise: (json['totalPaise'] ?? 0) as int,
        allAvailable: json['allAvailable'] == true,
      );
}
