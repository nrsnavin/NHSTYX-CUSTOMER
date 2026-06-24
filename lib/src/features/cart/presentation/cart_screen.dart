import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../addresses/presentation/address_controller.dart';
import '../../addresses/presentation/add_address_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../orders/presentation/orders_controller.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

/// Selected payment method for checkout. COD is not offered.
final selectedPaymentProvider = StateProvider.autoDispose<String>((ref) => 'RAZORPAY');

class _Method {
  const _Method(this.code, this.label, this.sub, this.icon);
  final String code;
  final String label;
  final String sub;
  final IconData icon;
}

const _methods = [
  _Method('RAZORPAY', 'Pay online', 'UPI · Card · Netbanking', Icons.bolt_outlined),
  _Method('CREDIT', 'Credit (pay later)', 'On your approved credit limit', Icons.account_balance_wallet_outlined),
  _Method('BANK_TRANSFER', 'Bank transfer', 'NEFT / IMPS — add your reference', Icons.account_balance_outlined),
];

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _changeQty(BuildContext context, WidgetRef ref, String productId, int qty) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cartControllerProvider.notifier).setQuantity(productId, qty);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartControllerProvider);

    ref.listen(checkoutControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
      final order = next.valueOrNull;
      if (order != null && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Order ${order.orderNumber} placed!')));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: AsyncValueView<Cart>(
        value: cartAsync,
        onRetry: () => ref.invalidate(cartControllerProvider),
        loading: () => const ListCardSkeleton(itemCount: 4, height: 64),
        data: (cart) {
          if (cart.isEmpty) return const _EmptyCart();
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: Text(
                        '${formatPaise(item.unitPricePaise)} / ${item.unit.toLowerCase()} · '
                        '${formatPaise(item.lineSubtotalPaise)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                _changeQty(context, ref, item.productId, item.quantity - 1),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                _changeQty(context, ref, item.productId, item.quantity + 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _CheckoutPanel(subtotalPaise: cart.subtotalPaise),
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutPanel extends ConsumerStatefulWidget {
  const _CheckoutPanel({required this.subtotalPaise});
  final int subtotalPaise;

  @override
  ConsumerState<_CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends ConsumerState<_CheckoutPanel> {
  final _bankRef = TextEditingController();

  @override
  void dispose() {
    _bankRef.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = ref.watch(defaultAddressProvider);
    final method = ref.watch(selectedPaymentProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final customer = ref.watch(authControllerProvider).valueOrNull;

    final creditApproved = customer?.creditApproved ?? false;
    final creditLimit = customer?.creditLimitPaise ?? 0;
    final bankRefMissing = method == 'BANK_TRANSFER' && _bankRef.text.trim().isEmpty;
    final creditBlocked = method == 'CREDIT' && !creditApproved;
    final canPlace = address != null && !checkout.isLoading && !bankRefMissing && !creditBlocked;

    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Delivery address
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(address == null ? 'Add a delivery address' : 'Deliver to'),
                subtitle: Text(address?.summary ?? 'Required to place your order'),
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                  ),
                  child: Text(address == null ? 'Add' : 'Change'),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Payment method', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              for (final m in _methods)
                _PaymentTile(
                  method: m,
                  selected: method == m.code,
                  enabled: m.code != 'CREDIT' || creditApproved,
                  trailing: m.code == 'CREDIT' && creditApproved
                      ? 'up to ${formatPaise(creditLimit)}'
                      : m.code == 'CREDIT'
                          ? 'Not approved'
                          : null,
                  onTap: () => ref.read(selectedPaymentProvider.notifier).state = m.code,
                ),
              if (method == 'BANK_TRANSFER') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _bankRef,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Transfer reference (UTR / txn id)',
                    helperText: 'Enter the reference after you transfer; we verify and confirm.',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ],
              if (creditBlocked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Credit isn\'t approved for your shop yet.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal (excl. GST)', style: theme.textTheme.titleMedium),
                  Text(formatPaise(widget.subtotalPaise), style: theme.textTheme.titleLarge),
                ],
              ),
              Text('GST is added at checkout based on your delivery state.',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: canPlace
                    ? () => ref.read(checkoutControllerProvider.notifier).placeOrder(
                          addressId: address.id,
                          paymentMethod: method,
                          bankReference: method == 'BANK_TRANSFER' ? _bankRef.text.trim() : null,
                        )
                    : null,
                child: checkout.isLoading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Place order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.trailing,
  });

  final _Method method;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(method.icon, size: 22, color: selected ? scheme.primary : scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(method.sub,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('Your cart is empty'),
        ],
      ),
    );
  }
}
