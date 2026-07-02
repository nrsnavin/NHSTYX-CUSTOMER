import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/haptics.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/order.dart';
import 'order_detail_screen.dart';

/// Celebratory confirmation shown right after checkout succeeds — the peak of
/// the funnel. A springy check-mark, the order number, what's left to pay, and
/// two clear next steps (track it / keep shopping) so the moment lands.
class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // A weighty buzz to mark the win.
    Haptics.heavy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final order = widget.order;
    final paid = order.paymentStatus == 'PAID' || order.amountDuePaise == 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            children: [
              const Spacer(),
              // Springy check-mark.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 620),
                curve: Curves.elasticOut,
                builder: (context, t, child) => Transform.scale(scale: t, child: child),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 64, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 28),
              Text('Order placed!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Thanks — your store order is confirmed and on its way to being packed.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 24),
              _SummaryCard(order: order, paid: paid),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // Land on the Orders tab underneath, then open this order.
                    ref.read(homeTabProvider.notifier).state = 2;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                    );
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Track your order'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(homeTabProvider.notifier).state = 0;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Continue shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order, required this.paid});

  final Order order;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row(theme, 'Order number', order.orderNumber, emphasise: true),
          const SizedBox(height: 10),
          _row(theme, 'Order total', formatPaise(order.totalPaise)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
              Row(
                children: [
                  Icon(paid ? Icons.check_circle : Icons.schedule,
                      size: 16, color: paid ? Colors.green.shade600 : scheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    paid ? 'Paid in full' : '${formatPaise(order.amountDuePaise)} due',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: paid ? Colors.green.shade700 : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value, {bool emphasise = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        Text(
          value,
          style: emphasise
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
              : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
