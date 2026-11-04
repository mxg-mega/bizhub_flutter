import 'package:isar/isar.dart';
import '../models/transaction_model.dart';

class ProfitLossReport {
  final double totalRevenue;
  final double totalCogs;
  final double totalOpex;
  final double grossProfit;
  final double netProfit;

  ProfitLossReport({
    required this.totalRevenue,
    required this.totalCogs,
    required this.totalOpex,
    required this.grossProfit,
    required this.netProfit,
  });
}

class FinanceService {
  final Isar _isar;

  FinanceService(this._isar);

  Future<ProfitLossReport> getProfitLoss(final String businessId, final DateTime start, final DateTime end) async {
    final transactions = await _isar.transactionModels
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .and()
        .timestampBetween(start, end)
        .findAll();

    double revenue = 0;
    double cogs = 0;
    double opex = 0;

    for (final tx in transactions) {
      switch (tx.category) {
        case FinancialCategory.revenue:
          revenue += tx.amount;
          break;
        case FinancialCategory.cogs:
          cogs += tx.amount;
          break;
        case FinancialCategory.opex:
          opex += tx.amount;
          break;
        default:
          break;
      }
    }

    final grossProfit = revenue - cogs;
    final netProfit = grossProfit - opex;

    return ProfitLossReport(
      totalRevenue: revenue,
      totalCogs: cogs,
      totalOpex: opex,
      grossProfit: grossProfit,
      netProfit: netProfit,
    );
  }
}
