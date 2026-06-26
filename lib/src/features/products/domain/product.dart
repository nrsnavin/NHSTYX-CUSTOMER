int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class PriceTier {
  const PriceTier({required this.minQty, required this.pricePaise});

  final int minQty;
  final int pricePaise;

  factory PriceTier.fromJson(Map<String, dynamic> json) =>
      PriceTier(minQty: _toInt(json['minQty']), pricePaise: _toInt(json['pricePaise']));
}

/// An orderable variation of a product (e.g. "Red / M") with its own per-store
/// price & stock.
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.pricePaise,
    required this.stockQty,
    this.sku,
    this.mrpPaise,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int pricePaise;
  final int stockQty;
  final String? sku;
  final int? mrpPaise;
  final String? imageUrl;

  bool get inStock => stockQty > 0;

  int? get discountPercent {
    final mrp = mrpPaise;
    if (mrp == null || mrp <= pricePaise) return null;
    return ((mrp - pricePaise) / mrp * 100).round();
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      pricePaise: _toInt(json['pricePaise']),
      stockQty: _toInt(json['stockQty']),
      sku: json['sku'] as String?,
      mrpPaise: json['mrpPaise'] == null ? null : _toInt(json['mrpPaise']),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// A flat catalog product priced in integer paise, GST-exclusive.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.pricePaise,
    required this.gstRatePercent,
    required this.moqQty,
    required this.stockQty,
    this.brand,
    this.description,
    this.hsnCode,
    this.mrpPaise,
    this.imageUrl,
    this.categoryName,
    this.tags = const [],
    this.priceTiers = const [],
    this.hasVariants = false,
    this.variants = const [],
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final String id;
  final String name;
  final String unit;
  final int pricePaise;
  final int gstRatePercent;
  final int moqQty;
  final int stockQty;
  final String? brand;
  final String? description;
  final String? hsnCode;
  final int? mrpPaise;
  final String? imageUrl;
  final String? categoryName;
  final List<String> tags;
  final List<PriceTier> priceTiers;

  /// True when the product is sold via variants (size/colour). The card then
  /// prompts "Select" instead of a one-tap add; [variants] is populated on the
  /// product-detail fetch.
  final bool hasVariants;
  final List<ProductVariant> variants;

  /// Average star rating (0 when no reviews) and the number of reviews.
  final double ratingAvg;
  final int ratingCount;

  bool get hasRatings => ratingCount > 0;

  bool get inStock => stockQty > 0;

  /// Lowest advertised per-unit price across base + tiers.
  int get fromPricePaise {
    var lowest = pricePaise;
    for (final tier in priceTiers) {
      if (tier.pricePaise < lowest) lowest = tier.pricePaise;
    }
    return lowest;
  }

  /// Whole-number discount percent of the displayed (lowest) price against the
  /// MRP, or null when there's no MRP or no real saving.
  int? get discountPercent {
    final mrp = mrpPaise;
    if (mrp == null || mrp <= fromPricePaise) return null;
    return ((mrp - fromPricePaise) / mrp * 100).round();
  }

  /// Resolves the per-unit price for a quantity (highest applicable tier wins).
  int unitPricePaiseFor(int quantity) {
    var price = pricePaise;
    var bestMinQty = 0;
    for (final tier in priceTiers) {
      if (quantity >= tier.minQty && tier.minQty >= bestMinQty) {
        price = tier.pricePaise;
        bestMinQty = tier.minQty;
      }
    }
    return price;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: (json['unit'] ?? 'PIECE') as String,
      pricePaise: _toInt(json['pricePaise']),
      gstRatePercent: _toInt(json['gstRatePercent']),
      moqQty: json['moqQty'] == null ? 1 : _toInt(json['moqQty']),
      stockQty: _toInt(json['stockQty']),
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      hsnCode: json['hsnCode'] as String?,
      mrpPaise: json['mrpPaise'] == null ? null : _toInt(json['mrpPaise']),
      imageUrl: json['imageUrl'] as String?,
      categoryName: category?['name'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      priceTiers: (json['priceTiers'] as List<dynamic>? ?? [])
          .map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasVariants: json['hasVariants'] == true,
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      ratingAvg: _toDouble(json['ratingAvg']),
      ratingCount: _toInt(json['ratingCount']),
    );
  }
}
