/// Authenticated user (a store/boutique owner using the customer app).
class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.businessName,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? businessName;

  factory User.fromJson(Map<String, dynamic> json) {
    final profile = json['customerProfile'] as Map<String, dynamic>?;
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] ?? '') as String,
      role: (json['role'] ?? 'CUSTOMER') as String,
      businessName: profile?['businessName'] as String?,
    );
  }
}

/// Result of a successful login/register call.
class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
