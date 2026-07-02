import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../../shared/widgets/quantity_sheet.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../addresses/presentation/address_controller.dart';
import '../../addresses/presentation/add_address_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../coupons/data/coupon_repository.dart';
import '../../orders/presentation/orders_controller.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

/// Selected payment method for checkout. COD is not offered.
final selectedPaymentProvider =
    StateProvider.autoDispose<String>((ref) => 'RAZORPAY');

class _Method {
  const _Method(this.code, this.label, this.sub, this.icon);
  final String code;
  final String label;
  final String sub;
  final IconData icon;
}

const _methods = [
  _Method(
      'RAZORPAY', 'Pay online', 'UPI · Card · Netbanking', Icons.bolt_outlined),
  _Method('CREDIT', 'Credit (pay later)', 'On your approved credit limit',
      Icons.account_balance_wallet_outlined),
  _Method('BANK_TRANSFER', 'Bank transfer', 'NEFT / IMPS — add your reference',
      Icons.account_balance_outlined),
];

/// The cart screen. Cart lines + the full checkout form scroll together in the
/// body; only a compact, intrinsically-sized total + "Place order" bar is
/// pinned in the bottomNavigationBar. (A scrollable/fractional-height panel in
/// the bottom slot has no determinable size under the home shell's IndexedStack
/// and triggers a `hasSize` paint assertion — so we keep the pinned bar simple.)
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _bankRef = TextEditingController();
  final _coupon = TextEditingController();
  bool _applyingCoupon = false;

  @override
  void dispose() {
    _bankRef.dispose();
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _changeQty(CartLine line, int qty) async {
    final messenger = ScaffoldMessenger.of(context);
    // Below the minimum order quantity there is no valid line — the − button
    // at the MOQ removes the item (otherwise a below-MOQ line lingers in the
    // cart and only fails later, at checkout).
    if (qty > 0 && qty < line.moqQty) qty = 0;
    final removing = qty <= 0;
    // The line vanishes optimistically, so confirm the removal right away —
    // don't leave the shop guessing while the server round-trip completes.
    if (removing) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Removed ${line.name}${line.variantName != null ? ' (${line.variantName})' : ''} from cart'),
          duration: const Duration(seconds: 2),
        ));
    }
    try {
      // Variant-aware: targets the exact (product, variant) line.
      await ref
          .read(cartControllerProvider.notifier)
          .setLineQuantity(line.productId, qty, variantId: line.variantId);
      // The cart total changed, so any applied coupon's discount is now stale —
      // drop it and let the customer re-apply against the new total.
      ref.read(appliedCouponProvider.notifier).state = null;
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            removing ? 'Could not remove ${line.name} — restored. ${e.toString()}' : e.toString(),
          ),
        ));
    }
  }

  Future<void> _editLineQty(CartLine item) async {
    final chosen = await showQuantitySheet(
      context,
      current: item.quantity,
      moq: item.moqQty,
      stock: item.stockQty,
      unit: item.unit,
      name: item.name,
    );
    if (chosen == null) return;
    await _changeQty(item, chosen);
  }

  Future<void> _applyCoupon() async {
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _applyingCoupon = true);
    try {
      final applied = await ref.read(couponRepositoryProvider).validate(code);
      ref.read(appliedCouponProvider.notifier).state = applied;
      _coupon.clear();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Coupon ${applied.code} applied')));
    } catch (e) {
      ref.read(appliedCouponProvider.notifier).state = null;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ..showSnackBar(
              SnackBar(content: Text('Order ${order.orderNumber} placed!')));
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
          // Cart lines + checkout form scroll; the totals + Place order stay
          // pinned in a bottom bar. (The earlier layout crashes traced to the
          // coupon Apply button demanding infinite width under the full-width
          // button theme — fixed separately — not to this structure.)
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  children: [
                    for (final item in cart.items) ...[
                      _cartLine(item),
                      const Divider(height: 1),
                    ],
                    const SizedBox(height: 12),
                    ..._checkoutForm(cart),
                  ],
                ),
              ),
              _pinnedBar(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _cartLine(CartLine item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail — scannability in a long bulk cart.
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: ProductThumb(imageUrl: item.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.variantName != null ? '${item.name} · ${item.variantName}' : item.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatPaise(item.unitPricePaise)} / ${item.unit.toLowerCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPaise(item.lineSubtotalPaise),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CartStepper(
            qty: item.quantity,
            onDec: () => _changeQty(item, item.quantity - 1),
            onInc: () => _changeQty(item, item.quantity + 1),
            onEdit: () => _editLineQty(item),
          ),
        ],
      ),
    );
  }

  /// Address + payment method + coupon — the part that scrolls with the cart.
  List<Widget> _checkoutForm(Cart cart) {
    final theme = Theme.of(context);
    final address = ref.watch(defaultAddressProvider);
    final method = ref.watch(selectedPaymentProvider);
    final customer = ref.watch(authControllerProvider).valueOrNull;
    final coupon = ref.watch(appliedCouponProvider);

    final creditApproved = customer?.creditApproved ?? false;
    final creditLimit = customer?.creditLimitPaise ?? 0;
    final creditBlocked = method == 'CREDIT' && !creditApproved;

    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.location_on_outlined),
        title: Text(address == null ? 'Add a delivery address' : 'Deliver to'),
        subtitle:
            Text(address?.summary ?? 'Required to place your order'),
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
          onTap: () =>
              ref.read(selectedPaymentProvider.notifier).state = m.code,
        ),
      if (method == 'BANK_TRANSFER') ...[
        const SizedBox(height: 8),
        TextField(
          controller: _bankRef,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Transfer reference (UTR / txn id)',
            helperText:
                'Enter the reference after you transfer; we verify and confirm.',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
      ],
      if (creditBlocked)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Credit isn\'t approved for your shop yet.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ),
      const SizedBox(height: 12),
      _CouponField(
        applied: coupon,
        controller: _coupon,
        applying: _applyingCoupon,
        onApply: _applyCoupon,
        onRemove: () =>
            ref.read(appliedCouponProvider.notifier).state = null,
      ),
      const SizedBox(height: 12),
      Text('GST is added at checkout based on your delivery state.',
          style: theme.textTheme.bodySmall),
    ];
  }

  /// Pinned totals + place-order CTA. Stays visible while the form scrolls;
  /// reads the same providers so it enables/disables live.
  Widget _pinnedBar(Cart cart) {
    final theme = Theme.of(context);
    final address = ref.watch(defaultAddressProvider);
    final method = ref.watch(selectedPaymentProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final customer = ref.watch(authControllerProvider).valueOrNull;
    final coupon = ref.watch(appliedCouponProvider);

    final creditApproved = customer?.creditApproved ?? false;
    final bankRefMissing =
        method == 'BANK_TRANSFER' && _bankRef.text.trim().isEmpty;
    final creditBlocked = method == 'CREDIT' && !creditApproved;
    final canPlace = address != null &&
        !checkout.isLoading &&
        !bankRefMissing &&
        !creditBlocked;

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal (excl. GST)',
                      style: theme.textTheme.titleMedium),
                  Text(formatPaise(cart.subtotalPaise),
                      style: theme.textTheme.titleLarge),
                ],
              ),
              if (coupon != null && coupon.discountPaise > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Coupon (${coupon.code})',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.green.shade700)),
                    Text('- ${formatPaise(coupon.discountPaise)}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.green.shade700)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canPlace
                      ? () => ref
                          .read(checkoutControllerProvider.notifier)
                          .placeOrder(
                            addressId: address.id,
                            paymentMethod: method,
                            bankReference: method == 'BANK_TRANSFER'
                                ? _bankRef.text.trim()
                                : null,
                            couponCode: coupon?.code,
                          )
                      : null,
                  child: checkout.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(address == null
                          ? 'Add an address to continue'
                          : 'Place order'),
                ),
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
            border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(method.icon,
                  size: 22,
                  color: selected ? scheme.primary : scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(method.sub,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing!,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor)),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
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

/// Coupon entry: a code field + Apply, or a green "applied" banner with the
/// saving and a remove button.
class _CouponField extends StatelessWidget {
  const _CouponField({
    required this.applied,
    required this.controller,
    required this.applying,
    required this.onApply,
    required this.onRemove,
  });

  final AppliedCoupon? applied;
  final TextEditingController controller;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${applied!.code} applied',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: Colors.green.shade800)),
                  Text(
                    applied!.description?.isNotEmpty == true
                        ? applied!.description!
                        : 'You save ${formatPaise(applied!.discountPaise)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.green.shade700,
              onPressed: onRemove,
              tooltip: 'Remove coupon',
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Have a coupon?',
              hintText: 'Enter code',
              prefixIcon: Icon(Icons.local_offer_outlined),
              isDense: true,
            ),
            onSubmitted: (_) => onApply(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          // Bounded width: the app theme gives FilledButton a full-width
          // minimumSize (Size.fromHeight), which demands infinite width when
          // the button is a non-flex child of a Row and crashes layout.
          width: 96,
          height: 48,
          child: FilledButton.tonal(
            onPressed: applying ? null : onApply,
            child: applying
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Apply'),
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
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('Your cart is empty'),
        ],
      ),
    );
  }
}

/// Accessible, finger-friendly quantity stepper for a cart line — bordered
/// pill with 44dp hit areas, haptics and screen-reader labels.
class _CartStepper extends StatelessWidget {
  const _CartStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
    required this.onEdit,
  });

  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, Icons.remove, qty <= 1 ? 'Remove item' : 'Decrease quantity', onDec),
          Semantics(
            button: true,
            label: 'Edit quantity, currently $qty',
            child: InkWell(
              onTap: onEdit,
              child: Container(
                constraints: const BoxConstraints(minWidth: 34, minHeight: 44),
                alignment: Alignment.center,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          _btn(context, Icons.add, 'Increase quantity', onInc),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
      ),
    );
  }
}
