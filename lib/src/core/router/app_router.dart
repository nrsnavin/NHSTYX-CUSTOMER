import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';

/// App router. Redirects between the auth flow and the main app based on the
/// reactive [authControllerProvider] state.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    ],
  );
});

/// Bridges Riverpod auth changes to GoRouter's [refreshListenable].
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);

    // Wait for the initial session check before redirecting.
    if (authState.isLoading) return null;

    final loggedIn = authState.valueOrNull != null;
    final location = state.matchedLocation;
    final onAuthPage = location == '/login' || location == '/register';

    if (!loggedIn) return onAuthPage ? null : '/login';
    if (loggedIn && onAuthPage) return '/';
    return null;
  }
}
