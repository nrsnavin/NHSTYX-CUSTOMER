import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../orders/presentation/orders_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final checkout = ref.watch(checkoutControllerProvider);

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
          ..showSnackBar(
            SnackBar(content: Text('Order ${order.orderNumber} placed!')),
          );
      }
    });

    if (cart.isEmpty) {
      return const _EmptyCart();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cart.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = cart[index];
              return ListTile(
                title: Text(item.product.name),
                subtitle: Text(
                  '${item.variant.label} · ${formatCurrency(item.variant.price)} each',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => ref
                          .read(cartControllerProvider.notifier)
                          .setQuantity(item.variant.id, item.quantity - 1),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => ref
                          .read(cartControllerProvider.notifier)
                          .setQuantity(item.variant.id, item.quantity + 1),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      formatCurrency(subtotal),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: checkout.isLoading
                      ? null
                      : () => ref.read(checkoutControllerProvider.notifier).placeOrder(),
                  child: checkout.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Place order'),
                ),
              ],
            ),
          ),
        ),
      ],
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
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('Your cart is empty'),
        ],
      ),
    );
  }
}
