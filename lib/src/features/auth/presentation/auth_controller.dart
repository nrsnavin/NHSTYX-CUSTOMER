import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/customer.dart';

/// Current authentication state as [AsyncValue<Customer?>]; null = signed out.
class AuthController extends AsyncNotifier<Customer?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  Future<Customer?> build() async {
    final token = await _storage.readAccessToken();
    if (token == null) return null;
    try {
      return await _repo.me();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.login(phone, password);
      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return result.customer;
    });
  }

  /// Submits a registration request. Does NOT sign the shop in — the account
  /// is PENDING until the store agent approves it, so no tokens are stored and
  /// auth state stays signed-out. Returns the result for the screen to show.
  Future<RegisterResult> register({
    required String shopName,
    required String phone,
    required String password,
    required String city,
    String? ownerName,
    String? email,
    String? gstin,
  }) {
    return _repo.register(
      shopName: shopName,
      phone: phone,
      password: password,
      city: city,
      ownerName: ownerName,
      email: email,
      gstin: gstin,
    );
  }

  /// Re-fetches the signed-in shop's profile (e.g. after editing GST details)
  /// and refreshes auth state in place.
  Future<void> refreshProfile() async {
    final customer = await _repo.me();
    state = AsyncData(customer);
  }

  Future<void> logout() async {
    await _repo.logout();
    await _storage.clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Customer?>(AuthController.new);
