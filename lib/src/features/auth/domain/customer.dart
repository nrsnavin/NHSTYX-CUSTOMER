/// The store that serves this shop owner (by their city).
class CustomerStore {
  const CustomerStore({required this.id, required this.name, required this.city, this.code});

  final String id;
  final String name;
  final String city;
  final String? code;

  factory CustomerStore.fromJson(Map<String, dynamic> json) {
    return CustomerStore(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      code: json['code'] as String?,
    );
  }
}

/// The signed-in shop owner (NH Styx customer). Phone is the primary identity.
class Customer {
  const Customer({
    required this.id,
    required this.shopName,
    required this.phone,
    this.ownerName,
    this.email,
    this.gstin,
    this.store,
  });

  final String id;
  final String shopName;
  final String phone;
  final String? ownerName;
  final String? email;
  final String? gstin;

  /// The store serving this customer; null if their city isn't covered yet.
  final CustomerStore? store;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      shopName: (json['shopName'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      ownerName: json['ownerName'] as String?,
      email: json['email'] as String?,
      gstin: json['gstin'] as String?,
      store: json['store'] is Map<String, dynamic>
          ? CustomerStore.fromJson(json['store'] as Map<String, dynamic>)
          : null,
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
