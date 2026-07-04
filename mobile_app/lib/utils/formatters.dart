import 'package:intl/intl.dart';

final NumberFormat currencyInr = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0, locale: 'en_IN');
final DateFormat shortDate = DateFormat('dd/MM/yy');
final DateFormat longDate = DateFormat('dd MMM yyyy');
