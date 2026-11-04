import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/stock_in_model.dart';
import '../../data/repositories/stock_in_repository_impl.dart';
import '../providers/supplier_providers.dart';
import '../providers/inventory_providers.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../inventory/data/models/product_model.dart';

class RestockPage extends ConsumerStatefulWidget {
  const RestockPage({super.key});

  @override
  ConsumerState<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends ConsumerState<RestockPage> {
  String? _selectedSupplierId;
  String? _selectedLocationId;
  bool _isPaid = true;
  final List<StockInItem> _items = [];

  @override
  Widget build(final BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonAppBar(hasTitle: true, title: 'Stock Purchase'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionSection(suppliersAsync, locationsAsync),
            SizedBox(height: 24.h),
            _buildItemsSection(productsAsync),
            SizedBox(height: 24.h),
            _buildPaymentSection(),
            SizedBox(height: 32.h),
            _buildSubmitButton(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSection(final AsyncValue<List<dynamic>> suppliersAsync, final AsyncValue<List<dynamic>> locationsAsync) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Supplier',
            hint: 'Select Source Supplier',
            value: _selectedSupplierId,
            items: suppliersAsync.when(
              data: (final suppliers) => suppliers.map<DropdownMenuItem<String>>((final s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              loading: () => [],
              error: (_, final __) => [],
            ),
            onChanged: (final val) => setState(() => _selectedSupplierId = val),
            icon: Icons.business_outlined,
          ),
          SizedBox(height: 16.h),
          _buildDropdown(
            label: 'Destination Location',
            hint: 'Where to store items',
            value: _selectedLocationId,
            items: locationsAsync.when(
              data: (final locations) => locations.map<DropdownMenuItem<String>>((final l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              loading: () => [],
              error: (_, final __) => [],
            ),
            onChanged: (final val) => setState(() => _selectedLocationId = val),
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required final String label,
    required final String hint,
    required final dynamic value,
    required final List<DropdownMenuItem<String>> items,
    required final ValueChanged<String?> onChanged,
    required final IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(hint, style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[400])),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.sp, color: Colors.blue[700]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildItemsSection(final AsyncValue<List<ProductModel>> productsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Purchase Items', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(productsAsync.value ?? []),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  label: Text('Add Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ],
            ),
          ),
          if (_items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48.sp, color: Colors.grey[200]),
                    SizedBox(height: 12.h),
                    Text('No items added', style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, final __) => Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (final context, final index) {
                final item = _items[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  title: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                  subtitle: Text('${item.quantity.toStringAsFixed(0)} ${item.unit} @ \$${item.costPrice.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${(item.quantity * item.costPrice).toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _items.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (_items.isNotEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: Colors.blue[50]?.withOpacity(0.3), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.blue[900])),
                  Text('\$${_items.fold(0.0, (final sum, final i) => sum + (i.quantity * i.costPrice)).toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.blue[900])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _isPaid ? Colors.green[100]! : Colors.orange[100]!),
      ),
      child: SwitchListTile(
        title: Text('Mark as Paid', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp)),
        subtitle: Text(_isPaid ? 'Paid from Cash account' : 'Save as Supplier Credit', style: GoogleFonts.inter(fontSize: 12.sp)),
        value: _isPaid,
        activeThumbColor: Colors.green,
        onChanged: (final val) => setState(() => _isPaid = val),
        secondary: Icon(_isPaid ? Icons.check_circle_outline : Icons.account_balance_wallet_outlined, color: _isPaid ? Colors.green : Colors.orange),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final totalCost = _items.fold(0.0, (final sum, final i) => sum + (i.quantity * i.costPrice));
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: Text('Complete Purchase • \$${totalCost.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddItemDialog(final List<ProductModel> products) {
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Text('Add Purchase Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: productId,
                hint: const Text('Select Product'),
                isExpanded: true,
                items: products.map((final p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (final val) {
                  setDialogState(() {
                    productId = val;
                    if (val != null) {
                      final p = products.firstWhere((final prod) => prod.id == val);
                      costController.text = p.cost.toString();
                    }
                  });
                },
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: qtyController, 
                decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))), 
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: costController, 
                decoration: InputDecoration(labelText: 'Cost Price per Unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)), prefixText: r'$ '), 
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (productId == null) return;
                final product = products.firstWhere((final p) => p.id == productId);
                setState(() {
                  _items.add(StockInItem(
                    productId: product.id,
                    name: product.name,
                    quantity: double.tryParse(qtyController.text) ?? 0.0,
                    unit: product.unitChain?.baseUnit ?? 'Piece',
                    costPrice: double.tryParse(costController.text) ?? product.cost,
                  ));
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final business = ref.read(currentBusinessProvider);
    if (_selectedSupplierId == null || _selectedLocationId == null || _items.isEmpty || business == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and add items.')));
      return;
    }

    final totalCost = _items.fold(0.0, (final sum, final i) => sum + (i.quantity * i.costPrice));
    final supplier = (ref.read(supplierListProvider).value ?? []).firstWhere((final s) => s.id == _selectedSupplierId);

    final stockIn = StockInModel(
      id: const Uuid().v4(),
      businessId: business.id!,
      supplierId: _selectedSupplierId!,
      supplierName: supplier.name,
      locationId: _selectedLocationId!,
      items: _items,
      totalCost: totalCost,
      isPaid: _isPaid,
      timestamp: DateTime.now(),
    );

    await ref.read(stockInActionsProvider.notifier).performStockIn(stockIn);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restock completed successfully!')));
      Navigator.pop(context);
    }
  }
}
