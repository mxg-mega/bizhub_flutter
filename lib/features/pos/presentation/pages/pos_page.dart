import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/data/models/location_model.dart';
import '../providers/cart_provider.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/presentation/widgets/enhanced_unit_selector.dart';
import '../widgets/customer_selector.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../../data/models/sale_item_model.dart';
import 'sale_success_page.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/currency_provider.dart';
import '../../../../shared/providers/app_settings_provider.dart';

double availableBaseStock(
  final ProductModel product,
  final String? locationId,
  final List<SaleItemModel> items,
) {
  final stock = locationId == null
      ? product.totalStock
      : (product.stockByLocation[locationId] ?? 0.0);
  final baseUnit = product.unitChain?.baseUnit ?? 'Piece';
  final reserved = items
      .where((final item) => item.productId == product.id)
      .fold<double>(
        0.0,
        (final sum, final item) =>
            sum +
            item.quantity *
                (product.unitChain?.getFactor(item.unit, baseUnit) ?? 1.0),
      );
  final available = stock - reserved;
  return available > 0 ? available : 0.0;
}

String formatPosQuantity(final double quantity) =>
    quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2);

double convertPosQuantity(
  final ProductModel product,
  final String fromUnit,
  final String toUnit,
  final double quantity,
) {
  if (fromUnit == toUnit || product.unitChain == null) return quantity;
  final chain = product.unitChain!;
  final baseUnit = chain.baseUnit ?? fromUnit;
  final toBaseFactor = chain.getFactor(fromUnit, baseUnit);
  final fromBaseFactor = chain.getFactor(toUnit, baseUnit);
  if (toBaseFactor <= 0 || fromBaseFactor <= 0) return quantity;
  return quantity * toBaseFactor / fromBaseFactor;
}

String posPaymentLabel(final String method) {
  switch (method) {
    case 'card':
      return 'Card';
    case 'bank_transfer':
      return 'Bank Transfer';
    case 'on_credit':
      return 'On Credit';
    default:
      return 'Cash';
  }
}

class _PosStatusPill extends ConsumerWidget {
  const _PosStatusPill();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final offline = ref.watch(appSettingsNotifierProvider).offlineModeEnabled;
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

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isCartGridView = false;
  bool _isCartSummaryExpanded = false;
  String? _selectedLocationId;
  String _paymentMethod = 'cash';
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
    final currency = ref.watch(activeDisplayCurrencyProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: CommonAppBar(
        actions: [
          const _PosStatusPill(),
          SizedBox(width: 12.w),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          locationsAsync.when(
            data: (final locations) => _buildLocationSelector(locations),
            loading: () => const SizedBox.shrink(),
            error: (_, final __) => const SizedBox.shrink(),
          ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cart.items.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                height: 60.h,
                child: Material(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(18.r),
                  elevation: 6,
                  child: InkWell(
                    onTap: _openCartSheet,
                    borderRadius: BorderRadius.circular(18.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text(
                              '${cart.items.length}',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: palette.onAccent,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Cart (${cart.items.length} items)',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: palette.onPrimary.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${formatPosQuantity(cart.items.fold(0.0, (final sum, final item) => sum + item.quantity))} units',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: palette.onPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${currency.symbol}${cart.total.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: palette.onPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: palette.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final sheetContext) => StatefulBuilder(
        builder: (final context, final setSheetState) => FractionallySizedBox(
          heightFactor: 0.95,
          child: Consumer(
            builder: (final context, final ref, final child) =>
                _buildCartPanel(ref.watch(cartProvider), setSheetState),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(final List<LocationModel> locations) {
    if (locations.isEmpty) return const SizedBox.shrink();
    final palette = AppTheme.paletteOf(context);
    // Auto-select the first location if none selected
    if (_selectedLocationId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedLocationId = locations.first.id);
      });
    }
    return Container(
      height: 42.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 4.h),
      child: Row(
        children: [
          Icon(Icons.store_outlined, size: 16.sp, color: palette.textSecondary),
          SizedBox(width: 6.w),
          Text(
            'Location:',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: palette.textSecondary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: locations.map((final loc) {
                  final isSelected = _selectedLocationId == loc.id;
                  return Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLocationId = loc.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? palette.primary : palette.card,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected
                                ? palette.primary
                                : palette.outline,
                          ),
                        ),
                        child: Text(
                          loc.name,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? palette.onPrimary
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(final List<String> categories) {
    final palette = AppTheme.paletteOf(context);
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
              selectedColor: palette.primary,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? palette.onPrimary : palette.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected ? palette.primary : palette.outline,
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

  Widget _buildSearchBar() {
    final palette = AppTheme.paletteOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                  hintStyle: GoogleFonts.inter(color: palette.textSecondary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: palette.textSecondary,
                    size: 20.sp,
                  ),
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
  }

  Widget _buildScanButton() {
    final palette = AppTheme.paletteOf(context);
    return Container(
      height: 48.h,
      width: 48.h,
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.qr_code_scanner, color: palette.onPrimary, size: 22),
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
  }

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
    final selectedLocation = _selectedLocationId;
    final palette = AppTheme.paletteOf(context);
    final filtered = products
        .where(
          (final p) =>
              (p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                      false)) &&
              (_selectedCategory == 'All' || p.category == _selectedCategory),
        )
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.sp, color: palette.outline),
            SizedBox(height: 16.h),
            Text(
              'No products found',
              style: GoogleFonts.inter(
                color: palette.textSecondary,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: crossAxisCount > 2 ? 0.92 : 0.82,
          ),
          itemCount: filtered.length,
          itemBuilder: (final context, final index) {
            final product = filtered[index];
            return _ProductPosCard(
              product: product,
              locationId: selectedLocation,
            );
          },
        );
      },
    );
  }

  Widget _buildCartPanel(final CartState cart, [final StateSetter? setSheetState]) {
    final palette = AppTheme.paletteOf(context);
    final symbol = ref.watch(activeDisplayCurrencyProvider).symbol;
    final totalUnits = cart.items.fold(
      0.0,
      (final sum, final item) => sum + item.quantity,
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: palette.outline,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Order',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${cart.items.length} items • ${formatPosQuantity(totalUnits)} units',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cart.items.isNotEmpty) ...[
                  IconButton(
                    onPressed: _showClearCartDialog,
                    icon: Icon(Icons.delete_sweep_outlined, color: palette.error),
                    tooltip: 'Clear Cart',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isCartGridView = !_isCartGridView);
                      setSheetState?.call(() {});
                    },
                    icon: Icon(
                      _isCartGridView ? Icons.view_list : Icons.grid_view,
                    ),
                    tooltip: _isCartGridView
                        ? 'Switch to List'
                        : 'Switch to Grid',
                    color: palette.primary,
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: palette.textSecondary),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: CustomerSelector(
              selectedCustomerId: cart.customerId,
              onCustomerSelected: (final customer) => ref
                  .read(cartProvider.notifier)
                  .setCustomer(customer?.id, customer?.name),
            ),
          ),
          SizedBox(height: 8.h),
          Divider(height: 1, color: palette.outline.withValues(alpha: 0.5)),
          Expanded(
            child: cart.items.isEmpty
                ? _buildEmptyCartState(palette)
                : _isCartGridView
                ? _buildCartGrid(cart, symbol, palette)
                : _buildCartList(cart, symbol, palette),
          ),
          _buildCheckoutSummary(cart, symbol, palette, setSheetState),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState(final AppPalette palette) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shopping_basket_outlined,
          size: 80.sp,
          color: palette.outline,
        ),
      ),
      SizedBox(height: 24.h),
      Text(
        'Your basket is empty',
        style: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        'Add some products to start a sale',
        style: GoogleFonts.inter(fontSize: 14.sp, color: palette.textSecondary),
      ),
    ],
  );

  Widget _buildCartList(
    final CartState cart,
    final String symbol,
    final AppPalette palette,
  ) => ListView.separated(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
    itemCount: cart.items.length,
    separatorBuilder: (final context, final index) => SizedBox(height: 10.h),
    itemBuilder: (final context, final index) {
      final item = cart.items[index];
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: palette.outline.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: palette.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '$symbol${item.unitPrice.toStringAsFixed(2)} / ${item.unit}',
                        style: GoogleFonts.inter(
                          color: palette.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '$symbol${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: palette.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuantityControls(item, cart, palette),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditItemDialog(item),
                      icon: Icon(Icons.edit_outlined, size: 18.sp),
                      color: palette.primary,
                      tooltip: 'Edit price/unit',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(6.w),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(cartProvider.notifier)
                            .removeItem(item.productId, item.unit);
                      },
                      icon: Icon(Icons.delete_outline, size: 18.sp),
                      color: palette.error,
                      tooltip: 'Remove',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(6.w),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _buildQuantityControls(
    final SaleItemModel item,
    final CartState cart,
    final AppPalette palette,
  ) => Container(
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: palette.outline.withValues(alpha: 0.6)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _quantityButton(Icons.remove, palette, () {
          HapticFeedback.selectionClick();
          ref
              .read(cartProvider.notifier)
              .updateQuantity(item.productId, item.unit, item.quantity - 1);
        }),
        Container(
          constraints: BoxConstraints(minWidth: 36.w),
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Text(
            formatPosQuantity(item.quantity),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              color: palette.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _quantityButton(Icons.add, palette, () {
          final next = item.quantity + 1;
          if (next > _maxQuantityFor(item, cart)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No more stock available for ${item.name}')),
            );
            return;
          }
          HapticFeedback.selectionClick();
          ref
              .read(cartProvider.notifier)
              .updateQuantity(item.productId, item.unit, next);
        }),
      ],
    ),
  );

  Widget _quantityButton(
    final IconData icon,
    final AppPalette palette,
    final VoidCallback onPressed,
  ) => SizedBox(
    width: 32.w,
    height: 32.h,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16.sp),
      color: palette.primary,
      padding: EdgeInsets.zero,
    ),
  );

  double _maxQuantityFor(final SaleItemModel item, final CartState cart) {
    final products = ref.read(productListProvider).value ?? [];
    for (final product in products) {
      if (product.id != item.productId) continue;
      final baseUnit = product.unitChain?.baseUnit ?? 'Piece';
      final factor = product.unitChain?.getFactor(item.unit, baseUnit) ?? 1.0;
      final available = availableBaseStock(
        product,
        _selectedLocationId,
        cart.items,
      );
      return item.quantity + (factor > 0 ? available / factor : 0.0);
    }
    return double.infinity;
  }

  void _showEditItemDialog(final SaleItemModel item) {
    final palette = AppTheme.paletteOf(context);
    final symbol = ref.watch(activeDisplayCurrencyProvider).symbol;
    final quantityController = TextEditingController(
      text: formatPosQuantity(item.quantity),
    );
    final priceController = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );
    final maxQuantity = _maxQuantityFor(item, ref.read(cartProvider));

    showDialog<void>(
      context: context,
      builder: (final dialogContext) => StatefulBuilder(
        builder: (final dialogContext, final setState) {
          final quantity = double.tryParse(quantityController.text) ?? 0.0;
          final unitPrice = double.tryParse(priceController.text) ?? -1.0;
          final invalid =
              quantity <= 0 ||
              quantity > maxQuantity ||
              unitPrice < 0 ||
              !unitPrice.isFinite;
          return AlertDialog(
            title: Text('Edit ${item.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available: ${formatPosQuantity(maxQuantity)} ${item.unit}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: palette.textSecondary,
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantity (${item.unit})',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Unit price ($symbol)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (invalid)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Enter a quantity up to ${formatPosQuantity(maxQuantity)} ${item.unit} and a valid price',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: palette.error,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: invalid
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(
                              item.productId,
                              item.unit,
                              quantity,
                            );
                        ref
                            .read(cartProvider.notifier)
                            .updateItemPrice(
                              item.productId,
                              item.unit,
                              unitPrice,
                            );
                        Navigator.pop(dialogContext);
                      },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartGrid(
    final CartState cart,
    final String symbol,
    final AppPalette palette,
  ) => GridView.builder(
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
          color: palette.card,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(cartProvider.notifier)
                        .removeItem(item.productId, item.unit);
                  },
                  icon: Icon(Icons.close, size: 16.sp),
                  color: palette.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: palette.textSecondary,
                  ),
                ),
                Text(
                  '$symbol${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _buildCheckoutSummary(
    final CartState cart,
    final String symbol,
    final AppPalette palette, [
    final StateSetter? setSheetState,
  ]) {
    final canFinalize =
        cart.items.isNotEmpty &&
        (_paymentMethod != 'on_credit' || cart.hasCustomer);

    void update(final VoidCallback fn) {
      setState(fn);
      setSheetState?.call(fn);
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border(
          top: BorderSide(color: palette.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment method row (compact horizontal scrolling)
              _buildPaymentSelector(cart, palette, update),
              SizedBox(height: 8.h),

              // Expandable order breakdown toggle
              InkWell(
                onTap: () => update(
                  () => _isCartSummaryExpanded = !_isCartSummaryExpanded,
                ),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCartSummaryExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            size: 18.sp,
                            color: palette.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _isCartSummaryExpanded
                                ? 'Hide breakdown'
                                : 'Discount & breakdown',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: palette.textSecondary,
                            ),
                          ),
                          if (cart.discount > 0 || cart.taxRate > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                cart.discount > 0 ? 'Discounted' : 'Taxed',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: palette.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Subtotal: $symbol${cart.subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: palette.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isCartSummaryExpanded) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: palette.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: cart.items.isEmpty
                                  ? null
                                  : () => _showDiscountDialog(cart),
                              icon: Icon(
                                Icons.local_offer_outlined,
                                size: 14.sp,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 6.h,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              label: Text(
                                cart.discount > 0
                                    ? 'Disc: $symbol${cart.discount.toStringAsFixed(2)}'
                                    : 'Apply Discount',
                                style: TextStyle(fontSize: 11.sp),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tax 7.5%',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: palette.textSecondary,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: cart.taxRate > 0,
                                  onChanged: (final value) => ref
                                      .read(cartProvider.notifier)
                                      .setTaxRate(value ? 0.075 : 0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      _summaryRow('Subtotal', cart.subtotal, symbol, palette),
                      if (cart.discount > 0)
                        _summaryRow('Discount', -cart.discount, symbol, palette),
                      if (cart.taxRate > 0)
                        _summaryRow('Tax', cart.taxAmount, symbol, palette),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 10.h),

              // Final row: Total on left, Action buttons on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: palette.textSecondary,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$symbol${cart.total.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: palette.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  OutlinedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () => _processCheckout(_paymentMethod, isDraft: true),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text('Draft', style: TextStyle(fontSize: 13.sp)),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: canFinalize
                        ? () {
                            if (_paymentMethod == 'bank_transfer') {
                              _showBankTransferSheet(cart);
                              return;
                            }
                            _processCheckout(_paymentMethod);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Charge',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSelector(
    final CartState cart,
    final AppPalette palette, [
    final void Function(VoidCallback)? onUpdate,
  ]) {
    final methods = [
      ('cash', Icons.payments_outlined, 'Cash'),
      ('card', Icons.credit_card, 'Card'),
      ('bank_transfer', Icons.account_balance, 'Transfer'),
      ('on_credit', Icons.assignment_outlined, 'Credit'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: methods.map((final method) {
          final value = method.$1;
          final enabled = value != 'on_credit' || cart.hasCustomer;
          final selected = _paymentMethod == value;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              avatar: Icon(
                method.$2,
                size: 14.sp,
                color: selected ? palette.onPrimary : palette.textSecondary,
              ),
              label: Text(method.$3),
              selected: selected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              onSelected: enabled
                  ? (final next) {
                      if (next) {
                        if (onUpdate != null) {
                          onUpdate(() => _paymentMethod = value);
                        } else {
                          setState(() => _paymentMethod = value);
                        }
                      }
                    }
                  : null,
              selectedColor: palette.primary,
              backgroundColor: palette.surface,
              labelStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? palette.onPrimary : palette.textPrimary,
              ),
              side: BorderSide(
                color: selected ? palette.primary : palette.outline,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _summaryRow(
    final String label,
    final double value,
    final String symbol,
    final AppPalette palette, {
    final bool isTotal = false,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: 2.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 14.sp : 13.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? palette.primary : palette.textSecondary,
          ),
        ),
        Text(
          '$symbol${value.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            fontSize: isTotal ? 18.sp : 13.sp,
            color: isTotal ? palette.primary : palette.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  void _showDiscountDialog(final CartState cart) {
    final palette = AppTheme.paletteOf(context);
    final symbol = ref.watch(activeDisplayCurrencyProvider).symbol;
    final controller = TextEditingController(
      text: cart.discount > 0 ? cart.discount.toStringAsFixed(2) : '',
    );
    var discountType = 'fixed';

    showDialog<void>(
      context: context,
      builder: (final dialogContext) => StatefulBuilder(
        builder: (final dialogContext, final setState) {
          final rawValue = double.tryParse(controller.text) ?? 0.0;
          final amount = discountType == 'percentage'
              ? cart.subtotal * (rawValue / 100)
              : rawValue;
          final invalid = amount < 0 || !amount.isFinite;
          return AlertDialog(
            title: const Text('Apply Discount'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Fixed'),
                        selected: discountType == 'fixed',
                        onSelected: (_) =>
                            setState(() => discountType = 'fixed'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Percentage'),
                        selected: discountType == 'percentage',
                        onSelected: (_) =>
                            setState(() => discountType = 'percentage'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: discountType == 'fixed'
                        ? 'Discount amount ($symbol)'
                        : 'Discount percentage (%)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 8.h),
                if (!invalid)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'New total: $symbol${(cart.total - amount).clamp(0.0, cart.total).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (cart.discount > 0)
                TextButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).setDiscount(0);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Remove'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: invalid
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).setDiscount(amount);
                        Navigator.pop(dialogContext);
                      },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showClearCartDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (final dialogContext) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'This removes all items from the current order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(cartProvider.notifier).clear();
    }
  }

  /// Bank Transfer capture (web pos/page.tsx:357-367): bank name, account
  /// name, account number, routing number, transfer fee. Wire status starts
  /// 'pending'.
  void _showBankTransferSheet(final CartState cart) {
    final bankName = TextEditingController();
    final accountName = TextEditingController();
    final accountNumber = TextEditingController();
    final routingNumber = TextEditingController();
    final fee = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final sheetContext) => Padding(
        padding: EdgeInsets.all(24.w).copyWith(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Transfer Details',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: bankName,
              decoration: const InputDecoration(labelText: 'Bank Name'),
            ),
            TextField(
              controller: accountName,
              decoration: const InputDecoration(labelText: 'Account Name'),
            ),
            TextField(
              controller: accountNumber,
              decoration: const InputDecoration(labelText: 'Account Number'),
            ),
            TextField(
              controller: routingNumber,
              decoration: const InputDecoration(labelText: 'Routing Number'),
            ),
            TextField(
              controller: fee,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Transfer Fee'),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _processCheckout(
                    'bank_transfer',
                    transferDetails: {
                      'bankName': bankName.text.trim(),
                      'accountName': accountName.text.trim(),
                      'accountNumber': accountNumber.text.trim(),
                      'routingNumber': routingNumber.text.trim(),
                      'transferFee': double.tryParse(fee.text) ?? 0.0,
                      'status': 'pending',
                    },
                  );
                },
                child: const Text('Confirm Transfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckout(
    final String method, {
    final bool isDraft = false,
    final Map<String, dynamic>? transferDetails,
  }) async {
    try {
      // Web parity (pos/page.tsx:329): never invent a location id — abort
      // and ask the cashier to pick one.
      final locationId = _selectedLocationId;
      if (locationId == null || locationId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a location first')),
          );
        }
        return;
      }
      final sale = await ref
          .read(cartProvider.notifier)
          .checkout(
            method,
            locationId,
            isDraft: isDraft,
            transferDetails: transferDetails,
          );
      final business = ref.read(currentBusinessProvider);
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (final sheetContext) => SizedBox(
          height: MediaQuery.of(sheetContext).size.height,
          child: SaleSuccessPage(sale: sale, business: business),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Success page replaces this dialog
}

class _ProductPosCard extends ConsumerWidget {
  final ProductModel product;

  final String? locationId;
  const _ProductPosCard({required this.product, this.locationId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final palette = AppTheme.paletteOf(context);
    final cart = ref.watch(cartProvider);
    final available = availableBaseStock(product, locationId, cart.items);
    final isOut = available <= 0;
    final isLow = !isOut && available <= 5;
    final symbol = ref.watch(activeDisplayCurrencyProvider).symbol;

    final badgeColor = isOut
        ? palette.error.withValues(alpha: 0.12)
        : isLow
        ? palette.lowStock
        : palette.success.withValues(alpha: 0.12);
    final badgeTextColor = isOut
        ? palette.error
        : isLow
        ? palette.warning
        : palette.success;

    return Opacity(
      opacity: isOut ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: isOut
            ? () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} is out of stock')),
                );
              }
            : () => _showAddToCart(context, ref, available, palette),
        child: Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: palette.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.r),
                    ),
                  ),
                  child: Hero(
                    tag: 'product-${product.id}',
                    child: Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 48.sp,
                        color: palette.primary,
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
                        color: palette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$symbol${product.calculatePriceForUnit(product.unitChain?.baseUnit ?? 'Piece').toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isOut
                                  ? 'Out of stock'
                                  : '${formatPosQuantity(available)} left',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }

  void _showAddToCart(
    final BuildContext context,
    final WidgetRef ref,
    final double available,
    final AppPalette palette,
  ) {
    final baseUnit = product.unitChain?.baseUnit ?? 'Piece';
    final symbol = ref.read(activeDisplayCurrencyProvider).symbol;
    String selectedUnit = baseUnit;
    final controller = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final sheetContext) => StatefulBuilder(
        builder: (final sheetContext, final setState) {
          final qty = double.tryParse(controller.text) ?? 0.0;
          final factor =
              product.unitChain?.getFactor(selectedUnit, baseUnit) ?? 1.0;
          final maxQty = factor > 0 ? available / factor : available;
          final invalid = qty <= 0 || qty > maxQty;
          return Padding(
            padding: EdgeInsets.all(24.w).copyWith(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.w,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to Cart',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${available.toStringAsFixed(0)} $baseUnit available',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: palette.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                EnhancedUnitSelector(
                  product: product,
                  selectedUnit: selectedUnit,
                  onUnitSelected: (final val) =>
                      setState(() => selectedUnit = val),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                if (invalid)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Enter a quantity up to ${formatPosQuantity(maxQty)} $selectedUnit',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: palette.error,
                      ),
                    ),
                  )
                else
                  _buildConversionPreview(selectedUnit, qty, symbol, palette),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: invalid
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(cartProvider.notifier)
                                .addItem(product, selectedUnit, qty);
                            Navigator.pop(sheetContext);
                          },
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversionPreview(
    final String selectedUnit,
    final double quantity,
    final String symbol,
    final AppPalette palette,
  ) {
    final alternatives =
        product.unitChain?.units
            ?.where((final unit) => unit != selectedUnit)
            .take(3)
            .toList() ??
        const <String>[];
    if (alternatives.isEmpty || quantity <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 14.sp, color: palette.primary),
              SizedBox(width: 6.w),
              Text(
                'Also available as',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...alternatives.map((final unit) {
            final converted = convertPosQuantity(
              product,
              selectedUnit,
              unit,
              quantity,
            );
            final price = product.calculatePriceForUnit(unit);
            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatPosQuantity(converted)} $unit',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: palette.textSecondary,
                    ),
                  ),
                  Text(
                    '$symbol${(converted * price).toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
