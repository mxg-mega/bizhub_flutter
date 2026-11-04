import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/services/finance_service.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../shared/providers/auth_provider.dart';

final profitLossProvider = FutureProvider<ProfitLossReport>((final ref) async {
  final isar = ref.watch(isarDatabaseProvider).value;
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (isar == null || businessId == null) throw Exception('Not initialized');
  
  final service = FinanceService(isar);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  return service.getProfitLoss(businessId, startOfMonth, now);
});

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final reportAsync = ref.watch(profitLossProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: reportAsync.when(
        data: (final report) => _buildReportView(context, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportView(final BuildContext context, final ProfitLossReport report) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Performance', style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          Text('Current Month Summary', style: GoogleFonts.inter(color: Colors.grey)),
          SizedBox(height: 24.h),
          
          _FinancialSummaryGrid(report: report),
          
          SizedBox(height: 32.h),
          Text('Profit Margin', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 16.h),
          AspectRatio(
            aspectRatio: 1.7,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: report.totalCogs, title: 'COGS', color: Colors.orange, radius: 50),
                  PieChartSectionData(value: report.totalOpex, title: 'OpEx', color: Colors.red, radius: 50),
                  PieChartSectionData(value: report.netProfit, title: 'Net Profit', color: Colors.green, radius: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummaryGrid extends StatelessWidget {
  final ProfitLossReport report;
  const _FinancialSummaryGrid({required this.report});

  @override
  Widget build(final BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 1.5,
      children: [
        _SummaryCard(title: 'Revenue', value: report.totalRevenue, color: Colors.blue),
        _SummaryCard(title: 'COGS', value: report.totalCogs, color: Colors.orange),
        _SummaryCard(title: 'OpEx', value: report.totalOpex, color: Colors.red),
        _SummaryCard(title: 'Net Profit', value: report.netProfit, color: Colors.green),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          FittedBox(
            child: Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
