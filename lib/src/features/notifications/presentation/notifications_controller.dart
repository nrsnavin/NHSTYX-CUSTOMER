import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import '../domain/notification.dart';

/// The customer's in-app notification feed (most recent first) + unread count.
final notificationsProvider = FutureProvider.autoDispose<NotificationFeed>((ref) {
  return ref.watch(notificationRepositoryProvider).fetchMine();
});

/// Just the unread badge count — backs the bell on the Orders tab.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  final feed = await ref.watch(notificationRepositoryProvider).fetchMine();
  return feed.unread;
});
