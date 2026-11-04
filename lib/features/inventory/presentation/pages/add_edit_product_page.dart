import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late TextEditingController _categoryController;
  late TextEditingController _costController;
  late TextEditingController _priceController;
  final Map<String, TextEditingController> _stockControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _skuController = TextEditingController(text: widget.product?.sku);
    _descriptionController = TextEditingController(text: widget.product?.description);
    _categoryController = TextEditingController(text: widget.product?.category);
    _costController = TextEditingController(text: widget.product?.cost.toString() ?? '0.0');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '0.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    _priceController.dispose();
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
      category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
      cost: double.tryParse(_costController.text) ?? 0.0,
      price: double.tryParse(_priceController.text) ?? 0.0,
      stockByLocation: stockByLocation.isNotEmpty 
          ? stockByLocation 
          : widget.product?.stockByLocation ?? {'main': 0.0},
      unitSystemVersion: widget.product?.unitSystemVersion ?? 'enhanced',
      unitChain: widget.product?.unitChain,
      priceConfigs: widget.product?.priceConfigs,
      isArchived: widget.product?.isArchived ?? false,
      updatedAt: DateTime.now(),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'General Information',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Product Name',
                    hint: 'e.g. Wireless Mouse',
                    validator: (final val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _skuController,
                          label: 'SKU / Barcode',
                          hint: 'Optional',
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _categoryController,
                          label: 'Category',
                          hint: 'e.g. Electronics',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Product details...',
                    maxLines: 3,
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildSection(
                title: 'Pricing',
                icon: Icons.payments_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _costController,
                          label: 'Cost Price',
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          prefixText: r'$ ',
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Selling Price',
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          prefixText: r'$ ',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildSection(
                title: 'Inventory & Locations',
                icon: Icons.location_on_outlined,
                children: [
                  locationsAsync.when(
                    data: (final locations) => Column(
                      children: locations.map((final l) {
                        final controller = _stockControllers.putIfAbsent(
                          l.id, 
                          () => TextEditingController(
                            text: widget.product?.stockByLocation[l.id]?.toString() ?? '0'
                          ),
                        );
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildTextField(
                            controller: controller,
                            label: l.name,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            suffixText: 'units',
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (final err, _) => const Text('Error loading locations'),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Update Product' : 'Save Product',
                    style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required final String title, required final IconData icon, required final List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: Colors.blue[700]),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required final TextEditingController controller,
    required final String label,
    final String? hint,
    final int maxLines = 1,
    final TextInputType keyboardType = TextInputType.text,
    final String? prefixText,
    final String? suffixText,
    final String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14.sp),
            prefixText: prefixText,
            suffixText: suffixText,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.blue[400]!, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
