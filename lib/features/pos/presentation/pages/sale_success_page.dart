import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/sale_model.dart';
import '../../../../shared/models/business_model.dart';
import '../../../../core/services/receipt/receipt_generator.dart';
import '../../../../core/services/receipt_service.dart';
import '../../../receipts/presentation/providers/receipt_providers.dart';

class SaleSuccessPage extends ConsumerWidget {
  final SaleModel sale;
  final BusinessModel business;

  const SaleSuccessPage({
    super.key,
    required this.sale,
    required this.business,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64.sp,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'Sale Successful!',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                sale.status == 'Draft'
                    ? 'Your draft has been saved.'
                    : (sale.status == 'PendingPayment'
                        ? 'Sale submitted for approval.'
                        : 'The transaction was completed successfully.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 48.h),
              _buildSaleSummary(),
              const Spacer(),
              _buildActions(context, ref),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleSummary() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _summaryRow('Sale ID', '#${sale.id.substring(0, 8).toUpperCase()}'),
          SizedBox(height: 12.h),
          _summaryRow('Total Amount', '\$${sale.total.toStringAsFixed(2)}', isBold: true),
          SizedBox(height: 12.h),
          _summaryRow('Payment Method', sale.paymentMethod.replaceFirst(sale.paymentMethod[0], sale.paymentMethod[0].toUpperCase())),
        ],
      ),
    );
  }

  Widget _summaryRow(final String label, final String value, {final bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14.sp),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 14.sp,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(final BuildContext context, final WidgetRef ref) {
    return Column(
      children: [
        if (sale.status == 'Paid' || sale.status == 'Pending') ...[
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.print,
                  label: 'Print Thermal',
                  onPressed: () async {
                    final template = await ref.read(activeReceiptTemplateProvider.future);
                    ReceiptGenerator().printThermal(sale, business, template);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _actionButton(
                  icon: Icons.share,
                  label: 'Share PDF',
                  onPressed: () => ReceiptService.generateAndShareReceipt(sale, business),
                  isPrimary: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            onPressed: () => context.go('/pos'),
            child: Text(
              'New Sale',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required final IconData icon,
    required final String label,
    required final VoidCallback onPressed,
    final bool isPrimary = true,
  }) {
    return SizedBox(
      height: 56.h,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          side: isPrimary ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
          backgroundColor: isPrimary ? Colors.blue[50] : Colors.white,
          foregroundColor: isPrimary ? Colors.blue[700] : Colors.black87,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20.sp),
        label: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
        ),
      ),
    );
  }
}
