import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhstyx_customer/src/core/storage/token_storage.dart';
import 'package:nhstyx_customer/src/features/auth/presentation/login_screen.dart';

/// In-memory token storage so widget tests never touch platform channels.
class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('Login screen renders the sign-in form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Allow the auth session check to resolve (to "signed out").
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('NH Styx'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
