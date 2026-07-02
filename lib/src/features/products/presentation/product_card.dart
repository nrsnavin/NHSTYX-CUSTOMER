import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../../shared/widgets/quantity_sheet.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../wishlist/presentation/wishlist_controller.dart';
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
    final discount = product.discountPercent;

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
                    Positioned(top: 8, left: 8, child: _badge(context, 'Out of stock'))
                  else if (discount != null)
                    Positioned(top: 8, left: 8, child: _discountBadge(context, discount)),
                  Positioned(top: 6, right: 6, child: _WishlistHeart(productId: product.id)),
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
                  if (product.hasRatings) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5A623)),
                        const SizedBox(width: 2),
                        Text(
                          product.ratingAvg.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Text('(${product.ratingCount})',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(formatPaise(product.fromPricePaise), style: theme.textTheme.titleMedium),
                      const SizedBox(width: 4),
                      // Selling price + struck-through MRP when there's a saving,
                      // otherwise the per-unit suffix.
                      if (discount != null)
                        Flexible(
                          child: Text(
                            formatPaise(product.mrpPaise!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        )
                      else
                        Text('/ ${product.unit.toLowerCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                  if (discount != null)
                    Text('per ${product.unit.toLowerCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
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
                      // Variant products are added from the detail page (pick an
                      // option first); others use the inline quick-add stepper.
                      if (product.hasVariants)
                        _SelectButton(onTap: onTap)
                      else
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

  /// Green savings ribbon shown on the image corner, e.g. "20% OFF".
  Widget _discountBadge(BuildContext context, int percent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A7F37), // savings green
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$percent% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Heart overlay that saves/removes the product from the wishlist. Reads the
/// shared id set so it reflects (and toggles) state instantly across screens.
class _WishlistHeart extends ConsumerWidget {
  const _WishlistHeart({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(wishlistIdsProvider).valueOrNull?.contains(productId) ?? false;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: saved ? 'Remove from wishlist' : 'Add to wishlist',
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            Haptics.tap();
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(wishlistIdsProvider.notifier).toggle(productId);
            } catch (e) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          // Small glyph, but a finger-friendly 40dp hit area.
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            alignment: Alignment.center,
            child: Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: saved ? Colors.red : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Select" affordance for variant products — opens the detail page where the
/// shopper picks an option (size/colour) before adding.
class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary),
          ),
          child: Text(
            'SELECT',
            style: TextStyle(
              color: scheme.primary,
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

  void _add() {
    Haptics.success();
    _run(() => ref.read(cartControllerProvider.notifier).add(_p, _p.moqQty));
  }

  void _inc(int qty) {
    // Preventive, not reactive: never let the shopper step past what's in stock.
    if (qty >= _p.stockQty) {
      Haptics.error();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Only ${_p.stockQty} ${_p.unit.toLowerCase()}(s) in stock'),
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    Haptics.tap();
    _run(() => ref.read(cartControllerProvider.notifier).setQuantity(_p.id, qty + 1));
  }

  void _dec(int qty) {
    Haptics.tap();
    _run(() {
      // Stepping below the minimum order quantity removes the line.
      final next = qty - 1 < _p.moqQty ? 0 : qty - 1;
      return ref.read(cartControllerProvider.notifier).setQuantity(_p.id, next);
    });
  }

  Future<void> _editQty(int qty) async {
    final chosen = await showQuantitySheet(
      context,
      current: qty,
      moq: _p.moqQty,
      stock: _p.stockQty,
      unit: _p.unit,
      name: _p.name,
    );
    if (chosen == null) return; // cancelled
    _run(() => ref.read(cartControllerProvider.notifier).setQuantity(_p.id, chosen));
  }

  @override
  Widget build(BuildContext context) {
    final qty = ref.watch(cartQuantityProvider(_p.id));
    final atMax = qty >= _p.stockQty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: qty == 0
          ? _AddButton(key: const ValueKey('add'), enabled: widget.enabled, onAdd: _add)
          : _Stepper(
              key: const ValueKey('stepper'),
              qty: qty,
              busy: _busy,
              atMax: atMax,
              onDec: () => _dec(qty),
              onInc: () => _inc(qty),
              onEdit: () => _editQty(qty),
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
    required this.atMax,
    required this.onDec,
    required this.onInc,
    required this.onEdit,
  });
  final int qty;
  final bool busy;
  final bool atMax;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onEdit;

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
          _StepBtn(
            icon: Icons.remove,
            label: 'Decrease quantity',
            onTap: busy ? null : onDec,
          ),
          // Tap the number to type a bulk quantity directly (B2B shoppers order
          // in dozens/hundreds — stepping one at a time isn't viable).
          Semantics(
            button: true,
            label: 'Edit quantity, currently $qty',
            child: InkWell(
              onTap: busy ? null : onEdit,
              child: Container(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 44),
                alignment: Alignment.center,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            label: 'Increase quantity',
            // Dim (not disabled) at max so the tap still fires the "only N in
            // stock" feedback instead of doing nothing silently.
            dimmed: atMax,
            onTap: busy ? null : onInc,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.label, required this.onTap, this.dimmed = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        // 44dp minimum touch target (WCAG 2.5.5 / Material) without inflating
        // the visual size of the pill.
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: scheme.onPrimary.withValues(alpha: dimmed ? 0.45 : 1),
          ),
        ),
      ),
    );
  }
}
