import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customer = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: customer == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        customer.shopName.isNotEmpty ? customer.shopName[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.shopName, style: theme.textTheme.titleLarge),
                          if (customer.ownerName != null)
                            Text(customer.ownerName!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Section(title: 'Account', children: [
                  _Tile(icon: Icons.phone_outlined, label: 'Phone', value: '+91 ${customer.phone}'),
                  if (customer.email != null)
                    _Tile(icon: Icons.mail_outline, label: 'Email', value: customer.email!),
                  if (customer.gstin != null)
                    _Tile(icon: Icons.receipt_long_outlined, label: 'GSTIN', value: customer.gstin!),
                ]),
                const SizedBox(height: 20),
                if (customer.store != null)
                  _Section(title: 'Your store', children: [
                    _Tile(
                        icon: Icons.storefront_outlined,
                        label: 'Served by',
                        value: customer.store!.name),
                    _Tile(
                        icon: Icons.local_shipping_outlined,
                        label: 'Ships from',
                        value: customer.store!.city),
                  ])
                else
                  const _Section(title: 'Your store', children: [
                    ListTile(
                      leading: Icon(Icons.info_outline, size: 20),
                      title: Text('No store linked yet'),
                      subtitle: Text(
                          "We don't serve your city yet. Contact support to get set up."),
                      dense: true,
                    ),
                  ]),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      subtitle: Text(value, style: theme.textTheme.bodyMedium),
      dense: true,
    );
  }
}
