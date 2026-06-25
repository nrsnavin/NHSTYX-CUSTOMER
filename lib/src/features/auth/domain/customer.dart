/// The store that serves this shop owner (by their city).
class CustomerStore {
  const CustomerStore({
    required this.id,
    required this.name,
    required this.city,
    this.code,
    this.phone,
  });

  final String id;
  final String name;
  final String city;
  final String? code;

  /// The store/agent contact number — powers the home "call to bulk order".
  final String? phone;

  factory CustomerStore.fromJson(Map<String, dynamic> json) {
    return CustomerStore(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      code: json['code'] as String?,
      phone: json['phone'] as String?,
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
    this.status = 'APPROVED',
    this.creditApproved = false,
    this.creditLimitPaise = 0,
    this.creditDays = 0,
  });

  final String id;
  final String shopName;
  final String phone;
  final String? ownerName;
  final String? email;
  final String? gstin;

  /// The store serving this customer; null if their city isn't covered yet.
  final CustomerStore? store;

  /// PENDING / APPROVED / REJECTED.
  final String status;

  /// Whether an admin has approved a credit facility, and its limit.
  final bool creditApproved;
  final int creditLimitPaise;
  final int creditDays;

  bool get isApproved => status == 'APPROVED';

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
      status: (json['status'] ?? 'APPROVED') as String,
      creditApproved: json['creditApproved'] == true,
      creditLimitPaise: (json['creditLimitPaise'] as num?)?.toInt() ?? 0,
      creditDays: (json['creditDays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Result of a registration request — the shop must be approved before sign-in.
class RegisterResult {
  const RegisterResult({required this.status, required this.message, this.storeName});

  final String status; // PENDING
  final String message;
  final String? storeName;

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    final store = json['store'];
    return RegisterResult(
      status: (json['status'] ?? 'PENDING') as String,
      message: (json['message'] ?? 'Your request has been submitted for approval.') as String,
      storeName: store is Map<String, dynamic> ? store['name'] as String? : null,
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
