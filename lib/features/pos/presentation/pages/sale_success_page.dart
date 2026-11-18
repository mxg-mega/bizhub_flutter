import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../data/models/sale_model.dart';
import '../../../../shared/providers/currency_provider.dart';
import '../../../../shared/models/business_model.dart';
import '../../../../core/services/receipt/receipt_generator.dart';
import '../../../../core/services/receipt_service.dart';
import '../../../receipts/data/models/receipt_design_model.dart';
import '../../../receipts/presentation/providers/receipt_providers.dart';

class SaleSuccessPage extends ConsumerWidget {
  final SaleModel sale;
  final BusinessModel? business;

  const SaleSuccessPage({
    super.key,
    required this.sale,
    this.business,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final currency = ref.watch(activeDisplayCurrencyProvider);
    return Container(
      width: double.infinity,
      color: palette.card,
      child: SafeArea(
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
                  color: palette.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: palette.success,
                  size: 64.sp,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'Sale Successful!',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
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
                  color: palette.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),
              _buildSaleSummary(currency.symbol, palette),
              const Spacer(),
              _buildActions(context, ref, palette),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleSummary(final String currencySymbol, final AppPalette palette) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        children: [
          _summaryRow('Sale ID', '#${sale.id.substring(0, 8).toUpperCase()}', palette),
          SizedBox(height: 12.h),
          _summaryRow(
            'Total Amount',
            '$currencySymbol${sale.total.toStringAsFixed(2)}',
            palette,
            isBold: true,
          ),
          SizedBox(height: 12.h),
          _summaryRow(
            'Payment Method',
            sale.paymentMethod.replaceFirst(
              sale.paymentMethod[0],
              sale.paymentMethod[0].toUpperCase(),
            ),
            palette,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    final String label,
    final String value,
    final AppPalette palette, {
    final bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: palette.textSecondary, fontSize: 14.sp),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 14.sp,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    final BuildContext context,
    final WidgetRef ref,
    final AppPalette palette,
  ) {
    final canPrint = business != null &&
        (sale.status == 'Paid' || sale.status == 'Pending');
    return Column(
      children: [
        if (canPrint) ...[
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.print,
                  label: 'Print Thermal',
                  palette: palette,
                  onPressed: () async {
                    final currentBusiness = business;
                    if (currentBusiness == null) return;
                    final template =
                        await ref.read(activeReceiptTemplateProvider.future);
                    ReceiptDesignModel? design;
                    try {
                      design =
                          await ref.read(webReceiptDesignProvider.future);
                    } catch (_) {}
                    await ReceiptGenerator().printThermal(
                      sale,
                      currentBusiness,
                      template,
                      design: design,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _actionButton(
                  icon: Icons.share,
                  label: 'Share PDF',
                  palette: palette,
                  onPressed: () async {
                    final currentBusiness = business;
                    if (currentBusiness == null) return;
                    await ReceiptService.generateAndShareReceipt(sale, currentBusiness);
                  },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'New Sale',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: palette.onPrimary,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required final IconData icon,
    required final String label,
    required final AppPalette palette,
    required final VoidCallback onPressed,
    final bool isPrimary = true,
  }) {
    return SizedBox(
      height: 56.h,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          side: isPrimary
              ? BorderSide.none
              : BorderSide(color: palette.outline),
          backgroundColor: isPrimary
              ? palette.primary.withValues(alpha: 0.12)
              : palette.card,
          foregroundColor: isPrimary ? palette.primary : palette.textPrimary,
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
