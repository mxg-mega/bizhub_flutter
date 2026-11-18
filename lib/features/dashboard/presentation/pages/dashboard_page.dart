import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/currency_provider.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../pos/data/models/sale_model.dart';
import '../../../pos/presentation/providers/sales_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final currency = ref.watch(activeDisplayCurrencyProvider);
    final offline = ref.watch(appSettingsNotifierProvider).offlineModeEnabled;
    final authState = ref.watch(authProvider);
    final productsAsync = ref.watch(productListProvider);
    final salesAsync = ref.watch(salesHistoryProvider);
    final name = authState.user?.name ?? 'there';
    final businessName = authState.activeBusiness?.name;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: CommonAppBar(
        actions: [
          _DashboardStatusPill(offline: offline, palette: palette),
          SizedBox(width: 12.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productListProvider);
          ref.invalidate(salesHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name, businessName, palette),
              SizedBox(height: 24.h),
              _buildKpiSection(
                productsAsync,
                salesAsync,
                currency.symbol,
                palette,
              ),
              SizedBox(height: 28.h),
              _buildSectionTitle('Quick Actions', palette),
              SizedBox(height: 12.h),
              _buildQuickActions(palette),
              SizedBox(height: 28.h),
              _buildSalesOverview(salesAsync, currency.symbol, palette),
              SizedBox(height: 20.h),
              _buildRecentSales(salesAsync, currency.symbol, palette, context),
              SizedBox(height: 20.h),
              _buildLowStock(productsAsync, palette, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    final String name,
    final String? businessName,
    final AppPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Center',
          style: GoogleFonts.inter(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Welcome back, $name',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: palette.textSecondary,
          ),
        ),
        if (businessName != null && businessName.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights, size: 14.sp, color: palette.primary),
                SizedBox(width: 6.w),
                Text(
                  businessName,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(final String title, final AppPalette palette) =>
      Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      );

  Widget _buildKpiSection(
    final AsyncValue<List<ProductModel>> productsAsync,
    final AsyncValue<List<SaleModel>> salesAsync,
    final String symbol,
    final AppPalette palette,
  ) {
    final products = productsAsync.value ?? const <ProductModel>[];
    final sales = salesAsync.value ?? const <SaleModel>[];
    final now = DateTime.now();
    final today = sales
        .where((final sale) => _isSameDay(sale.date, now))
        .toList();
    final todayRevenue = today.fold<double>(
      0.0,
      (final sum, final sale) => sum + sale.total,
    );
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final weekRevenue = sales
        .where((final sale) => !sale.date.isBefore(weekStart))
        .fold<double>(0.0, (final sum, final sale) => sum + sale.total);
    final inventoryValue = products.fold<double>(
      0.0,
      (final sum, final product) => sum + (product.price * product.totalStock),
    );
    final lowStockCount = products
        .where(
          (final product) => !product.isArchived && product.totalStock < 10,
        )
        .length;
    final averageSale = today.isEmpty ? 0.0 : todayRevenue / today.length;

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: crossAxisCount == 4 ? 1.4 : 1.05,
          children: [
            _MetricCard(
              label: 'Sales Today',
              value: '$symbol${todayRevenue.toStringAsFixed(0)}',
              subtitle: '${today.length} transactions',
              icon: Icons.payments_outlined,
              color: palette.primary,
              palette: palette,
            ),
            _MetricCard(
              label: 'Average Sale',
              value: '$symbol${averageSale.toStringAsFixed(0)}',
              subtitle: 'Today',
              icon: Icons.show_chart,
              color: palette.warning,
              palette: palette,
            ),
            _MetricCard(
              label: 'Inventory Value',
              value: '$symbol${inventoryValue.toStringAsFixed(0)}',
              subtitle: '${products.length} products',
              icon: Icons.inventory_2_outlined,
              color: palette.success,
              palette: palette,
            ),
            _MetricCard(
              label: 'Low Stock',
              value: '$lowStockCount',
              subtitle: 'Items need restock',
              icon: Icons.warning_amber_rounded,
              color: lowStockCount > 0 ? palette.error : palette.success,
              palette: palette,
            ),
            if (crossAxisCount == 4)
              _MetricCard(
                label: 'Weekly Sales',
                value: '$symbol${weekRevenue.toStringAsFixed(0)}',
                subtitle: 'Last 7 days',
                icon: Icons.calendar_month_outlined,
                color: palette.primary,
                palette: palette,
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(final AppPalette palette) => SizedBox(
    height: 104.h,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _QuickActionCard(
          label: 'New Sale',
          icon: Icons.point_of_sale,
          color: palette.accent,
          onTap: (final context) => context.go('/pos'),
          palette: palette,
        ),
        _QuickActionCard(
          label: 'Add Product',
          icon: Icons.add_box_outlined,
          color: palette.primary,
          onTap: (final context) => context.pushNamed('add-edit-product'),
          palette: palette,
        ),
        _QuickActionCard(
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          color: palette.success,
          onTap: (final context) => context.go('/inventory'),
          palette: palette,
        ),
        _QuickActionCard(
          label: 'Customers',
          icon: Icons.people_outline,
          color: palette.warning,
          onTap: (final context) => context.go('/customers'),
          palette: palette,
        ),
        _QuickActionCard(
          label: 'Zakat',
          icon: Icons.account_balance_wallet_outlined,
          color: palette.error,
          onTap: (final context) => context.go('/zakat'),
          palette: palette,
        ),
      ],
    ),
  );

  Widget _buildSalesOverview(
    final AsyncValue<List<SaleModel>> salesAsync,
    final String symbol,
    final AppPalette palette,
  ) {
    final sales = salesAsync.value ?? const <SaleModel>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List<DateTime>.generate(
      7,
      (final index) => today.subtract(Duration(days: 6 - index)),
    );
    final values = days.map((final day) {
      return sales
          .where(
            (final sale) =>
                _isSameDay(sale.date, day) && sale.status != 'Draft',
          )
          .fold<double>(0.0, (final sum, final sale) => sum + sale.total);
    }).toList();
    final maxValue = values.fold<double>(
      0.0,
      (final max, final value) => value > max ? value : max,
    );
    final total = values.fold<double>(
      0.0,
      (final sum, final value) => sum + value,
    );

    return _SectionCard(
      title: 'Sales Overview',
      subtitle: 'Last 7 days',
      trailing: Text(
        '$symbol${total.toStringAsFixed(0)}',
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: palette.primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      palette: palette,
      child: SizedBox(
        height: 118.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (final index) {
            final value = values[index];
            final height = maxValue <= 0
                ? 6.h
                : 10.h + (value / maxValue) * 74.h;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value > 0 ? value.toStringAsFixed(0) : '',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: palette.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  width: 22.w,
                  height: height,
                  decoration: BoxDecoration(
                    color: index == 6 ? palette.accent : palette.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  DateFormat('E').format(days[index]).substring(0, 2),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentSales(
    final AsyncValue<List<SaleModel>> salesAsync,
    final String symbol,
    final AppPalette palette,
    final BuildContext context,
  ) {
    return _SectionCard(
      title: 'Recent Sales',
      subtitle: 'Latest transactions',
      trailing: TextButton(
        onPressed: () => context.go('/sales-history'),
        child: const Text('View All'),
      ),
      palette: palette,
      child: salesAsync.when(
        data: (final sales) {
          if (sales.isEmpty) {
            return _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No sales recorded yet',
              palette: palette,
            );
          }
          return Column(
            children: sales.take(4).map((final sale) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        size: 20.sp,
                        color: palette.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.referenceNumber ??
                                'Sale #${sale.id.substring(0, 6).toUpperCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            '${sale.customer ?? 'Walk-in Customer'} • ${DateFormat('hh:mm a').format(sale.date)}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$symbol${sale.total.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
        error: (final error, final _) => _EmptyState(
          icon: Icons.error_outline,
          message: 'Unable to load sales',
          palette: palette,
        ),
      ),
    );
  }

  Widget _buildLowStock(
    final AsyncValue<List<ProductModel>> productsAsync,
    final AppPalette palette,
    final BuildContext context,
  ) {
    return _SectionCard(
      title: 'Low Stock Items',
      subtitle: 'Restock soon',
      trailing: TextButton(
        onPressed: () => context.go('/inventory'),
        child: const Text('View Inventory'),
      ),
      palette: palette,
      child: productsAsync.when(
        data: (final products) {
          final lowStock = products
              .where(
                (final product) =>
                    !product.isArchived && product.totalStock < 10,
              )
              .take(4)
              .toList();
          if (lowStock.isEmpty) {
            return _EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Inventory levels are healthy',
              palette: palette,
            );
          }
          return Column(
            children: lowStock.map((final product) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: palette.lowStock,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 20.sp,
                        color: palette.warning,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            product.sku?.isNotEmpty == true
                                ? 'SKU: ${product.sku}'
                                : 'No SKU',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: palette.lowStock,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${product.totalStock.toStringAsFixed(0)} left',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: palette.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (final error, final _) => const SizedBox.shrink(),
      ),
    );
  }

  bool _isSameDay(final DateTime first, final DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _DashboardStatusPill extends StatelessWidget {
  final bool offline;
  final AppPalette palette;

  const _DashboardStatusPill({required this.offline, required this.palette});

  @override
  Widget build(final BuildContext context) {
    final color = offline ? palette.offline : palette.success;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            offline ? Icons.cloud_off : Icons.cloud_done_outlined,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 5.w),
          Text(
            offline ? 'Offline' : 'Synced',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppPalette palette;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 16.sp, color: color),
              ),
              Icon(Icons.north_east, size: 13.sp, color: palette.textSecondary),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: palette.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final void Function(BuildContext context) onTap;
  final AppPalette palette;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 92.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => onTap(context),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: palette.outline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, size: 18.sp, color: color),
                ),
                SizedBox(height: 8.h),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget child;
  final AppPalette palette;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.child,
    required this.palette,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final AppPalette palette;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.palette,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: palette.textSecondary),
          SizedBox(width: 8.w),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
