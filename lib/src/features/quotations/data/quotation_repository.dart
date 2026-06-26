import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/quotation.dart';

class QuotationRepository {
  QuotationRepository(this._dio);

  final Dio _dio;

  /// Quotations the shop has been sent (drafts are hidden server-side).
  Future<List<Quotation>> fetchMine() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/quotations/mine');
      final items = response.data!['items'] as List<dynamic>;
      return items.map((e) => Quotation.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Quotation> fetchOne(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/quotations/mine/$id');
      return Quotation.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Accept or decline a quote (`action` is ACCEPT or DECLINE).
  Future<Quotation> respond(String id, String action) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quotations/mine/$id/respond',
        data: {'action': action},
      );
      return Quotation.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Uint8List> fetchPdf(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/quotations/$id/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return QuotationRepository(ref.watch(dioProvider));
});
