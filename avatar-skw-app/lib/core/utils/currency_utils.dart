import 'package:intl/intl.dart';

class CurrencyUtils {
  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format a double amount to INR currency string (e.g., ₹1,500.00)
  static String format(double? amount) {
    if (amount == null) return '₹0.00';
    return _formatter.format(amount);
  }

  /// Format an amount in paise to INR currency string
  static String formatPaise(int? paise) {
    if (paise == null) return '₹0.00';
    return format(paise / 100.0);
  }

  /// Clean a price string from common formatting to get a double
  /// (Useful for legacy data or user input)
  static double parsePrice(String? price) {
    if (price == null || price.isEmpty) return 0.0;
    // Remove ₹ and ,
    final clean = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}
