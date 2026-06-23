int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class PriceTier {
  const PriceTier({required this.minQty, required this.pricePaise});

  final int minQty;
  final int pricePaise;

  factory PriceTier.fromJson(Map<String, dynamic> json) =>
      PriceTier(minQty: _toInt(json['minQty']), pricePaise: _toInt(json['pricePaise']));
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
    this.priceTiers = const [],
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
  final List<PriceTier> priceTiers;

  bool get inStock => stockQty > 0;

  /// Lowest advertised per-unit price across base + tiers.
  int get fromPricePaise {
    var lowest = pricePaise;
    for (final tier in priceTiers) {
      if (tier.pricePaise < lowest) lowest = tier.pricePaise;
    }
    return lowest;
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
      priceTiers: (json['priceTiers'] as List<dynamic>? ?? [])
          .map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
