class TrackingCheckpoint {
  const TrackingCheckpoint({
    required this.status,
    required this.at,
    this.note,
    this.location,
  });

  final String status;
  final DateTime at;
  final String? note;
  final String? location;

  factory TrackingCheckpoint.fromJson(Map<String, dynamic> json) {
    return TrackingCheckpoint(
      status: (json['status'] ?? '') as String,
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
      location: json['location'] as String?,
    );
  }
}

/// A shipment's tracking: courier + AWB + a checkpoint timeline (live from the
/// courier when the backend has a shipping partner configured).
class OrderTracking {
  const OrderTracking({
    required this.status,
    required this.live,
    required this.checkpoints,
    this.courierName,
    this.trackingNumber,
    this.trackingUrl,
    this.shippedAt,
    this.deliveredAt,
  });

  final String status;
  final bool live;
  final List<TrackingCheckpoint> checkpoints;
  final String? courierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  bool get hasTracking => (trackingNumber ?? '').isNotEmpty;

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return OrderTracking(
      status: (json['status'] ?? 'PENDING') as String,
      live: json['live'] == true,
      courierName: json['courierName'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      trackingUrl: json['trackingUrl'] as String?,
      shippedAt: d(json['shippedAt']),
      deliveredAt: d(json['deliveredAt']),
      checkpoints: (json['checkpoints'] as List<dynamic>? ?? const [])
          .map((e) => TrackingCheckpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
