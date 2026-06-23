import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../cart/presentation/cart_controller.dart';
import '../domain/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late int _qty = widget.product.moqQty;
  bool _adding = false;

  Product get _p => widget.product;

  void _setQty(int next) {
    final clamped = next.clamp(_p.moqQty, _p.stockQty == 0 ? _p.moqQty : _p.stockQty);
    setState(() => _qty = clamped);
  }

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(_p.id, _qty);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Added ${_p.name} to cart')));
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
    final unitPrice = _p.unitPricePaiseFor(_qty);
    final lineTotal = unitPrice * _qty;

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: ListView(
        children: [
          AspectRatio(aspectRatio: 1, child: ProductThumb(imageUrl: _p.imageUrl)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_p.categoryName != null || _p.brand != null)
                  Text(
                    [_p.brand, _p.categoryName].where((e) => e != null).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                const SizedBox(height: 4),
                Text(_p.name, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(formatPaise(unitPrice), style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26)),
                    const SizedBox(width: 6),
                    Text('/ ${_p.unit.toLowerCase()}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                    const SizedBox(width: 10),
                    if (_p.mrpPaise != null && _p.mrpPaise! > unitPrice)
                      Text(
                        formatPaise(_p.mrpPaise!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Excl. ${_p.gstRatePercent}% GST', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 16),
                _InfoRow(label: 'Minimum order', value: '${_p.moqQty} ${_p.unit.toLowerCase()}'),
                _InfoRow(
                  label: 'Availability',
                  value: _p.inStock ? '${_p.stockQty} in stock' : 'Out of stock',
                ),
                if (_p.hsnCode != null) _InfoRow(label: 'HSN', value: _p.hsnCode!),
                if (_p.priceTiers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Bulk pricing', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _TierTable(product: _p, currentQty: _qty),
                ],
                if ((_p.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Description', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(_p.description!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        product: _p,
        qty: _qty,
        lineTotalPaise: lineTotal,
        adding: _adding,
        onDec: () => _setQty(_qty - 1),
        onInc: () => _setQty(_qty + 1),
        onAdd: _p.inStock && !_adding ? _add : null,
      ),
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
    required this.product,
    required this.qty,
    required this.lineTotalPaise,
    required this.adding,
    required this.onDec,
    required this.onInc,
    required this.onAdd,
  });

  final Product product;
  final int qty;
  final int lineTotalPaise;
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
                      : Text('Add • ${formatPaise(lineTotalPaise)}'),
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
