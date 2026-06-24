import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../cart/presentation/cart_controller.dart';
import '../domain/product.dart';

/// Compact storefront grid tile: image, name, price, MOQ, and a quick-add
/// control that morphs into a live quantity stepper once the item is in the
/// cart (Blinkit-style — the control itself is the feedback).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTiers = product.priceTiers.isNotEmpty;
    final outOfStock = !product.inStock;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductThumb(imageUrl: product.imageUrl),
                  if (outOfStock)
                    Positioned(top: 8, left: 8, child: _badge(context, 'Out of stock')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(formatPaise(product.fromPricePaise), style: theme.textTheme.titleMedium),
                      const SizedBox(width: 4),
                      Text('/ ${product.unit.toLowerCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                  if (hasTiers)
                    Text('Bulk pricing available',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text('MOQ ${product.moqQty}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ),
                      _QtyControl(product: product, enabled: !outOfStock),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Morphs between an outlined ADD button and a filled −/qty/+ stepper.
class _QtyControl extends ConsumerStatefulWidget {
  const _QtyControl({required this.product, required this.enabled});
  final Product product;
  final bool enabled;

  @override
  ConsumerState<_QtyControl> createState() => _QtyControlState();
}

class _QtyControlState extends ConsumerState<_QtyControl> {
  bool _busy = false;

  Product get _p => widget.product;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString()), duration: const Duration(seconds: 2)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _add() => _run(() => ref.read(cartControllerProvider.notifier).add(_p.id, _p.moqQty));

  void _inc(int qty) =>
      _run(() => ref.read(cartControllerProvider.notifier).setQuantity(_p.id, qty + 1));

  void _dec(int qty) => _run(() {
        // Stepping below the minimum order quantity removes the line.
        final next = qty - 1 < _p.moqQty ? 0 : qty - 1;
        return ref.read(cartControllerProvider.notifier).setQuantity(_p.id, next);
      });

  @override
  Widget build(BuildContext context) {
    final qty = ref.watch(cartQuantityProvider(_p.id));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: qty == 0
          ? _AddButton(key: const ValueKey('add'), enabled: widget.enabled, onAdd: _add)
          : _Stepper(
              key: const ValueKey('stepper'),
              qty: qty,
              busy: _busy,
              onDec: () => _dec(qty),
              onInc: () => _inc(qty),
            ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.enabled, required this.onAdd});
  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onAdd : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: enabled ? scheme.primary : scheme.outline),
          ),
          child: Text(
            'ADD',
            style: TextStyle(
              color: enabled ? scheme.primary : scheme.outline,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    super.key,
    required this.qty,
    required this.busy,
    required this.onDec,
    required this.onInc,
  });
  final int qty;
  final bool busy;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: busy ? null : onDec),
          SizedBox(
            width: 24,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: busy ? null : onInc),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        child: Icon(icon, size: 18, color: scheme.onPrimary),
      ),
    );
  }
}
