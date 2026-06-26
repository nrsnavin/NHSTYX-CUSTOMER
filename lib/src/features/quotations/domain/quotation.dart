int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class QuotationItem {
  const QuotationItem({
    required this.productName,
    required this.quantity,
    required this.unitPricePaise,
    required this.lineTotalPaise,
    this.variantName,
  });

  final String productName;
  final int quantity;
  final int unitPricePaise;
  final int lineTotalPaise;
  final String? variantName;

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      productName: (json['productName'] ?? 'Item') as String,
      quantity: _toInt(json['quantity']),
      unitPricePaise: _toInt(json['unitPricePaise']),
      lineTotalPaise: _toInt(json['lineTotalPaise']),
      variantName: json['variantName'] as String?,
    );
  }
}

class Quotation {
  const Quotation({
    required this.id,
    required this.quoteNumber,
    required this.status,
    required this.subtotalPaise,
    required this.totalPaise,
    required this.createdAt,
    this.title,
    this.notes,
    this.validUntil,
    this.cgstPaise = 0,
    this.sgstPaise = 0,
    this.igstPaise = 0,
    this.discountPaise = 0,
    this.orderNumber,
    this.items = const [],
  });

  final String id;
  final String quoteNumber;
  final String status;
  final String? title;
  final String? notes;
  final DateTime? validUntil;
  final int subtotalPaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int discountPaise;
  final int totalPaise;
  final String? orderNumber;
  final DateTime createdAt;
  final List<QuotationItem> items;

  int get taxPaise => cgstPaise + sgstPaise + igstPaise;

  bool get canRespond => status == 'SENT';

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as String,
      quoteNumber: json['quoteNumber'] as String,
      status: (json['status'] ?? 'SENT') as String,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      validUntil: DateTime.tryParse(json['validUntil'] as String? ?? ''),
      subtotalPaise: _toInt(json['subtotalPaise']),
      cgstPaise: _toInt(json['cgstPaise']),
      sgstPaise: _toInt(json['sgstPaise']),
      igstPaise: _toInt(json['igstPaise']),
      discountPaise: _toInt(json['discountPaise']),
      totalPaise: _toInt(json['totalPaise']),
      orderNumber: json['orderNumber'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => QuotationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
