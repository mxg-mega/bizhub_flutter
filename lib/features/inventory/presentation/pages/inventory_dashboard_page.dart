import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/product_model.dart';
import '../providers/inventory_providers.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/config/router/app_router.dart';
import '../../../../core/services/report_service.dart';
import '../../../../shared/providers/auth_provider.dart';

class InventoryDashboardPage extends ConsumerStatefulWidget {
  const InventoryDashboardPage({super.key});

  @override
  ConsumerState<InventoryDashboardPage> createState() => _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends ConsumerState<InventoryDashboardPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(final BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonAppBar(
        hasTitle: true,
        title: 'Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import',
            onPressed: () => context.push(AppRouter.importWizard),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export',
            onSelected: (final value) => _handleExport(context, ref, value, productsAsync.value ?? []),
            itemBuilder: (final context) => [
              const PopupMenuItem(value: 'pdf', child: Text('PDF Stock Health')),
              const PopupMenuItem(value: 'csv', child: Text('CSV Full Backup')),
            ],
          ),
        ],
      ),
      body: productsAsync.when(
        data: (final products) {
          final filteredProducts = products.where((final p) {
            final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                 (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              _buildSummaryStats(products),
              _buildSearchAndFilters(categoriesAsync),
              Expanded(
                child: _buildProductList(context, filteredProducts),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, final _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('${AppRouter.inventory}/add-edit'),
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryStats(final List<ProductModel> products) {
    final lowStockCount = products.where((final p) => p.totalStock < 10).length;
    final totalValue = products.fold(0.0, (final sum, final p) => sum + (p.totalStock * p.cost));

    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Total Items', products.length.toString(), Colors.blue),
          _buildStatCard('Low Stock', lowStockCount.toString(), Colors.orange),
          _buildStatCard('Total Value', '\$${totalValue.toStringAsFixed(0)}', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(final String label, final String value, final Color color) {
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(value, style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(final AsyncValue<List<String>> categoriesAsync) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            onChanged: (final val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search products or SKU...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        categoriesAsync.when(
          data: (final categories) => SizedBox(
            height: 40.h,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (final context, final index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (final val) => setState(() => _selectedCategory = category),
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black87,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  ),
                );
              },
            ),
          ),
          loading: () => const SizedBox(),
          error: (_, final __) => const SizedBox(),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildProductList(final BuildContext context, final List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64.sp, color: Colors.grey[200]),
            SizedBox(height: 16.h),
            Text('No products found', style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: products.length,
      itemBuilder: (final context, final index) {
        final product = products[index];
        final isLowStock = product.totalStock < 10;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isLowStock ? Colors.red[100]! : Colors.grey[100]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.shopping_bag_outlined, color: Colors.grey[400]),
            ),
            title: Text(
              product.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  'SKU: ${product.sku ?? 'N/A'} • ${product.category ?? 'General'}',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                if (isLowStock) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'LOW STOCK',
                      style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.totalStock}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: isLowStock ? Colors.red : Colors.black87,
                  ),
                ),
                Text('in stock', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey)),
              ],
            ),
            onTap: () => context.push('${AppRouter.inventory}/add-edit', extra: product),
          ),
        );
      },
    );
  }

  Future<void> _handleExport(final BuildContext context, final WidgetRef ref, final String format, final List<ProductModel> products) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    if (format == 'pdf') {
      final file = await ReportService.generateStockHealthPdf(products, business);
      await Share.shareXFiles([XFile(file.path)], text: 'Stock Health Report');
    } else {
      final file = await ReportService.generateInventoryCsv(products);
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Backup');
    }
  }
}
