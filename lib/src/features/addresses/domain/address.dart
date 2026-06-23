class Address {
  const Address({
    required this.id,
    required this.line1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
    this.label,
    this.line2,
    this.stateCode,
  });

  final String id;
  final String line1;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final String? label;
  final String? line2;
  final String? stateCode;

  String get summary {
    final parts = [line1, if (line2 != null && line2!.isNotEmpty) line2, '$city, $state', pincode];
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      line1: (json['line1'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      pincode: (json['pincode'] ?? '') as String,
      isDefault: (json['isDefault'] ?? false) as bool,
      label: json['label'] as String?,
      line2: json['line2'] as String?,
      stateCode: json['stateCode'] as String?,
    );
  }
}
