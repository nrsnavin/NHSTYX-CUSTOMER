/// Centralized app configuration.
///
/// The API base URL can be overridden at build/run time:
///   flutter run --dart-define=API_BASE_URL=https://api.nhstyx.com/api/v1
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Android emulator reaches the host machine via 10.0.2.2.
    // For iOS simulator / web / desktop use http://localhost:4000/api/v1.
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
