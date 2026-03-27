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
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Purchase (Restock)', style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 24.h),
            
            // Supplier & Location Pickers
            Row(
              children: [
                Expanded(
                  child: suppliersAsync.when(
                    data: (suppliers) => DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => _selectedSupplierId = val),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: locationsAsync.when(
                    data: (locations) => DropdownButtonFormField<String>(
                      value: _selectedLocationId,
                      decoration: const InputDecoration(labelText: 'Location'),
                      items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                      onChanged: (val) => setState(() => _selectedLocationId = val),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(productsAsync.value ?? []),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            
            _buildItemsList(),
            
            const Divider(height: 48),
            SwitchListTile(
              title: const Text('Mark as Paid (Cash Purchase)'),
              subtitle: const Text('Disable to add this to Supplier Balance (Credit)'),
              value: _isPaid,
              onChanged: (val) => setState(() => _isPaid = val),
            ),
            
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Complete Purchase & Update Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No items added yet.')));
    
    return Column(
      children: _items.map((item) => ListTile(
        title: Text(item.name),
        subtitle: Text('${item.quantity} ${item.unit} @ \$${item.costPrice}'),
        trailing: Text('\$${(item.quantity * item.costPrice).toStringAsFixed(2)}'),
        onLongPress: () => setState(() => _items.remove(item)),
      )).toList(),
    );
  }

  void _showAddItemDialog(List<ProductModel> products) {
    String? productId;
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Purchase Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: productId,
                hint: const Text('Select Product'),
                items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (val) => setDialogState(() => productId = val),
              ),
              SizedBox(height: 16.h),
              TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              SizedBox(height: 16.h),
              TextField(controller: costController, decoration: const InputDecoration(labelText: 'Cost Price per Unit'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (productId == null) return;
                final product = products.firstWhere((p) => p.id == productId);
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

    final totalCost = _items.fold(0.0, (sum, i) => sum + (i.quantity * i.costPrice));
    final supplier = (ref.read(supplierListProvider).value ?? []).firstWhere((s) => s.id == _selectedSupplierId);

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
