import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';
import 'orders_controller.dart';

/// Opens the "request a return" flow for an order. Returns true on success.
Future<bool?> showRequestReturnSheet(BuildContext context, Order order) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RequestReturnSheet(order: order),
  );
}

class _RequestReturnSheet extends ConsumerStatefulWidget {
  const _RequestReturnSheet({required this.order});
  final Order order;

  @override
  ConsumerState<_RequestReturnSheet> createState() => _RequestReturnSheetState();
}

class _RequestReturnSheetState extends ConsumerState<_RequestReturnSheet> {
  // orderItemId → quantity to return (0 = not selected).
  final Map<String, int> _qty = {};
  final _reason = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  List<OrderItem> get _returnable =>
      widget.order.items.where((i) => (i.id ?? '').isNotEmpty).toList();

  bool get _anySelected => _qty.values.any((q) => q > 0);

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(orderRepositoryProvider).requestReturn(
            orderId: widget.order.id,
            items: _qty,
            reason: _reason.text.trim(),
          );
      ref.invalidate(ordersProvider);
      navigator.pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Return requested — we\'ll review it shortly')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Request a return',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text('Order ${widget.order.orderNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final it in _returnable) _line(it),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reason,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g. damaged, wrong size',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_anySelected && !_submitting) ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit return request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(OrderItem it) {
    final theme = Theme.of(context);
    final id = it.id!;
    final selected = (_qty[id] ?? 0) > 0;
    final qty = _qty[id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() => _qty[id] = v == true ? it.quantity : 0),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.variantName != null ? '${it.productName} · ${it.variantName}' : it.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text('Ordered ${it.quantity} · ${formatPaise(it.lineTotalPaise)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
          if (selected)
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: qty > 1 ? () => setState(() => _qty[id] = qty - 1) : null,
                ),
                Text('$qty'),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: qty < it.quantity ? () => setState(() => _qty[id] = qty + 1) : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
