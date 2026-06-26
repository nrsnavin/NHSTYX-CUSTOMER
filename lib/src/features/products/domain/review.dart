int _toInt(dynamic v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);
double _toDouble(dynamic v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);

class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.shopName,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final int rating;
  final String shopName;
  final DateTime createdAt;
  final String? comment;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as String,
      rating: _toInt(json['rating']),
      shopName: (json['shopName'] ?? 'A shop') as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      comment: json['comment'] as String?,
    );
  }
}

/// A product's rating summary plus its recent reviews.
class ReviewSummary {
  const ReviewSummary({required this.avg, required this.count, required this.items});

  final double avg;
  final int count;
  final List<ProductReview> items;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>? ?? const {};
    return ReviewSummary(
      avg: _toDouble(s['avg']),
      count: _toInt(s['count']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
