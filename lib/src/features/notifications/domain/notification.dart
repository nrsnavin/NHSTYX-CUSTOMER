class AppNotification {
  const AppNotification({
    required this.id,
    required this.event,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.orderId,
  });

  final String id;
  final String event;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? orderId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      event: (json['event'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      read: json['status'] == 'READ',
      orderId: json['orderId'] as String?,
    );
  }
}

/// The feed plus its unread badge count.
class NotificationFeed {
  const NotificationFeed({required this.items, required this.unread});

  final List<AppNotification> items;
  final int unread;

  factory NotificationFeed.fromJson(Map<String, dynamic> json) {
    return NotificationFeed(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unread: json['unread'] is num ? (json['unread'] as num).toInt() : 0,
    );
  }
}
