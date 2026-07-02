import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/bundle_repository.dart';
import '../domain/bundle.dart';
import 'bundles_controller.dart';

/// Curated kits the shop can add to their cart in one tap.
class BundlesScreen extends ConsumerWidget {
  const BundlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundlesAsync = ref.watch(bundlesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kits & bundles')),
      body: AsyncValueView<List<Bundle>>(
        value: bundlesAsync,
        onRetry: () => ref.invalidate(bundlesProvider),
        loading: () => const ListCardSkeleton(itemCount: 3, height: 180),
        data: (bundles) {
          if (bundles.isEmpty) {
            return const EmptyState(
              icon: Icons.widgets_outlined,
              title: 'No kits yet',
              message: 'Curated bundles from your store will show up here — add them to your cart in one tap.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bundlesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bundles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _BundleCard(bundle: bundles[i]),
            ),
          );
        },
      ),
    );
  }
}

class _BundleCard extends ConsumerStatefulWidget {
  const _BundleCard({required this.bundle});
  final Bundle bundle;

  @override
  ConsumerState<_BundleCard> createState() => _BundleCardState();
}

class _BundleCardState extends ConsumerState<_BundleCard> {
  bool _adding = false;

  Future<void> _add() async {
    setState(() => _adding = true);
    try {
      await ref.read(bundleRepositoryProvider).addToCart(widget.bundle.id);
      ref.invalidate(cartControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.bundle.name} added to cart')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.bundle;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: ProductThumb(imageUrl: b.imageUrl, icon: Icons.widgets_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: theme.textTheme.titleMedium),
                      if ((b.description ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            b.description!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final it in b.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${it.name}  × ${it.quantity}',
                        style: TextStyle(
                          color: it.available ? null : theme.colorScheme.error,
                        ),
                      ),
                    ),
                    Text(
                      it.lineTotalPaise != null ? formatPaise(it.lineTotalPaise!) : '—',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bundle total', style: theme.textTheme.bodyMedium),
                Text(
                  formatPaise(b.totalPaise),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!b.allAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Some items are out of stock at your store.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (b.allAvailable && !_adding) ? _add : null,
                icon: _adding
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart_outlined),
                label: Text(_adding ? 'Adding…' : 'Add kit to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
