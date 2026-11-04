import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/zakat_calculation_provider.dart';
import 'providers/inventory_worth_provider.dart';
import '../data/zakat_calculation_model.dart';
import '../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../shared/providers/auth_provider.dart';

class ZakatPage extends ConsumerStatefulWidget {
  const ZakatPage({super.key});

  @override
  ConsumerState<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends ConsumerState<ZakatPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Input Controllers
  final _cashController = TextEditingController();
  final _businessAssetsController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _liabilitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fetch inventory value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFetchInventoryValue();
    });
  }

  Future<void> _autoFetchInventoryValue() async {
    final worth = await ref.read(totalInventoryWorthProvider.future);
    _businessAssetsController.text = worth.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _businessAssetsController.dispose();
    _investmentsController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  void _calculate(final String currencyCode) {
    if (_formKey.currentState!.validate()) {
      ref.read(zakatCalculationFlowProvider.notifier).performCalculation(
        cash: double.tryParse(_cashController.text) ?? 0,
        businessAssets: double.tryParse(_businessAssetsController.text) ?? 0,
        investments: double.tryParse(_investmentsController.text),
        liabilities: double.tryParse(_liabilitiesController.text) ?? 0,
        currency: currencyCode,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final calculationState = ref.watch(zakatCalculationFlowProvider);
    final business = ref.watch(currentBusinessProvider);
    final currencyCode = business?.settings?['currencyCode'] ?? 'USD';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Zakat Tracker'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: 24.h),
            _buildInputForm(theme, currencyCode),
            SizedBox(height: 32.h),
            _buildCalculateButton(calculationState.isLoading, currencyCode),
            if (calculationState.hasValue && calculationState.value != null) ...[
              SizedBox(height: 32.h),
              _buildResultsCard(theme, calculationState.value!),
            ],
            if (calculationState.hasError) ...[
              SizedBox(height: 24.h),
              _buildErrorWidget(theme, calculationState.error.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(final ThemeData theme) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purify Your Wealth',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Calculate your annual Zakat with real-time gold prices and AI-driven financial insights.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );

  Widget _buildInputForm(final ThemeData theme, final String currencyCode) => Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _cashController,
            label: 'Total Cash & Bank Balance',
            icon: Icons.account_balance_wallet_outlined,
            suffix: currencyCode,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _businessAssetsController,
            label: 'Business Assets (Stock/Inventory)',
            icon: Icons.inventory_2_outlined,
            suffix: currencyCode,
            isAutoFetched: true,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _investmentsController,
            label: 'Investments (Stocks/Funds)',
            icon: Icons.trending_up_outlined,
            suffix: currencyCode,
            isOptional: true,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _liabilitiesController,
            label: 'Total Liabilities/Debts',
            icon: Icons.money_off_outlined,
            suffix: currencyCode,
          ),
        ],
      ),
    );

  Widget _buildTextField({
    required final TextEditingController controller,
    required final String label,
    required final IconData icon,
    required final String suffix,
    final bool isOptional = false,
    final bool isAutoFetched = false,
  }) => TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.w),
        suffixText: suffix,
        helperText: isAutoFetched ? 'Auto-calculated from your inventory' : null,
        hintText: isOptional ? 'Optional' : '0.00',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      validator: (final value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter a value';
        }
        if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );

  Widget _buildCalculateButton(final bool isLoading, final String currencyCode) => SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _calculate(currencyCode),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.h,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'Calculate Zakat',
                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
      ),
    );

  Widget _buildResultsCard(final ThemeData theme, final ZakatCalculationResult result) => Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calculation Result',
                style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              Icon(
                result.isPayable ? Icons.check_circle : Icons.info_outline,
                color: result.isPayable ? Colors.green : theme.colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildResultRow('Net Worth', result.netWorth, result.currency),
          _buildResultRow('Nisab Threshold', result.nisabValue, result.currency),
          const Divider(height: 32),
          _buildResultRow(
            'Zakat Due',
            result.zakatAmount,
            result.currency,
            isMain: true,
            color: result.isPayable ? Colors.green[700] : Colors.grey,
          ),
          if (result.insights != null) ...[
            SizedBox(height: 24.h),
            _buildAiInsights(theme, result.insights!),
          ],
        ],
      ),
    );

  Widget _buildResultRow(
    final String label,
    final double value,
    final String currency, {
    final bool isMain = false,
    final Color? color,
  }) => Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMain ? 16.sp : 14.sp,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} $currency',
            style: GoogleFonts.inter(
              fontSize: isMain ? 18.sp : 14.sp,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );

  Widget _buildAiInsights(final ThemeData theme, final String insights) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18.w, color: theme.colorScheme.secondary),
            SizedBox(width: 8.w),
            Text(
              'AI Financial Insights',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            insights,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );

  Widget _buildErrorWidget(final ThemeData theme, final String error) => Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
}
