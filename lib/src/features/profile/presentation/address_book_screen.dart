import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../addresses/domain/address.dart';
import '../../addresses/presentation/add_address_screen.dart';
import '../../addresses/presentation/address_controller.dart';

/// The shop's saved delivery addresses. The default is used to pre-fill
/// checkout; new ones are added via [AddAddressScreen].
class AddressBookScreen extends ConsumerWidget {
  const AddressBookScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    ref.invalidate(addressesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Address book')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
      ),
      body: AsyncValueView<List<Address>>(
        value: addressesAsync,
        onRetry: () => ref.invalidate(addressesProvider),
        loading: () => const ListCardSkeleton(height: 110),
        data: (addresses) {
          if (addresses.isEmpty) return const _NoAddresses();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(addressesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _AddressCard(address: addresses[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});
  final Address address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label?.isNotEmpty == true ? address.label! : 'Address',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.summary, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAddresses extends StatelessWidget {
  const _NoAddresses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No saved addresses', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Add a delivery address to speed up checkout.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
