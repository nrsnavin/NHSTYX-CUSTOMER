import 'package:dio/dio.dart';

/// A user-presentable exception derived from a failed HTTP call.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Builds a friendly exception from a [DioException].
  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      String message = 'Something went wrong. Please try again.';
      if (data is Map && data['message'] is String) {
        message = data['message'] as String;
      }
      return ApiException(message, statusCode: response.statusCode);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timed out. Check your network.');
      case DioExceptionType.connectionError:
        return ApiException('Cannot reach the server. Is it running?');
      default:
        return ApiException('Unexpected error. Please try again.');
    }
  }

  @override
  String toString() => message;
}
