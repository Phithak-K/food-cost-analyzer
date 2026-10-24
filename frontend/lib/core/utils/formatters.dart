import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'th_TH',
    symbol: '฿',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'th_TH',
    symbol: '฿',
  );


  static String currency(double value) {
    return _currencyFormat.format(value);
  }

  static String compactCurrency(double value) {
    return _compactCurrency.format(value);
  }

  static String percentage(double value) {
    // Assuming value is already out of 100, e.g. 32.5%
    return '${value.toStringAsFixed(1)}%';
  }

  static String number(num value) {
    return NumberFormat.decimalPattern('th_TH').format(value);
  }
}
