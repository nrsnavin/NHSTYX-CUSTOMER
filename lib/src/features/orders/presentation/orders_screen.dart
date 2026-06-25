import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../data/order_repository.dart';
import '../data/razorpay_service.dart';
import '../domain/order.dart';
import 'invoice_screen.dart';
import 'orders_controller.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: AsyncValueView<List<Order>>(
        value: ordersAsync,
        onRetry: () => ref.invalidate(ordersProvider),
        loading: () => const ListCardSkeleton(height: 168),
        data: (orders) {
          if (orders.isEmpty) return const _NoOrders();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('No orders yet', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Visual treatment for an order status (Blinkit-style coloured pill).
({Color color, IconData icon, String label}) _statusStyle(String status) {
  switch (status) {
    case 'DELIVERED':
      return (color: const Color(0xFF1A7F37), icon: Icons.check_circle, label: 'Delivered');
    case 'SHIPPED':
      return (color: const Color(0xFF0B6BCB), icon: Icons.local_shipping, label: 'Shipped');
    case 'PACKED':
      return (color: const Color(0xFF6750A4), icon: Icons.inventory_2, label: 'Packed');
    case 'CONFIRMED':
      return (color: const Color(0xFF0B6BCB), icon: Icons.task_alt, label: 'Confirmed');
    case 'CANCELLED':
    case 'REJECTED':
      return (color: const Color(0xFFB3261E), icon: Icons.cancel, label: 'Cancelled');
    default:
      return (color: const Color(0xFF9A6700), icon: Icons.schedule, label: 'Pending');
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final Order order;

  /// Re-adds every line of this order to the cart, then jumps to the Cart tab.
  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(cartControllerProvider.notifier);
    var added = 0;
    var failed = 0;
    for (final item in order.items) {
      final id = item.productId;
      if (id == null) {
        failed++;
        continue;
      }
      try {
        if (item.variantId != null) {
          await notifier.setLineQuantity(id, item.quantity, variantId: item.variantId);
        } else {
          await notifier.setQuantity(id, item.quantity);
        }
        added++;
      } catch (_) {
        failed++;
      }
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(added > 0
          ? 'Added $added item${added == 1 ? '' : 's'} to cart'
              '${failed > 0 ? ' · $failed unavailable' : ''}'
          : 'Those items are no longer available in your store'),
    ));
    if (added > 0) ref.read(homeTabProvider.notifier).state = 3; // Cart tab
  }

  /// Pays an existing unpaid online order via Razorpay.
  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final checkout = await ref.read(orderRepositoryProvider).payRazorpay(order.id);
      final payment = await ref.read(razorpayServiceProvider).pay(checkout);
      await ref.read(orderRepositoryProvider).verifyRazorpayPayment(
            orderId: order.id,
            razorpayOrderId: payment.orderId,
            razorpayPaymentId: payment.paymentId,
            razorpaySignature: payment.signature,
          );
      ref.invalidate(ordersProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Payment successful')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paid = order.paymentStatus == 'PAID';
    final canPayOnline = order.paymentMethod == 'RAZORPAY' && !paid;
    const fulfilled = {'CONFIRMED', 'PACKED', 'SHIPPED', 'DELIVERED'};
    final hasInvoice = paid || fulfilled.contains(order.status);
    final s = _statusStyle(order.status);
    final itemCount = order.items.fold<int>(0, (n, i) => n + i.quantity);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header: status pill + date.
          Container(
            color: s.color.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(s.icon, size: 18, color: s.color),
                const SizedBox(width: 8),
                Text(s.label,
                    style: theme.textTheme.titleSmall?.copyWith(color: s.color, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  DateFormat('dd MMM, h:mm a').format(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$itemCount item${itemCount == 1 ? '' : 's'}',
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            _itemSummary(order),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(formatPaise(order.totalPaise),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(paid ? Icons.check_circle : Icons.schedule,
                        size: 14, color: paid ? const Color(0xFF1A7F37) : theme.colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      '${_method(order.paymentMethod)} · ${paid ? 'Paid' : order.paymentStatus.toLowerCase()}'
                      '${order.amountDuePaise > 0 ? ' · due ${formatPaise(order.amountDuePaise)}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (canPayOnline) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _pay(context, ref),
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: Text('Pay now · ${formatPaise(order.amountDuePaise)}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _reorder(context, ref),
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Reorder'),
                      ),
                    ),
                    if (hasInvoice) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => InvoiceScreen(order: order)),
                          ),
                          icon: const Icon(Icons.receipt_long_outlined, size: 18),
                          label: const Text('Invoice'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _method(String m) {
    switch (m) {
      case 'RAZORPAY':
        return 'Online';
      case 'BANK_TRANSFER':
        return 'Bank transfer';
      case 'CREDIT':
        return 'Credit';
      default:
        return m;
    }
  }

  /// A compact, variant-aware list of the order's items.
  static String _itemSummary(Order order) {
    if (order.items.isEmpty) return '';
    final parts = order.items.take(3).map((i) {
      final name = i.variantName != null ? '${i.productName} (${i.variantName})' : i.productName;
      return '$name ×${i.quantity}';
    }).toList();
    final extra = order.items.length - 3;
    return extra > 0 ? '${parts.join(', ')} +$extra more' : parts.join(', ');
  }
}
