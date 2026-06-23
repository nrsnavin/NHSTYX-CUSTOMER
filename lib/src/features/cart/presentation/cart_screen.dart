import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../addresses/presentation/address_controller.dart';
import '../../addresses/presentation/add_address_screen.dart';
import '../../orders/presentation/orders_controller.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

/// Selected payment method for checkout (in-app methods; Razorpay handled later).
final selectedPaymentProvider = StateProvider.autoDispose<String>((ref) => 'COD');

const _paymentLabels = {
  'COD': 'Cash on Delivery',
  'CREDIT': 'Credit (Pay Later)',
  'BANK_TRANSFER': 'Bank Transfer',
};

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

class _CheckoutPanel extends ConsumerWidget {
  const _CheckoutPanel({required this.subtotalPaise});

  final int subtotalPaise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(defaultAddressProvider);
    final method = ref.watch(selectedPaymentProvider);
    final checkout = ref.watch(checkoutControllerProvider);

    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
              // Payment method
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Payment', style: Theme.of(context).textTheme.labelLarge),
              ),
              Wrap(
                spacing: 8,
                children: _paymentLabels.entries
                    .map((e) => ChoiceChip(
                          label: Text(e.value),
                          selected: method == e.key,
                          onSelected: (_) =>
                              ref.read(selectedPaymentProvider.notifier).state = e.key,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal (excl. GST)', style: Theme.of(context).textTheme.titleMedium),
                  Text(formatPaise(subtotalPaise),
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              Text(
                'GST is calculated at checkout based on your delivery state.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (address == null || checkout.isLoading)
                    ? null
                    : () => ref.read(checkoutControllerProvider.notifier).placeOrder(
                          addressId: address.id,
                          paymentMethod: method,
                        ),
                child: checkout.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Place order · ${_paymentLabels[method]}'),
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
