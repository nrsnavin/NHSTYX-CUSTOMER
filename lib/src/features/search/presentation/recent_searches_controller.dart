import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the shop's recent search queries (most-recent first, de-duped and
/// capped) so the search screen can offer one-tap re-runs.
class RecentSearches extends Notifier<List<String>> {
  static const _key = 'nhstyx_recent_searches';
  static const _max = 8;
  final _storage = const FlutterSecureStorage();

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return;
    try {
      state = (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      // Ignore a corrupt cache — recents are best-effort.
    }
  }

  Future<void> _persist() => _storage.write(key: _key, value: jsonEncode(state));

  /// Record a query at the top of the list, dropping any older duplicate.
  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [
      q,
      ...state.where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(_max).toList();
    await _persist();
  }

  Future<void> remove(String query) async {
    state = state.where((e) => e != query).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _storage.delete(key: _key);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);
