import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../haptics.dart';

/// Bottom sheet for entering a bulk quantity directly — the wholesale buyer's
/// core action. Tapping +/− 100 times is a non-starter, so this lets them type
/// a number, jump by pack multiples, and see min-order / stock limits inline.
///
/// Returns the chosen quantity (>= moq), 0 to remove the line, or null on
/// cancel. Enforces `moq <= qty <= stock`.
Future<int?> showQuantitySheet(
  BuildContext context, {
  required int current,
  required int moq,
  required int stock,
  required String unit,
  String? name,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _QuantitySheet(current: current, moq: moq, stock: stock, unit: unit, name: name),
  );
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({
    required this.current,
    required this.moq,
    required this.stock,
    required this.unit,
    this.name,
  });

  final int current;
  final int moq;
  final int stock;
  final String unit;
  final String? name;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final TextEditingController _c =
      TextEditingController(text: '${widget.current > 0 ? widget.current : widget.moq}');

  int get _qty => int.tryParse(_c.text.trim()) ?? 0;
  String get _unit => widget.unit.toLowerCase();

  String? get _error {
    final q = _qty;
    if (q == 0) return null; // 0 = remove, allowed
    if (q < widget.moq) return 'Minimum order is ${widget.moq} $_unit';
    if (q > widget.stock) return 'Only ${widget.stock} $_unit in stock';
    return null;
  }

  void _bump(int by) {
    final next = (_qty + by).clamp(0, widget.stock);
    _c.text = '$next';
    Haptics.tap();
    setState(() {});
  }

  void _set(int v) {
    _c.text = '$v';
    Haptics.tap();
    setState(() {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _error == null;
    // Handy pack jumps a wholesaler actually uses.
    final quicks = <int>{widget.moq, widget.moq * 2, 12, 24, 50, 100}
        .where((q) => q >= widget.moq && q <= widget.stock)
        .toList()
      ..sort();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.name != null)
            Text(widget.name!, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('Min ${widget.moq} · ${widget.stock} in stock',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 16),
          Row(
            children: [
              _RoundBtn(icon: Icons.remove, onTap: () => _bump(-1)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    suffixText: _unit,
                    errorText: _error,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              _RoundBtn(icon: Icons.add, onTap: () => _bump(1)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in quicks)
                ActionChip(label: Text('$q'), onPressed: () => _set(q)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.current > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Haptics.tap();
                      Navigator.of(context).pop(0);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                  ),
                ),
              if (widget.current > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: valid && _qty > 0
                      ? () {
                          Haptics.success();
                          Navigator.of(context).pop(_qty);
                        }
                      : null,
                  child: Text(widget.current > 0 ? 'Update' : 'Add ${_qty > 0 ? _qty : widget.moq}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: scheme.onSurface),
        ),
      ),
    );
  }
}
