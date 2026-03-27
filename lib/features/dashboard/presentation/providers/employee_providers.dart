import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/repositories/employee_repository_impl.dart';

part 'employee_providers.g.dart';

@riverpod
Future<List<UserModel>> employeeList(final EmployeeListRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Future.value([]);
  return ref.watch(employeeRepositoryProvider).getEmployees(businessId);
}

@riverpod
class EmployeeActions extends _$EmployeeActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> inviteEmployee(final String email, final String role) async {
    final auth = ref.read(authProvider);
    final business = auth.activeBusiness;
    if (business == null || auth.user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(employeeRepositoryProvider).inviteEmployee(
        businessId: business.id!,
        businessName: business.name ?? 'Your Business',
        adminId: auth.user!.uid,
        email: email,
        role: role,
      );
      ref.invalidate(employeeListProvider);
    });
  }

  Future<void> updateRole(final String uid, final String role) async {
    final businessId = ref.read(currentBusinessProvider)?.id;
    if (businessId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(employeeRepositoryProvider).updateEmployeeRole(businessId, uid, role);
      ref.invalidate(employeeListProvider);
    });
  }

  Future<void> removeEmployee(final String uid) async {
    final businessId = ref.read(currentBusinessProvider)?.id;
    if (businessId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(employeeRepositoryProvider).removeEmployee(businessId, uid);
      ref.invalidate(employeeListProvider);
    });
  }
}
