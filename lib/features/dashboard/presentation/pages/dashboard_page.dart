import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../pos/presentation/providers/sales_providers.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../pos/data/models/sale_model.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final productsAsync = ref.watch(productListProvider);
    final salesAsync = ref.watch(salesHistoryProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productListProvider);
          ref.invalidate(salesHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.name ?? 'User'),
              SizedBox(height: 24.h),
              _buildKPISection(productsAsync, salesAsync, context),
              SizedBox(height: 32.h),
              _buildSectionTitle('Quick Actions'),
              SizedBox(height: 16.h),
              _buildQuickActions(context),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Recent Sales'),
                  TextButton(
                    onPressed: () => context.go('/sales-history'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              _buildRecentSales(salesAsync),
              SizedBox(height: 32.h),
              _buildSectionTitle('Low Stock Items'),
              SizedBox(height: 16.h),
              _buildInventorySummary(productsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(final String name) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Center',
          style: GoogleFonts.inter(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          'Welcome back, $name',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );

  Widget _buildSectionTitle(final String title) => Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );

  Widget _buildKPISection(
    final AsyncValue<List<ProductModel>> productsAsync, 
    final AsyncValue<List<SaleModel>> salesAsync, 
    final BuildContext context
  ) {
    final totalProducts = productsAsync.maybeWhen(
      data: (final List<ProductModel> p) => p.length, 
      orElse: () => 0
    );
    final revenueToday = salesAsync.maybeWhen(
      data: (final List<SaleModel> sales) {
        final today = DateTime.now();
        return sales
            .where((final SaleModel s) => s.timestamp.year == today.year && s.timestamp.month == today.month && s.timestamp.day == today.day)
            .fold(0.0, (final double sum, final SaleModel s) => sum + s.total);
      },
      orElse: () => 0.0,
    );

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/analytics'),
            child: _KPICard(
              label: 'Sales Today',
              value: '\$${revenueToday.toStringAsFixed(0)}',
              icon: Icons.payments_outlined,
              color: Colors.green,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/inventory'),
            child: _KPICard(
              label: 'Total Items',
              value: '$totalProducts',
              icon: Icons.inventory_2_outlined,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(final BuildContext context) => SizedBox(
      height: 100.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionItem(
            label: 'New Sale',
            icon: Icons.point_of_sale,
            onTap: () => context.go('/pos'),
          ),
          _QuickActionItem(
            label: 'Add Product',
            icon: Icons.add_box_outlined,
            onTap: () => context.pushNamed('add-edit-product'),
          ),
          _QuickActionItem(
            label: 'Zakat',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => context.go('/zakat'),
          ),
          _QuickActionItem(
            label: 'Customers',
            icon: Icons.people_outline,
            onTap: () => context.go('/customers'),
          ),
        ],
      ),
    );

  Widget _buildRecentSales(final AsyncValue<List<SaleModel>> salesAsync) => salesAsync.when(
      data: (final List<SaleModel> sales) {
        if (sales.isEmpty) return const Text('No sales recorded today.');
        final recent = sales.take(3).toList();
        return Column(
          children: recent.map((final SaleModel s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.green[50], child: const Icon(Icons.receipt_long, color: Colors.green, size: 20)),
            title: Text('Sale #${s.id.substring(0, 6).toUpperCase()}'),
            subtitle: Text(DateFormat('hh:mm a').format(s.timestamp)),
            trailing: Text('\$${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          )).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (final e, _) => Text('Error: $e'),
    );

  Widget _buildInventorySummary(final AsyncValue<List<ProductModel>> productsAsync) => productsAsync.when(
      data: (final List<ProductModel> products) {
        final lowStock = products.where((final ProductModel p) => p.totalStock < 10).take(3).toList();
        if (lowStock.isEmpty) return const Text('Inventory levels are healthy.');

        return Column(
          children: lowStock.map((final ProductModel p) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.red[50], child: const Icon(Icons.warning, color: Colors.red, size: 20)),
            title: Text(p.name),
            subtitle: Text('SKU: ${p.sku ?? "N/A"}'),
            trailing: Text('${p.totalStock.toStringAsFixed(0)} units', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (final e, _) => const SizedBox.shrink(),
    );
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(final BuildContext context) => Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 12.h),
          Text(value, style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600])),
        ],
      ),
    );
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppConfig.primaryColor),
            SizedBox(height: 8.h),
            Text(label, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
}
