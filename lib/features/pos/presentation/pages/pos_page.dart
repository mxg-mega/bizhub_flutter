import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/config/router/app_router.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../providers/cart_provider.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/presentation/widgets/enhanced_unit_selector.dart';
import '../widgets/customer_selector.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../../../../shared/providers/auth_provider.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isCartGridView = false;
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          categoriesAsync.when(
            data: (final categories) => _buildCategoryFilters(categories),
            loading: () => const SizedBox.shrink(),
            error: (_, final __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: productsAsync.when(
              data: (final products) => _buildProductGrid(products),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (final e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: cart.items.isEmpty
          ? null
          : Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton.extended(
                  onPressed: () => showModalBottomSheet(
                    useSafeArea: true,
                    isScrollControlled: true,
                    context: context,
                    builder: (final context) => _buildCartPanel(cart),
                    showDragHandle: true,
                    enableDrag: true,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  label: Text(
                    'Checkout • \$${cart.total.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(minWidth: 24.w, minHeight: 24.w),
                    child: Center(
                      child: Text(
                        cart.items.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilters(final List<String> categories) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 8.h),
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
              onSelected: (final selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search products or SKU...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20.sp),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              onChanged: (final val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        _buildScanButton(),
      ],
    ),
  );

  Widget _buildScanButton() => Container(
    height: 48.h,
    width: 48.h,
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: IconButton(
      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (final context) => BarcodeScannerWidget(
              onScan: (final sku) {
                _handleBarcodeScanned(sku);
              },
            ),
          ),
        );
      },
    ),
  );

  void _handleBarcodeScanned(final String sku) {
    final products = ref.read(productListProvider).value ?? [];
    try {
      final product = products.firstWhere(
        (final p) => p.sku?.toLowerCase() == sku.toLowerCase(),
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
            (final e) =>
                '${e.key}: ${e.value.priceConfigs?.first.price} (SKU: ${e.value.sku ?? 'N/A'}, Stock: ${e.value.totalStock})',
          )
          .join('\n'),
    );
    final filtered = products
        .where(
          (final p) =>
              (p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) &&
              (_selectedCategory == 'All' || p.category == _selectedCategory),
        )
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'No products found',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.8,
      ),
      itemCount: filtered.length,
      itemBuilder: (final context, final index) {
        final product = filtered[index];
        return _ProductPosCard(product: product);
      },
    );
  }

  Widget _buildCartPanel(final CartState cart) => Container(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Basket (${cart.items.length})',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (cart.items.isNotEmpty)
                IconButton(
                  onPressed: () => setState(() => _isCartGridView = !_isCartGridView),
                  icon: Icon(_isCartGridView ? Icons.view_list : Icons.grid_view),
                  tooltip: _isCartGridView ? 'Switch to List' : 'Switch to Grid',
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: CustomerSelector(
            selectedCustomerId: cart.customerId,
            onCustomerSelected: (final customer) =>
                ref.read(cartProvider.notifier).setCustomer(customer?.id),
          ),
        ),
        SizedBox(height: 12.h),
        const Divider(height: 1),
        Expanded(
          child: cart.items.isEmpty
              ? _buildEmptyCartState()
              : _isCartGridView ? _buildCartGrid(cart) : _buildCartList(cart),
        ),
        _buildCheckoutSummary(cart),
      ],
    ),
  );

  Widget _buildEmptyCartState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shopping_basket_outlined,
          size: 80.sp,
          color: Colors.grey[300],
        ),
      ),
      SizedBox(height: 24.h),
      Text(
        'Your basket is empty',
        style: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        'Add some products to start a sale',
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.grey,
        ),
      ),
    ],
  );

  Widget _buildCartList(final CartState cart) => ListView.separated(
    padding: EdgeInsets.all(20.w),
    itemCount: cart.items.length,
    separatorBuilder: (final context, final index) => SizedBox(height: 12.h),
    itemBuilder: (final context, final index) {
      final item = cart.items[index];
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.inventory_2_outlined, color: Colors.blue[200]),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${item.quantity} x ${item.unit} • \$${item.unitPrice.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).removeItem(item.productId, item.unit),
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('Remove', style: TextStyle(color: Colors.red, fontSize: 11.sp)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _buildCartGrid(final CartState cart) => GridView.builder(
    padding: EdgeInsets.all(20.w),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.2,
    ),
    itemCount: cart.items.length,
    itemBuilder: (final context, final index) {
      final item = cart.items[index];
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).removeItem(item.productId, item.unit),
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.quantity} ${item.unit}', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _buildCheckoutSummary(final CartState cart) => Container(
    padding: EdgeInsets.all(24.w),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
    ),
    child: Column(
      children: [
        _summaryRow('Subtotal', cart.subtotal),
        _summaryRow('Tax', cart.taxAmount),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: _summaryRow('Total Amount', cart.total, isTotal: true),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56.h,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => _processCheckout('cash', isDraft: true),
                  child: Text(
                    'Save Draft',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => _showCheckoutDialog(cart),
                  child: Text(
                    'Complete Checkout',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summaryRow(final String label, final double value, {final bool isTotal = false}) =>
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
      builder: (final context) => AlertDialog(
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

  Future<void> _processCheckout(final String method, {final bool isDraft = false}) async {
    try {
      final sale = await ref
          .read(cartProvider.notifier)
          .checkout(method, 'main', isDraft: isDraft);
      final business = ref.read(currentBusinessProvider);
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        context.push(AppRouter.saleSuccess, extra: {
          'sale': sale,
          'business': business,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Success page replaces this dialog
}

class _ProductPosCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductPosCard({required this.product});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => GestureDetector(
    onTap: () => _showAddToCart(context, ref),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50], // Placeholder for image background
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Hero(
                tag: 'product-${product.id}',
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 48.sp,
                    color: Colors.blue[200],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.calculatePriceForUnit(product.unitChain?.baseUnit ?? 'Piece').toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: product.totalStock > 0 ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        product.totalStock.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: product.totalStock > 0 ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _showAddToCart(final BuildContext context, final WidgetRef ref) {
    String selectedUnit = product.unitChain?.baseUnit ?? 'Piece';
    final controller = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => Padding(
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
                onUnitSelected: (final val) => setState(() => selectedUnit = val),
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
