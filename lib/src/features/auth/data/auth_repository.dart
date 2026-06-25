import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/customer.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> login(String phone, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/customer/login',
        data: {'phone': phone, 'password': password},
      );
      return AuthResult.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Submits a registration request. The shop is created PENDING and must be
  /// approved by the store agent before it can sign in — no tokens are issued.
  Future<RegisterResult> register({
    required String shopName,
    required String phone,
    required String password,
    required String city,
    String? ownerName,
    String? email,
    String? gstin,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/customer/register',
        data: {
          'shopName': shopName,
          'phone': phone,
          'password': password,
          'city': city,
          if (ownerName != null && ownerName.isNotEmpty) 'ownerName': ownerName,
          if (email != null && email.isNotEmpty) 'email': email,
          if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
        },
      );
      return RegisterResult.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Customer> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/customer/me');
      return Customer.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Updates the signed-in shop's own profile (GST details, name, email).
  /// Pass an empty string to clear an optional field (e.g. remove a GSTIN).
  Future<Customer> updateProfile({
    String? shopName,
    String? ownerName,
    String? email,
    String? gstin,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/customer/me',
        data: {
          if (shopName != null) 'shopName': shopName,
          if (ownerName != null) 'ownerName': ownerName,
          if (email != null) 'email': email,
          if (gstin != null) 'gstin': gstin,
        },
      );
      return Customer.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Best-effort; ignore network errors on logout.
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
