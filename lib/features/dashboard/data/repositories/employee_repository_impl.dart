import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/firebase/firebase_config.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/invitation_model.dart';

part 'employee_repository_impl.g.dart';

@riverpod
EmployeeRepository employeeRepository(final EmployeeRepositoryRef ref) {
  return EmployeeRepositoryImpl(FirebaseConfig.firestore);
}

class EmployeeRepositoryImpl implements EmployeeRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  EmployeeRepositoryImpl(this._firestore);

  @override
  Future<List<UserModel>> getEmployees(final String businessId) async {
    final teamSnapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('team')
        .get();

    final List<UserModel> employees = [];
    for (final doc in teamSnapshot.docs) {
      final uid = doc.id;
      final role = doc.data()['role'] as String?;
      
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        employees.add(UserModel.fromJson(userData).copyWith(role: role));
      }
    }
    return employees;
  }

  @override
  Future<void> inviteEmployee({
    required final String businessId,
    required final String businessName,
    required final String adminId,
    required final String email,
    required final String role,
  }) async {
    final inviteId = _uuid.v4();
    final batch = _firestore.batch();

    // 1. Create Invitation Document (Top Level)
    final inviteRef = _firestore.collection('invitations').doc(inviteId);
    final invitation = InvitationModel(
      id: inviteId,
      from: adminId,
      to: email,
      role: role,
      businessId: businessId,
      businessName: businessName,
      createdAt: DateTime.now(),
    );
    batch.set(inviteRef, invitation.toJson());

    // 2. Trigger Email (via Firestore Email Extension collection)
    final mailRef = _firestore.collection('mail').doc();
    batch.set(mailRef, {
      'to': email,
      'message': {
        'subject': 'Invitation to join $businessName',
        'html': 'You have been invited to join $businessName as a $role. Click here to accept: https://bizmodule.web.app/accept-invite?inviteId=$inviteId',
      },
    });

    // 3. Create Placeholder in Team collection
    final teamMemberRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('team')
        .doc(email); // Use email as ID until user joins
    batch.set(teamMemberRef, {
      'email': email,
      'role': role,
      'status': 'pending',
      'inviteId': inviteId,
    });

    await batch.commit();
  }

  @override
  Future<InvitationModel?> getInvitation(final String inviteId) async {
    final doc = await _firestore.collection('invitations').doc(inviteId).get();
    if (!doc.exists) return null;
    return InvitationModel.fromJson(doc.data()!);
  }

  @override
  Future<void> acceptInvitation(final String inviteId, final String userId) async {
    final invitation = await getInvitation(inviteId);
    if (invitation == null) throw Exception('Invitation not found');

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final user = UserModel.fromJson(userDoc.data()!);

    if (user.email != invitation.to) {
      throw Exception('Email mismatch: This invite was sent to ${invitation.to}');
    }

    final batch = _firestore.batch();

    // 1. Update Team Member status
    final teamMemberRef = _firestore
        .collection('businesses')
        .doc(invitation.businessId)
        .collection('team')
        .doc(userId);
    batch.set(teamMemberRef, {
      'email': user.email,
      'role': invitation.role,
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // 2. Cleanup old placeholder if it exists (using email as ID)
    final oldPlaceholderRef = _firestore
        .collection('businesses')
        .doc(invitation.businessId)
        .collection('team')
        .doc(user.email);
    batch.delete(oldPlaceholderRef);

    // 3. Link Membership to User
    final membershipRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('memberships')
        .doc(invitation.businessId);
    batch.set(membershipRef, {
      'name': invitation.businessName,
      'role': invitation.role,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // 4. Delete the invitation source
    batch.delete(_firestore.collection('invitations').doc(inviteId));

    await batch.commit();
  }

  @override
  Future<void> updateEmployeeRole(final String businessId, final String uid, final String role) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid).collection('memberships').doc(businessId), {'role': role});
    batch.update(_firestore.collection('businesses').doc(businessId).collection('team').doc(uid), {'role': role});
    await batch.commit();
  }

  @override
  Future<void> removeEmployee(final String businessId, final String uid) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(uid).collection('memberships').doc(businessId));
    batch.delete(_firestore.collection('businesses').doc(businessId).collection('team').doc(uid));
    await batch.commit();
  }
}
