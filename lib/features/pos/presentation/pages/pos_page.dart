import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../providers/cart_provider.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/presentation/widgets/enhanced_unit_selector.dart';
import '../widgets/customer_selector.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../../../../core/services/receipt_service.dart';
import '../../../../core/services/receipt/receipt_generator.dart';
import '../../../receipts/presentation/providers/receipt_providers.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/business_model.dart';
import '../../data/models/sale_model.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: productsAsync.when(
                    data: (products) => _buildProductGrid(products),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
          // VerticalDivider(width: 1, color: Colors.grey[300]),
          // Expanded(
          //   flex: 2,
          //   child: _buildCartPanel(cart),
          // ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            top: 0,
            right: 1,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(cart.items.length.toString()),
            ),
          ),
          FloatingActionButton.extended(
            // onPressed: cart.items.isEmpty
            //     ? null
            //     : () => showCupertinoSheet(
            //         context: context,
            //         builder: (context) => _buildCartPanel(cart),
            //         showDragHandle: true,
            //         enableDrag: true,
            //       ),
            onPressed: () => showModalBottomSheet(
              useSafeArea: true,
              isScrollControlled: true,
              context: context,
              builder: (context) => _buildCartPanel(cart),
              showDragHandle: true,
              enableDrag: true,
            ),
            label: const Text(
              'Checkout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.payment),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
    padding: EdgeInsets.all(16.w),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name or SKU...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        SizedBox(width: 12.w),
        _buildScanButton(),
      ],
    ),
  );

  Widget _buildScanButton() => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: IconButton(
      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BarcodeScannerWidget(
              onScan: (sku) {
                _handleBarcodeScanned(sku);
              },
            ),
          ),
        );
      },
    ),
  );

  void _handleBarcodeScanned(String sku) {
    final products = ref.read(productListProvider).value ?? [];
    try {
      final product = products.firstWhere(
        (p) => p.sku?.toLowerCase() == sku.toLowerCase(),
      );
      ref
          .read(cartProvider.notifier)
          .addItem(product, product.unitChain?.baseUnit ?? 'Piece', 1.0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added ${product.name} to cart')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product with SKU $sku not found')),
      );
    }
  }

  Widget _buildProductGrid(final List<ProductModel> products) {
    print(
      products
          .asMap()
          .entries
          .map(
            (e) =>
                '${e.key}: ${e.value.priceConfigs?.first.price} (SKU: ${e.value.sku ?? 'N/A'}, Stock: ${e.value.totalStock})',
          )
          .join('\n'),
    );
    final filtered = products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false),
        )
        .toList();

    if (filtered.isEmpty) return const Center(child: Text('No products found'));

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return _ProductPosCard(product: product);
      },
    );
  }

  Widget _buildCartPanel(final CartState cart) => Column(
    children: [
      Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checkout',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            CustomerSelector(
              selectedCustomerId: cart.customerId,
              onCustomerSelected: (customer) =>
                  ref.read(cartProvider.notifier).setCustomer(customer?.id),
            ),
          ],
        ),
      ),
      const Divider(),
      Expanded(
        child: cart.items.isEmpty
            ? const Center(child: Text('Cart is empty'))
            : ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} x ${item.unit}'),
                    trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                    onLongPress: () => ref
                        .read(cartProvider.notifier)
                        .removeItem(item.productId, item.unit),
                  );
                },
              ),
      ),
      _buildCheckoutSummary(cart),
    ],
  );

  Widget _buildCheckoutSummary(final CartState cart) => Container(
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Column(
      children: [
        _summaryRow('Subtotal', cart.subtotal),
        _summaryRow('Tax', cart.taxAmount),
        const Divider(height: 24),
        _summaryRow('Total', cart.total, isTotal: true),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () => _processCheckout('cash', isDraft: true),
                child: const Text('Draft'),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () => _showCheckoutDialog(cart),
                child: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summaryRow(String label, double value, {bool isTotal = false}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18.sp : 14.sp,
              ),
            ),
          ],
        ),
      );

  void _showCheckoutDialog(final CartState cart) {
    final business = ref.read(currentBusinessProvider);
    final requireApproval = business?.settings?['requireApproval'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requireApproval
                  ? 'Workflow Enabled: This sale will require manager approval before inventory is deducted.'
                  : 'Select payment method and confirm transaction.',
            ),
            if (cart.customerId == null)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: const Text(
                  '* Select a customer to enable "On Credit" payment.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _processCheckout('cash'),
                  child: Text(
                    requireApproval ? 'Submit for Approval' : 'Pay with Cash',
                  ),
                ),
              ),
              if (cart.customerId != null) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _processCheckout('on_credit'),
                    child: const Text('Sell on Credit'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout(String method, {bool isDraft = false}) async {
    try {
      final sale = await ref
          .read(cartProvider.notifier)
          .checkout(method, 'main', isDraft: isDraft);
      final business = ref.read(currentBusinessProvider);
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showSuccessDialog(sale, business!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSuccessDialog(final SaleModel sale, final BusinessModel business) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(
          sale.status == 'Draft' ? Icons.edit_note : Icons.check_circle,
          color: sale.status == 'Draft' ? Colors.orange : Colors.green,
          size: 48,
        ),
        content: Text(
          sale.status == 'Draft'
              ? 'Sale saved as Draft.'
              : (sale.status == 'PendingPayment'
                    ? 'Sale submitted for approval.'
                    : 'Sale completed successfully!'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          if (sale.status == 'Paid' || sale.status == 'Pending') ...[
            TextButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Thermal'),
              onPressed: () async {
                final template = await ref.read(
                  activeReceiptTemplateProvider.future,
                );
                ReceiptGenerator().printThermal(sale, business, template);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
              onPressed: () async {
                final template = await ref.read(
                  activeReceiptTemplateProvider.future,
                );
                ReceiptService.generateAndShareReceipt(
                  sale,
                  business,
                ); // Legacy for now
                // Or better: ReceiptGenerator().generatePdf(sale, business, template);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductPosCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductPosCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: () => _showAddToCart(context, ref),
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '\$${product.calculatePriceForUnit(product.unitChain?.baseUnit ?? 'Piece').toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${product.totalStock.toStringAsFixed(0)} in stock',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );

  void _showAddToCart(BuildContext context, WidgetRef ref) {
    String selectedUnit = product.unitChain?.baseUnit ?? 'Piece';
    final controller = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.all(
            24.w,
          ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add to Cart',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              EnhancedUnitSelector(
                product: product,
                selectedUnit: selectedUnit,
                onUnitSelected: (val) => setState(() => selectedUnit = val),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(controller.text) ?? 1.0;
                    ref
                        .read(cartProvider.notifier)
                        .addItem(product, selectedUnit, qty);
                    Navigator.pop(context);
                  },
                  child: const Text('Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
