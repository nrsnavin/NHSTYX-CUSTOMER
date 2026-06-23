import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_repository.dart';
import '../domain/address.dart';

/// The customer's saved delivery addresses.
final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  return ref.watch(addressRepositoryProvider).list();
});

/// The default address (or the first one), used to pre-select at checkout.
final defaultAddressProvider = Provider.autoDispose<Address?>((ref) {
  final list = ref.watch(addressesProvider).valueOrNull ?? const [];
  if (list.isEmpty) return null;
  return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
});
