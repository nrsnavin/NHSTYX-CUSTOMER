import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quotation_repository.dart';
import '../domain/quotation.dart';

/// The signed-in shop's quotations (everything they've been sent).
final myQuotationsProvider = FutureProvider.autoDispose<List<Quotation>>((ref) {
  return ref.watch(quotationRepositoryProvider).fetchMine();
});

final quotationDetailProvider =
    FutureProvider.autoDispose.family<Quotation, String>((ref, id) {
  return ref.watch(quotationRepositoryProvider).fetchOne(id);
});
