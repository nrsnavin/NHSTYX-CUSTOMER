import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// Formats integer paise as Indian Rupees (25000 -> "₹250.00").
String formatPaise(int paise) => _currency.format(paise / 100);
