import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// A serviceable city and the store that fulfils it (location verification:
/// only cities backed by a real store are selectable at registration).
class ServiceCity {
  const ServiceCity({required this.city, required this.storeName});

  final String city;
  final String storeName;

  factory ServiceCity.fromJson(Map<String, dynamic> json) => ServiceCity(
        city: (json['city'] ?? '') as String,
        storeName: (json['storeName'] ?? '') as String,
      );
}

/// Public list of cities NH Styx serves — powers the registration dropdown.
final serviceCitiesProvider = FutureProvider<List<ServiceCity>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/stores/cities');
  final items = (res.data?['items'] as List<dynamic>? ?? []);
  return items.map((e) => ServiceCity.fromJson(e as Map<String, dynamic>)).toList();
});
