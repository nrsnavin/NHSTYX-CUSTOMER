import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String event) {
    switch (event) {
      case 'ORDER_PLACED':
        return Icons.receipt_long_outlined;
      case 'PAYMENT_RECEIVED':
        return Icons.payments_outlined;
      case 'ORDER_SHIPPED':
        return Icons.local_shipping_outlined;
      case 'ORDER_DELIVERED':
        return Icons.check_circle_outline;
      case 'RETURN_REQUESTED':
        return Icons.assignment_return_outlined;
      case 'RETURN_REFUNDED':
        return Icons.currency_rupee;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: AsyncValueView<NotificationFeed>(
        value: async,
        onRetry: () => ref.invalidate(notificationsProvider),
        loading: () => const ListCardSkeleton(itemCount: 6, height: 72),
        data: (feed) {
          if (feed.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              itemCount: feed.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = feed.items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: n.read
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    child: Icon(_iconFor(n.event),
                        size: 20,
                        color: n.read
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary),
                  ),
                  title: Text(
                    n.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(n.body),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM, h:mm a').format(n.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                  trailing: n.read
                      ? null
                      : Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  isThreeLine: true,
                  onTap: n.read
                      ? null
                      : () async {
                          await ref.read(notificationRepositoryProvider).markRead(n.id);
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadNotificationsProvider);
                        },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
