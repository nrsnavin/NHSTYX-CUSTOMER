import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/formatters.dart';
import '../data/order_repository.dart';
import '../data/razorpay_service.dart';
import '../domain/order.dart';
import '../domain/order_tracking.dart';
import 'invoice_screen.dart';
import 'orders_controller.dart';
import 'request_return_sheet.dart';

/// Full details for one order: status, a live shipment timeline, items, the
/// price breakdown, payment, and the invoice / pay / return actions.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  ({Color color, IconData icon, String label}) _statusStyle(String s) {
    switch (s) {
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
      case 'RETURNED':
        return (color: const Color(0xFF9A3412), icon: Icons.assignment_return, label: 'Returned');
      default:
        return (color: const Color(0xFF9A6700), icon: Icons.schedule, label: 'Pending');
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
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
      ref.invalidate(orderTrackingProvider(order.id));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Payment successful')));
      navigator.pop();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = _statusStyle(order.status);
    final paid = order.paymentStatus == 'PAID';
    final canPayOnline = order.paymentMethod == 'RAZORPAY' && !paid;
    const fulfilled = {'CONFIRMED', 'PACKED', 'SHIPPED', 'DELIVERED'};
    final hasInvoice = paid || fulfilled.contains(order.status);
    final trackingAsync = ref.watch(orderTrackingProvider(order.id));

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(orderTrackingProvider(order.id)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(s.icon, color: s.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: s.color, fontWeight: FontWeight.w700)),
                        Text('Placed ${DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipment tracking
            trackingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (t) => _TrackingSection(tracking: t),
            ),

            const _SectionTitle('Items'),
            ...order.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          it.variantName != null
                              ? '${it.productName} · ${it.variantName}'
                              : it.productName,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text('×${it.quantity}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      const SizedBox(width: 12),
                      Text(formatPaise(it.lineTotalPaise), style: theme.textTheme.titleSmall),
                    ],
                  ),
                )),

            const SizedBox(height: 8),
            const Divider(),
            _amountRow(context, 'Subtotal (excl. GST)', order.subtotalPaise),
            if (order.taxPaise > 0) _amountRow(context, 'GST', order.taxPaise),
            _amountRow(context, 'Total', order.totalPaise, strong: true),
            if (order.amountDuePaise > 0)
              _amountRow(context, 'Amount due', order.amountDuePaise, color: theme.colorScheme.error),

            const SizedBox(height: 8),
            Row(
              children: [
                Icon(paid ? Icons.check_circle : Icons.schedule,
                    size: 16, color: paid ? const Color(0xFF1A7F37) : theme.colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  '${_method(order.paymentMethod)} · ${paid ? 'Paid' : order.paymentStatus.toLowerCase()}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (canPayOnline)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.icon(
                  onPressed: () => _pay(context, ref),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text('Pay now · ${formatPaise(order.amountDuePaise)}'),
                ),
              ),
            if (hasInvoice)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InvoiceScreen(order: order)),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('View invoice'),
              ),
            if (order.isReturnable) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => showRequestReturnSheet(context, order),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('Request a return'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(BuildContext context, String label, int paise,
      {bool strong = false, Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: (strong ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
                  ?.copyWith(color: color)),
          Text(formatPaise(paise),
              style: (strong ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
                  ?.copyWith(color: color, fontWeight: strong ? FontWeight.w700 : null)),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// Courier + AWB + a checkpoint timeline. Hidden until the order has shipment
/// info; shows "Live" when the status came from the courier's API.
class _TrackingSection extends StatelessWidget {
  const _TrackingSection({required this.tracking});
  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!tracking.hasTracking && tracking.checkpoints.length <= 1) {
      return const SizedBox.shrink();
    }
    final url = tracking.trackingUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle('Shipment'),
            const Spacer(),
            if (tracking.live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A7F37).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Live',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A7F37))),
              ),
          ],
        ),
        if (tracking.hasTracking)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B6BCB).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF0B6BCB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if ((tracking.courierName ?? '').isNotEmpty) tracking.courierName!,
                      if ((tracking.trackingNumber ?? '').isNotEmpty) 'AWB ${tracking.trackingNumber}',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (url != null && url.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Track'),
                  ),
              ],
            ),
          ),
        // Timeline (newest at the bottom, matching event order).
        for (var i = 0; i < tracking.checkpoints.length; i++)
          _TimelineTile(
            checkpoint: tracking.checkpoints[i],
            isFirst: i == 0,
            isLast: i == tracking.checkpoints.length - 1,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.checkpoint, required this.isFirst, required this.isLast});
  final TrackingCheckpoint checkpoint;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLast ? theme.colorScheme.primary : theme.colorScheme.outline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: theme.colorScheme.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(checkpoint.status),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    DateFormat('dd MMM, h:mm a').format(checkpoint.at) +
                        ((checkpoint.location ?? '').isNotEmpty ? ' · ${checkpoint.location}' : ''),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                  if ((checkpoint.note ?? '').isNotEmpty)
                    Text(checkpoint.note!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(String status) {
    switch (status) {
      case 'PENDING':
        return 'Order placed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PACKED':
        return 'Packed';
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'RETURNED':
        return 'Returned';
      default:
        return status[0] + status.substring(1).toLowerCase().replaceAll('_', ' ');
    }
  }
}
