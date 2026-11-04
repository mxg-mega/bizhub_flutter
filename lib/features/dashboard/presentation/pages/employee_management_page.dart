import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/employee_providers.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';

class EmployeeManagementPage extends ConsumerWidget {
  const EmployeeManagementPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: const CommonAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(employeeListProvider),
        child: employeesAsync.when(
          data: (final employees) => _buildEmployeeList(context, ref, employees),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmployeeDialog(context, ref),
        label: const Text('Add Employee'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmployeeList(final BuildContext context, final WidgetRef ref, final List<UserModel> employees) {
    if (employees.isEmpty) {
      return const Center(child: Text('No employees found.'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: employees.length,
      itemBuilder: (final context, final index) {
        final employee = employees[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: employee.photoUrl != null ? NetworkImage(employee.photoUrl!) : null,
              child: employee.photoUrl == null ? Text(employee.name?[0].toUpperCase() ?? 'U') : null,
            ),
            title: Text(employee.name ?? 'Unnamed User', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${employee.email}\nRole: ${employee.role?.toUpperCase()}'),
            trailing: PopupMenuButton<String>(
              onSelected: (final val) => _handleAction(context, ref, val, employee),
              itemBuilder: (final context) => [
                const PopupMenuItem(value: 'change_role', child: Text('Change Role')),
                const PopupMenuItem(value: 'remove', child: Text('Remove from Business', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAction(final BuildContext context, final WidgetRef ref, final String action, final UserModel employee) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context, ref, employee);
        break;
      case 'remove':
        _showRemoveConfirmDialog(context, ref, employee);
        break;
    }
  }

  void _showAddEmployeeDialog(final BuildContext context, final WidgetRef ref) {
    final emailController = TextEditingController();
    String selectedRole = 'sales_rep';

    showDialog(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: const Text('Add New Employee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'User Email', hintText: 'Must be an existing user'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Assign Role'),
                items: const [
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  DropdownMenuItem(value: 'sales_rep', child: Text('Sales Rep')),
                ],
                onChanged: (final val) => setState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty) return;
                await ref.read(employeeActionsProvider.notifier).inviteEmployee(emailController.text, selectedRole);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(final BuildContext context, final WidgetRef ref, final UserModel employee) {
    String selectedRole = employee.role ?? 'sales_rep';

    showDialog(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: Text('Change Role: ${employee.name}'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRole,
            decoration: const InputDecoration(labelText: 'New Role'),
            items: const [
              DropdownMenuItem(value: 'manager', child: Text('Manager')),
              DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
              DropdownMenuItem(value: 'sales_rep', child: Text('Sales Rep')),
            ],
            onChanged: (final val) => setState(() => selectedRole = val!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(employeeActionsProvider.notifier).updateRole(employee.id, selectedRole);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmDialog(final BuildContext context, final WidgetRef ref, final UserModel employee) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Remove Employee?'),
        content: Text('Are you sure you want to remove ${employee.name} from this business?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(employeeActionsProvider.notifier).removeEmployee(employee.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
