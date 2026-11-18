import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../providers/supplier_providers.dart';
import '../../data/models/supplier_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../core/config/router/app_router.dart';

class SuppliersPage extends ConsumerWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonAppBar(hasTitle: true, title: 'Suppliers'),
      body: suppliersAsync.when(
        data: (final suppliers) => _buildSupplierList(context, ref, suppliers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierSheet(context, ref),
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add_business_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildSupplierList(final BuildContext context, final WidgetRef ref, final List<SupplierModel> suppliers) {
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64.sp, color: Colors.grey[200]),
            SizedBox(height: 16.h),
            Text('No suppliers found', style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: suppliers.length,
      itemBuilder: (final context, final index) {
        final supplier = suppliers[index];
        final hasBalance = supplier.balance > 0;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  supplier.name[0].toUpperCase(),
                  style: GoogleFonts.inter(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 18.sp),
                ),
              ),
            ),
            title: Text(supplier.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            subtitle: Text(supplier.phone ?? 'No contact info', style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₦${supplier.balance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: hasBalance ? Colors.redAccent : Colors.green[700],
                      ),
                    ),
                    Text('Balance', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey)),
                  ],
                ),
                SizedBox(width: 12.w),
                Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8.r)),
                  child: IconButton(
                    icon: Icon(Icons.add_shopping_cart, color: Colors.blue[700], size: 20.sp),
                    onPressed: () => context.push(AppRouter.restock),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSupplierSheet(final BuildContext context, final WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final context) => _AddSupplierForm(),
    );
  }
}

class _AddSupplierForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddSupplierForm> createState() => _AddSupplierFormState();
}

class _AddSupplierFormState extends ConsumerState<_AddSupplierForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.all(24.w).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add New Supplier', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          SizedBox(height: 24.h),
          _buildField(controller: _nameController, label: 'Business Name', icon: Icons.business),
          SizedBox(height: 16.h),
          _buildField(controller: _contactController, label: 'Contact Person (Optional)', icon: Icons.person_outline),
          SizedBox(height: 16.h),
          _buildField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: () async {
                final businessId = ref.read(currentBusinessProvider)?.id;
                if (_nameController.text.isNotEmpty && businessId != null) {
                  final supplier = SupplierModel(
                    id: const Uuid().v4(),
                    businessId: businessId,
                    name: _nameController.text,
                    contactName: _contactController.text,
                    phone: _phoneController.text,
                    createdAt: DateTime.now(),
                  );
                  await ref.read(supplierActionsProvider.notifier).saveSupplier(supplier);
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              child: Text('Save Supplier', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required final TextEditingController controller,
    required final String label,
    required final IconData icon,
    final TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.sp, color: Colors.blue[700]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
