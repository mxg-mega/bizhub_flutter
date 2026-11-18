import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/currency_provider.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/sale_model.dart';
import '../providers/sales_providers.dart';
import '../../../../core/auth/role_permissions.dart';
import '../../../../core/services/receipt/receipt_generator.dart';
import '../../../../core/services/receipt_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../receipts/data/models/receipt_design_model.dart';
import '../../../receipts/presentation/providers/receipt_providers.dart';

class SalesHistoryPage extends ConsumerStatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  ConsumerState<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends ConsumerState<SalesHistoryPage> {
  String _selectedStatus = 'All';

  @override
  Widget build(final BuildContext context) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonAppBar(
        hasTitle: true,
        title: 'Sales History',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Sales',
            onSelected: (final value) => _handleExport(context, ref, value, salesAsync.value ?? []),
            itemBuilder: (final context) => [
              const PopupMenuItem(value: 'pdf', child: Text('PDF Performance Report')),
              const PopupMenuItem(value: 'csv', child: Text('CSV Raw Export (Accountant)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(salesHistoryProvider),
              child: salesAsync.when(
                data: (final sales) {
                  final filtered = sales.where((final s) => _selectedStatus == 'All' || s.status == _selectedStatus).toList();
                  return _buildSalesList(context, ref, filtered, user);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final e, final _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final statuses = ['All', 'Paid', 'Pending', 'PendingPayment', 'Draft'];
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (final context, final index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (final val) => setState(() => _selectedStatus = status),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200]!),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleExport(final BuildContext context, final WidgetRef ref, final String format, final List<SaleModel> sales) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    if (format == 'pdf') {
      final file = await ReportService.generateSalesPdf(sales, business);
      await Share.shareXFiles([XFile(file.path)], text: 'Sales Performance Report');
    } else {
      final file = await ReportService.generateSalesCsv(sales);
      await Share.shareXFiles([XFile(file.path)], text: 'Sales Raw Export');
    }
  }

  Widget _buildSalesList(final BuildContext context, final WidgetRef ref, final List<SaleModel> sales, final UserModel? user) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64.sp, color: Colors.grey[200]),
            SizedBox(height: 16.h),
            Text('No sales records found', style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: sales.length,
      itemBuilder: (final context, final index) {
        final sale = sales[index];
        return _SaleCard(sale: sale, user: user);
      },
    );
  }
}

class _SaleCard extends ConsumerWidget {
  final SaleModel sale;
  final UserModel? user;
  const _SaleCard({required this.sale, this.user});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentRole = ref.watch(currentRoleProvider);
    final currency = ref.watch(activeDisplayCurrencyProvider);
    final canApprove = user?.hasPermission(role: currentRole, module: 'pos', action: 'approve') ?? false;
    final isPending = sale.status == 'Draft' || sale.status == 'PendingPayment';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: _getStatusColor(sale.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getStatusIcon(sale.status), color: _getStatusColor(sale.status), size: 24.sp),
        ),
        title: Text(
          '#${sale.id.substring(0, 8).toUpperCase()}',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        subtitle: Text(
          DateFormat('MMM dd, hh:mm a').format(sale.date),
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${currency.symbol}${sale.total.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: Colors.black87,
              ),
            ),
            _StatusBadge(status: sale.status),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                SizedBox(height: 8.h),
                ...sale.items.map((final item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} (x${item.quantity.toStringAsFixed(0)} ${item.unit})',
                          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
                        ),
                      ),
                      Text(
                        '${currency.symbol}${item.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: 12.h),
                const Divider(),
                SizedBox(height: 12.h),
                if (isPending && canApprove)
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => ref.read(saleActionsProvider.notifier).approveSale(sale),
                      child: Text('Approve & Finalize', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (!isPending) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _QuickActionButton(
                        icon: Icons.print_outlined,
                        label: 'Thermal',
                        onPressed: () async {
                          final business = ref.read(currentBusinessProvider);
                          final template = await ref.read(activeReceiptTemplateProvider.future);
                          ReceiptDesignModel? design;
                          try {
                            design = await ref
                                .read(webReceiptDesignProvider.future);
                          } catch (_) {}
                          ReceiptGenerator().printThermal(
                            sale,
                            business!,
                            template,
                            design: design,
                          );
                        },
                      ),
                      SizedBox(width: 8.w),
                      _QuickActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onPressed: () {
                          final business = ref.read(currentBusinessProvider);
                          ReceiptService.generateAndShareReceipt(sale, business!);
                        },
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

  Color _getStatusColor(final String status) {
    switch (status) {
      case 'Paid': return Colors.green;
      case 'Pending': return Colors.blue;
      case 'PendingPayment': return Colors.orange;
      case 'Draft': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(final String status) {
    switch (status) {
      case 'Paid': return Icons.check_circle_outline;
      case 'Pending': return Icons.history;
      case 'PendingPayment': return Icons.payment;
      case 'Draft': return Icons.edit_note;
      default: return Icons.help_outline;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(final BuildContext context) {
    Color color = Colors.grey;
    if (status == 'Paid') color = Colors.green;
    if (status == 'Pending') color = Colors.blue;
    if (status == 'PendingPayment') color = Colors.orange;
    if (status == 'Draft') color = Colors.purple;

    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(final BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue[700],
        padding: EdgeInsets.symmetric(horizontal: 12.w),
      ),
    );
  }
}
