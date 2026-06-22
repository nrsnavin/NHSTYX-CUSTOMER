import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String formatCurrency(num value) => _currency.format(value);
