import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../shared/providers/currency_provider.dart';
import '../../data/models/transfer_model.dart';
import '../providers/transfer_providers.dart';

/// Bank-transfer list + status management. No web page exists for this —
/// behavior follows the web's `use-transfers.tsx` contract (newest first,
/// status updates with optional notes, `processedAt` on terminal statuses).
class TransfersPage extends ConsumerStatefulWidget {
  const TransfersPage({super.key});

  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> {
  String _selectedStatus = 'all';

  static const Map<String, Color> _statusColors = {
    'pending': Color(0xFFF59E0B),
    'processing': Color(0xFF3B82F6),
    'completed': Color(0xFF10B981),
    'failed': Color(0xFFEF4444),
    'cancelled': Color(0xFF6B7280),
  };

  @override
  Widget build(final BuildContext context) {
    final transfersAsync = ref.watch(transferListProvider);
    final currency = ref.watch(activeDisplayCurrencyProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonAppBar(hasTitle: true, title: 'Transfers'),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(transferListProvider),
              child: transfersAsync.when(
                data: (final transfers) {
                  final filtered = _selectedStatus == 'all'
                      ? transfers
                      : transfers
                          .where((final t) => t.status == _selectedStatus)
                          .toList();
                  return _buildList(context, filtered, currency.symbol);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (final e, final _) =>
                    Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final statuses = ['all', ...TransferModel.statuses];
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
              label: Text(status == 'all' ? 'All' : _capitalize(status)),
              selected: isSelected,
              onSelected: (final _) =>
                  setState(() => _selectedStatus = status),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(
    final BuildContext context,
    final List<TransferModel> transfers,
    final String symbol,
  ) {
    if (transfers.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 120.h),
          Icon(Icons.account_balance_outlined,
              size: 64.sp, color: Colors.grey[200]),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'No transfers found',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: transfers.length,
      itemBuilder: (final context, final index) =>
          _buildCard(context, transfers[index], symbol),
    );
  }

  Widget _buildCard(
    final BuildContext context,
    final TransferModel transfer,
    final String symbol,
  ) {
    final color = _statusColors[transfer.status] ?? Colors.grey;
    final account = (transfer.accountNumber ?? '').trim();
    final masked = account.length > 4
        ? '****${account.substring(account.length - 4)}'
        : account;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.account_balance, color: color, size: 22.sp),
        ),
        title: Text(
          transfer.customerName?.trim().isNotEmpty == true
              ? transfer.customerName!
              : 'Walk-in Customer',
          style:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        subtitle: Text(
          [
            if (transfer.bankName?.trim().isNotEmpty == true)
              transfer.bankName!,
            if (masked.isNotEmpty) masked,
            DateFormat('MMM dd, yyyy').format(transfer.createdAt),
          ].join(' · '),
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$symbol${transfer.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 4.h),
            _statusChip(transfer.status, color),
          ],
        ),
        onTap: () => _showDetailSheet(context, transfer, symbol),
      ),
    );
  }

  Widget _statusChip(final String status, final Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        _capitalize(status),
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showDetailSheet(
    final BuildContext context,
    final TransferModel transfer,
    final String symbol,
  ) {
    final notes = TextEditingController(text: transfer.notes ?? '');
    var selectedStatus = transfer.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final sheetContext) => StatefulBuilder(
        builder: (final sheetContext, final setSheetState) => Padding(
          padding: EdgeInsets.all(24.w).copyWith(
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + 24.w,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Details',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                _detailRow('Sale ID', transfer.saleId),
                _detailRow('Amount', '$symbol${transfer.amount.toStringAsFixed(2)}'),
                _detailRow('Transfer Fee',
                    '$symbol${transfer.transferFee.toStringAsFixed(2)}'),
                if (transfer.bankName?.isNotEmpty == true)
                  _detailRow('Bank', transfer.bankName!),
                if (transfer.accountName?.isNotEmpty == true)
                  _detailRow('Account Name', transfer.accountName!),
                if (transfer.accountNumber?.isNotEmpty == true)
                  _detailRow('Account Number', transfer.accountNumber!),
                if (transfer.routingNumber?.isNotEmpty == true)
                  _detailRow('Routing Number', transfer.routingNumber!),
                _detailRow(
                    'Created',
                    DateFormat('MMM dd, yyyy · hh:mm a')
                        .format(transfer.createdAt)),
                if (transfer.processedAt != null)
                  _detailRow(
                      'Processed',
                      DateFormat('MMM dd, yyyy · hh:mm a')
                          .format(transfer.processedAt!)),
                SizedBox(height: 16.h),
                Text(
                  'Status',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: TransferModel.statuses.map((final status) {
                    final color = _statusColors[status] ?? Colors.grey;
                    final isSelected = selectedStatus == status;
                    return ChoiceChip(
                      label: Text(_capitalize(status)),
                      selected: isSelected,
                      onSelected: (final _) =>
                          setSheetState(() => selectedStatus = status),
                      backgroundColor: Colors.white,
                      selectedColor: color.withOpacity(0.15),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: isSelected ? color : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide(
                          color:
                              isSelected ? color : Colors.grey[200]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await ref
                          .read(transferActionsProvider.notifier)
                          .updateStatus(
                            transfer.id,
                            selectedStatus,
                            notes: notes.text.trim(),
                          );
                      if (mounted) {
                        final error =
                            ref.read(transferActionsProvider).error;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error == null
                                  ? 'Transfer updated'
                                  : 'Update failed: $error',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(final String label, final String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(final String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
