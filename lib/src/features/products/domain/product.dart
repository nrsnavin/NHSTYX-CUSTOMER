double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.price,
    required this.minOrderQty,
    required this.stockQuantity,
    this.size,
    this.color,
    this.mrp,
  });

  final String id;
  final String sku;
  final double price;
  final double? mrp;
  final int minOrderQty;
  final int stockQuantity;
  final String? size;
  final String? color;

  bool get inStock => stockQuantity > 0;

  String get label {
    final parts = [size, color].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isEmpty ? sku : parts.join(' / ');
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      sku: json['sku'] as String,
      price: _toDouble(json['price']),
      mrp: json['mrp'] == null ? null : _toDouble(json['mrp']),
      minOrderQty: (json['minOrderQty'] ?? 1) as int,
      stockQuantity: (json['stockQuantity'] ?? 0) as int,
      size: json['size'] as String?,
      color: json['color'] as String?,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.variants,
    this.brand,
    this.categoryName,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String? brand;
  final String? categoryName;
  final List<String> imageUrls;
  final List<ProductVariant> variants;

  double get fromPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  ProductVariant? get defaultVariant => variants.isEmpty ? null : variants.first;

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      categoryName: category?['name'] as String?,
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
