import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../products/domain/product.dart';

class SearchResult {
  const SearchResult({required this.reply, required this.aiPowered, required this.items});

  final String reply;
  final bool aiPowered;
  final List<Product> items;
}

class SearchRepository {
  SearchRepository(this._dio);

  final Dio _dio;

  Future<SearchResult> aiSearch(String query) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/search/ai',
        data: {'query': query},
      );
      final data = response.data!;
      return SearchResult(
        reply: (data['reply'] ?? '') as String,
        aiPowered: (data['aiPowered'] ?? false) as bool,
        items: (data['items'] as List<dynamic>? ?? [])
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(dioProvider));
});
