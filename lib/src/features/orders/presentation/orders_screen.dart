import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../domain/order.dart';
import 'orders_controller.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return AsyncValueView<List<Order>>(
      value: ordersAsync,
      onRetry: () => ref.invalidate(ordersProvider),
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(ordersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: theme.textTheme.titleMedium),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 20),
            Text('${order.items.length} item(s)', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatCurrency(order.total),
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
