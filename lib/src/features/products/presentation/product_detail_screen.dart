import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../cart/presentation/cart_controller.dart';
import '../domain/product.dart';
import 'products_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late int _qty = widget.product.moqQty;
  bool _adding = false;
  String? _selectedVariantId;

  /// The chosen variant for a variant product (defaults to the first in-stock).
  ProductVariant? _variant(Product p) {
    if (!p.hasVariants || p.variants.isEmpty) return null;
    final byId = _selectedVariantId == null
        ? null
        : p.variants.where((v) => v.id == _selectedVariantId).firstOrNull;
    return byId ??
        p.variants.where((v) => v.inStock).firstOrNull ??
        p.variants.first;
  }

  void _setQty(int next, int stock) {
    final clamped = next.clamp(widget.product.moqQty, stock == 0 ? widget.product.moqQty : stock);
    setState(() => _qty = clamped);
  }

  Future<void> _add(Product p, ProductVariant? variant) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = true);
    try {
      if (variant != null) {
        await ref.read(cartControllerProvider.notifier).addVariant(p.id, variant.id, _qty);
      } else {
        await ref.read(cartControllerProvider.notifier).add(p, _qty);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('Added ${p.name}${variant != null ? ' (${variant.name})' : ''} to cart')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Full detail (incl. variants) — fall back to the list product while loading.
    final p = ref.watch(productDetailProvider(widget.product.id)).valueOrNull ?? widget.product;
    final variant = _variant(p);

    // Effective price / stock come from the chosen variant when there is one.
    final unitPrice = variant?.pricePaise ?? p.unitPricePaiseFor(_qty);
    final stock = variant?.stockQty ?? p.stockQty;
    final mrp = variant?.mrpPaise ?? p.mrpPaise;
    final inStock = variant != null ? variant.inStock : p.inStock;
    final canAdd = inStock && !_adding && !(p.hasVariants && p.variants.isEmpty);
    final lineTotal = unitPrice * _qty;

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProductThumb(imageUrl: variant?.imageUrl ?? p.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.categoryName != null || p.brand != null)
                  Text(
                    [p.brand, p.categoryName].where((e) => e != null).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                const SizedBox(height: 4),
                Text(p.name, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(formatPaise(unitPrice), style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26)),
                    const SizedBox(width: 6),
                    Text('/ ${p.unit.toLowerCase()}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                    const SizedBox(width: 10),
                    if (mrp != null && mrp > unitPrice)
                      Text(
                        formatPaise(mrp),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Excl. ${p.gstRatePercent}% GST', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                if (p.hasVariants) ...[
                  const SizedBox(height: 18),
                  Text('Options', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (p.variants.isEmpty)
                    Text('No options available in your store yet',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor))
                  else
                    _VariantSelector(
                      variants: p.variants,
                      selectedId: variant?.id,
                      onSelect: (v) => setState(() {
                        _selectedVariantId = v.id;
                        _qty = p.moqQty;
                      }),
                    ),
                ],
                const SizedBox(height: 16),
                _InfoRow(label: 'Minimum order', value: '${p.moqQty} ${p.unit.toLowerCase()}'),
                _InfoRow(label: 'Availability', value: inStock ? '$stock in stock' : 'Out of stock'),
                if (p.hsnCode != null) _InfoRow(label: 'HSN', value: p.hsnCode!),
                if (!p.hasVariants && p.priceTiers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Bulk pricing', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _TierTable(product: p, currentQty: _qty),
                ],
                if ((p.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Description', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(p.description!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        priceLabel: formatPaise(lineTotal),
        qty: _qty,
        adding: _adding,
        onDec: () => _setQty(_qty - 1, stock),
        onInc: () => _setQty(_qty + 1, stock),
        onAdd: canAdd ? () => _add(p, variant) : null,
      ),
    );
  }
}

/// Choice chips for a product's variants, disabling out-of-stock options.
class _VariantSelector extends StatelessWidget {
  const _VariantSelector({required this.variants, required this.selectedId, required this.onSelect});

  final List<ProductVariant> variants;
  final String? selectedId;
  final void Function(ProductVariant) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in variants)
          ChoiceChip(
            label: Text(v.inStock ? v.name : '${v.name} · out'),
            selected: v.id == selectedId,
            onSelected: v.inStock ? (_) => onSelect(v) : null,
            labelStyle: TextStyle(
              color: !v.inStock
                  ? theme.disabledColor
                  : v.id == selectedId
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
              fontWeight: v.id == selectedId ? FontWeight.w700 : FontWeight.w500,
            ),
            selectedColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _TierTable extends StatelessWidget {
  const _TierTable({required this.product, required this.currentQty});
  final Product product;
  final int currentQty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[
      _row(context, 'From ${product.moqQty}', formatPaise(product.pricePaise),
          active: currentQty < (product.priceTiers.first.minQty)),
    ];
    for (var i = 0; i < product.priceTiers.length; i++) {
      final t = product.priceTiers[i];
      final upper = i + 1 < product.priceTiers.length ? product.priceTiers[i + 1].minQty : null;
      final active = currentQty >= t.minQty && (upper == null || currentQty < upper);
      rows.add(_row(context, '${t.minQty}+', formatPaise(t.pricePaise), active: active));
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(BuildContext context, String qty, String price, {required bool active}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      color: active ? theme.colorScheme.secondaryContainer : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$qty ${active ? '• applied' : ''}'.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
          Text(price, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.priceLabel,
    required this.qty,
    required this.adding,
    required this.onDec,
    required this.onInc,
    required this.onAdd,
  });

  final String priceLabel;
  final int qty;
  final bool adding;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              _Stepper(qty: qty, onDec: onDec, onInc: onInc),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  child: adding
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Add • $priceLabel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.qty, required this.onDec, required this.onInc});
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onDec, icon: const Icon(Icons.remove), visualDensity: VisualDensity.compact),
          Text('$qty', style: theme.textTheme.titleMedium),
          IconButton(onPressed: onInc, icon: const Icon(Icons.add), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}
