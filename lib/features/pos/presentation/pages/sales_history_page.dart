import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/sale_model.dart';
import '../providers/sales_providers.dart';
import '../../../../core/auth/role_permissions.dart';
import '../../../../core/services/receipt/receipt_generator.dart';
import '../../../../core/services/receipt_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../receipts/presentation/providers/receipt_providers.dart';

class SalesHistoryPage extends ConsumerWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: CommonAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Sales CSV',
            onPressed: () async {
              final sales = salesAsync.value ?? [];
              final file = await ReportService.generateSalesCsv(sales);
              await Share.shareXFiles([XFile(file.path)], text: 'Sales Report');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(salesHistoryProvider),
        child: salesAsync.when(
          data: (sales) => _buildSalesList(context, ref, sales, user),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildSalesList(BuildContext context, WidgetRef ref, List<SaleModel> sales, var user) {
    if (sales.isEmpty) {
      return const Center(child: Text('No sales found.'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return _SaleCard(sale: sale, user: user);
      },
    );
  }
}

class _SaleCard extends ConsumerWidget {
  final SaleModel sale;
  final dynamic user;
  const _SaleCard({required this.sale, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canApprove = user?.hasPermission(AppPermission.approvePayment) ?? false;
    final isPending = sale.status == 'Draft' || sale.status == 'PendingPayment';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: isPending ? Colors.orange[200]! : Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text('Sale #${sale.id.substring(0, 6).toUpperCase()}'),
            SizedBox(width: 8.w),
            _StatusBadge(status: sale.status),
          ],
        ),
        subtitle: Text(DateFormat('MMM dd, hh:mm a').format(sale.timestamp)),
        trailing: Text(
          '\$${sale.total.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: isPending ? Colors.orange[700] : Colors.green[700]),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sale.items.map((item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.name} (x${item.quantity} ${item.unit})'),
                      Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
                const Divider(),
                if (isPending && canApprove)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                        onPressed: () => ref.read(saleActionsProvider.notifier).approveSale(sale),
                        child: const Text('Approve & Finalize'),
                      ),
                    ),
                  ),
                if (!isPending) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final business = ref.read(currentBusinessProvider);
                          final template = await ref.read(activeReceiptTemplateProvider.future);
                          ReceiptGenerator().printThermal(sale, business!, template);
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Thermal'),
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        onPressed: () {
                          final business = ref.read(currentBusinessProvider);
                          ReceiptService.generateAndShareReceipt(sale, business!);
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share PDF'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'Paid') color = Colors.green;
    if (status == 'Pending') color = Colors.blue;
    if (status == 'PendingPayment') color = Colors.orange;
    if (status == 'Draft') color = Colors.purple;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
