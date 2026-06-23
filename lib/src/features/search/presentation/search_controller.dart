import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/search_repository.dart';

/// Holds the latest AI search result (null before the first query).
class SearchController extends AutoDisposeAsyncNotifier<SearchResult?> {
  @override
  Future<SearchResult?> build() async => null;

  Future<void> run(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(searchRepositoryProvider).aiSearch(trimmed),
    );
  }

  void clear() => state = const AsyncData(null);
}

final searchControllerProvider =
    AutoDisposeAsyncNotifierProvider<SearchController, SearchResult?>(SearchController.new);
