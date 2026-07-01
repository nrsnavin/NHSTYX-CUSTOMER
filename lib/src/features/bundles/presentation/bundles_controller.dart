import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bundle_repository.dart';
import '../domain/bundle.dart';

/// Active bundles, priced for the shopper's store.
final bundlesProvider = FutureProvider.autoDispose<List<Bundle>>((ref) {
  return ref.watch(bundleRepositoryProvider).list();
});
