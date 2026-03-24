import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat('#,###', 'en');

  static String format(num amount) {
    return 'TZS ${_formatter.format(amount)}';
  }

  static String formatCompact(num amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
