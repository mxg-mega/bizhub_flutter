import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../shared/providers/auth_provider.dart';

part 'analytics_providers.g.dart';

class DailyFinance {
  final double revenue;
  final double expense;
  DailyFinance({this.revenue = 0.0, this.expense = 0.0});
}

@riverpod
Stream<List<TransactionModel>> transactionHistory(final TransactionHistoryRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  
  final isar = ref.watch(isarDatabaseProvider).value;
  if (isar == null) return Stream.value([]);

  return isar.transactionModels
      .where()
      .filter()
      .businessIdEqualTo(businessId)
      .sortByTimestampDesc()
      .watch(fireImmediately: true);
}

@riverpod
Stream<Map<DateTime, DailyFinance>> dailyFinance(final DailyFinanceRef ref) {
  return ref.watch(transactionHistoryProvider).maybeWhen(
    data: (transactions) {
      final Map<DateTime, DailyFinance> daily = {};
      for (final tx in transactions) {
        final date = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
        final current = daily[date] ?? DailyFinance();
        
        if (tx.type == 'sale') {
          daily[date] = DailyFinance(revenue: current.revenue + tx.amount, expense: current.expense);
        } else if (tx.type == 'expense') {
          daily[date] = DailyFinance(revenue: current.revenue, expense: current.expense + tx.amount);
        }
      }
      return Stream.value(daily);
    },
    orElse: () => Stream.value({}),
  );
}
