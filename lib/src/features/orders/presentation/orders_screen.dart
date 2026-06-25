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
      appBar: AppBar(title: const Text('Orders')),
      body: AsyncValueView<List<Order>>(
        value: ordersAsync,
        onRetry: () => ref.invalidate(ordersProvider),
        loading: () => const ListCardSkeleton(height: 150),
        data: (orders) {
          if (orders.isEmpty) {
            return const _NoOrders();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
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
        await notifier.setQuantity(id, item.quantity);
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

  /// Pays an existing unpaid online order via Razorpay (e.g. an agent-placed
  /// order): fetch a fresh checkout, open Razorpay, verify, then refresh.
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
                Chip(
                  label: Text(order.status, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            Text(
              DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 20),
            _row(context, 'Items', '${order.items.length}'),
            _row(context, 'Subtotal', formatPaise(order.subtotalPaise)),
            if (order.taxPaise > 0) _row(context, 'GST', formatPaise(order.taxPaise)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium),
                Text(
                  formatPaise(order.totalPaise),
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  paid ? Icons.check_circle : Icons.schedule,
                  size: 16,
                  color: paid ? Colors.green : theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  '${order.paymentMethod} · ${order.paymentStatus}'
                  '${order.amountDuePaise > 0 ? ' · due ${formatPaise(order.amountDuePaise)}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            // An unpaid online order (e.g. placed by an agent) can be paid here.
            if (canPayOnline) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _pay(context, ref),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text('Pay now · ${formatPaise(order.amountDuePaise)}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _reorder(context, ref),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Reorder'),
                  ),
                ),
                // Invoice is available once payment is confirmed.
                if (paid) ...[
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
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
