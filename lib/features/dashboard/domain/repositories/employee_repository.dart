import '../../../../shared/models/user_model.dart';
import '../../data/models/invitation_model.dart';

abstract class EmployeeRepository {
  Future<List<UserModel>> getEmployees(final String businessId);
  
  /// Sends an invitation to an email.
  Future<void> inviteEmployee({
    required final String businessId,
    required final String businessName,
    required final String adminId,
    required final String email,
    required final String role,
  });

  /// Accepts a pending invitation.
  Future<void> acceptInvitation(final String inviteId, final String userId);

  /// Helper to get invitation details for verification.
  Future<InvitationModel?> getInvitation(final String inviteId);

  Future<void> updateEmployeeRole(final String businessId, final String uid, final String role);
  Future<void> removeEmployee(final String businessId, final String uid);
}
