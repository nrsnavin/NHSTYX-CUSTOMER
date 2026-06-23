import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/address.dart';

class AddressRepository {
  AddressRepository(this._dio);

  final Dio _dio;

  Future<List<Address>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/addresses');
      final items = response.data!['data'] as List<dynamic>;
      return items.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Address> create({
    required String line1,
    required String city,
    required String state,
    required String pincode,
    String? label,
    String? line2,
    String? stateCode,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/addresses',
        data: {
          'line1': line1,
          'city': city,
          'state': state,
          'pincode': pincode,
          if (label != null && label.isNotEmpty) 'label': label,
          if (line2 != null && line2.isNotEmpty) 'line2': line2,
          if (stateCode != null && stateCode.isNotEmpty) 'stateCode': stateCode,
          'isDefault': isDefault,
        },
      );
      return Address.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(dioProvider));
});
