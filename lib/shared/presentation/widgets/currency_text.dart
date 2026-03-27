import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/currency_provider.dart';

class CurrencyText extends ConsumerWidget {
  final double amount;
  final String? fromCurrency;
  final TextStyle? style;
  final bool showSymbol;

  const CurrencyText(
    this.amount, {
    super.key,
    this.fromCurrency,
    this.style,
    this.showSymbol = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayCurrency = ref.watch(activeDisplayCurrencyProvider);
    final notifier = ref.read(currencyNotifierProvider.notifier);
    
    final convertedAmount = notifier.convert(
      amount, 
      fromCurrency ?? notifier.baseCurrency.code, 
      displayCurrency.code
    );

    final formatter = NumberFormat.currency(
      symbol: showSymbol ? displayCurrency.symbol : '',
      decimalDigits: 2,
    );

    return Text(
      formatter.format(convertedAmount),
      style: style,
    );
  }
}
