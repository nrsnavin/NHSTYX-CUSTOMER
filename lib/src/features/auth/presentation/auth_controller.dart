import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// Holds the current authentication state as an [AsyncValue<User?>].
/// `null` data means "not signed in".
class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  Future<User?> build() async {
    final token = await _storage.readAccessToken();
    if (token == null) return null;
    try {
      return await _repo.me();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.login(email, password);
      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return result.user;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        businessName: businessName,
        phone: phone,
      );
      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return result.user;
    });
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      await _repo.logout(refreshToken);
    }
    await _storage.clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

/// Convenience: true when a user is signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).valueOrNull != null;
});
