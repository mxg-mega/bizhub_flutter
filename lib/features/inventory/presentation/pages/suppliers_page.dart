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

class SuppliersPage extends ConsumerWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: suppliersAsync.when(
        data: (suppliers) => _buildSupplierList(context, ref, suppliers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierSheet(context, ref),
        label: const Text('Add Supplier'),
        icon: const Icon(Icons.add_business),
      ),
    );
  }

  Widget _buildSupplierList(BuildContext context, WidgetRef ref, List<SupplierModel> suppliers) {
    if (suppliers.isEmpty) return const Center(child: Text('No suppliers found.'));

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: Colors.grey[200]!)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Text(supplier.name[0].toUpperCase(), style: TextStyle(color: Colors.blue[700]))),
            title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(supplier.phone ?? 'No contact info'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${supplier.balance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: supplier.balance > 0 ? Colors.red : Colors.green)),
                    Text('Balance', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                  ],
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                  onPressed: () => context.go('/restock'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSupplierSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddSupplierForm(),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add New Supplier', style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 24.h),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Business Name')),
          SizedBox(height: 16.h),
          TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact Person (Optional)')),
          SizedBox(height: 16.h),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
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
              child: const Text('Save Supplier'),
            ),
          ),
        ],
      ),
    );
  }
}
