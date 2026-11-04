import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_providers.dart';

class CustomerSelector extends ConsumerWidget {
  final String? selectedCustomerId;
  final Function(CustomerModel?) onCustomerSelected;

  const CustomerSelector({
    super.key,
    this.selectedCustomerId,
    required this.onCustomerSelected,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer',
              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () => _showAddCustomerDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New'),
            ),
          ],
        ),
        customersAsync.when(
          data: (final customers) => DropdownButtonFormField<String>(
            initialValue: selectedCustomerId,
            isExpanded: true,
            hint: const Text('Walk-in Customer'),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Walk-in Customer'),
              ),
              ...customers.map((final c) => DropdownMenuItem(
                value: c.id,
                child: Text('${c.name} (${c.phone ?? "No Phone"})'),
              )),
            ],
            onChanged: (final val) {
              final customer = val == null ? null : customers.firstWhere((final c) => c.id == val);
              onCustomerSelected(customer);
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (final e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  void _showAddCustomerDialog(final BuildContext context, final WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final businessId = ref.read(currentBusinessProvider)?.id;
              if (businessId == null) return;

              final customer = CustomerModel(
                id: const Uuid().v4(),
                businessId: businessId,
                name: nameController.text,
                phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                createdAt: DateTime.now(),
              );

              await ref.read(customerActionsProvider.notifier).saveCustomer(customer);
              Navigator.pop(context);
              onCustomerSelected(customer);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
