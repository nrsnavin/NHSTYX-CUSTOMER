import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/notification.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<NotificationFeed> fetchMine() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/notifications/mine');
      return NotificationFeed.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post<Map<String, dynamic>>('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post<Map<String, dynamic>>('/notifications/mine/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});
