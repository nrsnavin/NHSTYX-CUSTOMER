/// The signed-in shop owner (NH Styx customer). Phone is the primary identity.
class Customer {
  const Customer({
    required this.id,
    required this.shopName,
    required this.phone,
    this.ownerName,
    this.email,
    this.gstin,
  });

  final String id;
  final String shopName;
  final String phone;
  final String? ownerName;
  final String? email;
  final String? gstin;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      shopName: (json['shopName'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      ownerName: json['ownerName'] as String?,
      email: json['email'] as String?,
      gstin: json['gstin'] as String?,
    );
  }
}

/// Result of a successful login/register call.
class AuthResult {
  const AuthResult({
    required this.customer,
    required this.accessToken,
    required this.refreshToken,
  });

  final Customer customer;
  final String accessToken;
  final String refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
