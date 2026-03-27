import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product_model.dart';
import '../providers/inventory_providers.dart';

class AddEditProductPage extends ConsumerStatefulWidget {
  final ProductModel? product;
  const AddEditProductPage({super.key, this.product});

  @override
  ConsumerState<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends ConsumerState<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  final Map<String, TextEditingController> _stockControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _skuController = TextEditingController(text: widget.product?.sku);
    _descriptionController = TextEditingController(text: widget.product?.description);
    _costController = TextEditingController(text: widget.product?.cost.toString() ?? '0.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, double> stockByLocation = {};
    for (final entry in _stockControllers.entries) {
      stockByLocation[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }

    final product = ProductModel(
      id: widget.product?.id ?? const Uuid().v4(),
      name: _nameController.text,
      sku: _skuController.text.isNotEmpty ? _skuController.text : null,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      cost: double.tryParse(_costController.text) ?? 0.0,
      stockByLocation: stockByLocation.isNotEmpty 
          ? stockByLocation 
          : widget.product?.stockByLocation ?? {'main': 0.0},
      unitSystemVersion: widget.product?.unitSystemVersion ?? 'enhanced',
      unitChain: widget.product?.unitChain,
      priceConfigs: widget.product?.priceConfigs,
      isArchived: widget.product?.isArchived ?? false,
    );

    await ref.read(inventoryActionsProvider.notifier).saveProduct(product);

    if (mounted && !ref.read(inventoryActionsProvider).hasError) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost Price'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 24.h),
              const Divider(),
              Text('Initial Stock by Location', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16.h),
              locationsAsync.when(
                data: (locations) => Column(
                  children: locations.map((l) {
                    final controller = _stockControllers.putIfAbsent(
                      l.id, 
                      () => TextEditingController(
                        text: widget.product?.stockByLocation[l.id]?.toString() ?? '0'
                      ),
                    );
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(labelText: l.name),
                        keyboardType: TextInputType.number,
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error loading locations'),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
