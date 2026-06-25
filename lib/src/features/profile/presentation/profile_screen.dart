import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../../wishlist/presentation/wishlist_screen.dart';
import 'address_book_screen.dart';
import 'gst_details_screen.dart';

/// Account hub, Blinkit-style: an identity header over a list of menu rows
/// (orders, wishlist, address book, GST details) and a sign-out action.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customer = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: customer == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _Header(
                  shopName: customer.shopName,
                  phone: customer.phone,
                  storeLabel: customer.store == null
                      ? null
                      : 'Served by ${customer.store!.name} · ${customer.store!.city}',
                ),
                const SizedBox(height: 8),
                _MenuGroup(children: [
                  _MenuRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Your orders',
                    subtitle: 'Track, reorder & view invoices',
                    onTap: () {
                      // Orders is a bottom-nav tab on the home shell.
                      ref.read(homeTabProvider.notifier).state = 2;
                      Navigator.of(context).pop();
                    },
                  ),
                  _MenuRow(
                    icon: Icons.favorite_border,
                    label: 'Wishlist',
                    subtitle: 'Products you saved for later',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address book',
                    subtitle: 'Manage delivery addresses',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.description_outlined,
                    label: 'GST & business details',
                    subtitle: customer.gstin?.isNotEmpty == true
                        ? customer.gstin!
                        : 'Add GSTIN for tax invoices',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GstDetailsScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _MenuGroup(children: [
                  _MenuRow(
                    icon: Icons.logout,
                    label: 'Log out',
                    danger: true,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ]),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'NH Styx',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to place orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.shopName, required this.phone, this.storeLabel});
  final String shopName;
  final String phone;
  final String? storeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              shopName.isNotEmpty ? shopName[0].toUpperCase() : '?',
              style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName,
                    style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('+91 $phone', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                if (storeLabel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          storeLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded, divided container that groups menu rows (Blinkit-style cards).
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? theme.colorScheme.error : theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.titleSmall?.copyWith(color: color)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      trailing: danger ? null : const Icon(Icons.chevron_right, size: 20),
    );
  }
}
