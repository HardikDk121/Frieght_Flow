import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _inrWhole = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _compact = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1);

  static String format(double amount)        => _inr.format(amount);
  static String formatWhole(double amount)   => _inrWhole.format(amount);
  static String formatCompact(double amount) => _compact.format(amount);

  static String formatWeight(double kg) {
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)} MT';
    return '${kg.toStringAsFixed(0)} kg';
  }
}
