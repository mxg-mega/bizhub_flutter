import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/product_model.dart';
import '../providers/inventory_providers.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/services/report_service.dart';

class InventoryDashboardPage extends ConsumerWidget {
  const InventoryDashboardPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: CommonAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Inventory',
            onPressed: () => context.push('/import-wizard'),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Inventory',
            onPressed: () async {
              final products = productsAsync.value ?? [];
              final file = await ReportService.generateInventoryCsv(products);
              await Share.shareXFiles([XFile(file.path)], text: 'Inventory Backup');
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => _buildProductList(context, ref, products),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/inventory/add-edit'),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, WidgetRef ref, List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products in inventory.'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final lowStock = product.totalStock < 10;

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: lowStock ? Colors.red[200]! : Colors.grey[200]!),
          ),
          child: ListTile(
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('SKU: ${product.sku ?? 'N/A'} • ${product.category ?? 'Uncategorized'}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.totalStock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: lowStock ? Colors.red : Colors.green,
                    fontSize: 16.sp,
                  ),
                ),
                Text('in stock', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
              ],
            ),
            onTap: () => context.go('/inventory/add-edit', extra: product),
          ),
        );
      },
    );
  }
}
