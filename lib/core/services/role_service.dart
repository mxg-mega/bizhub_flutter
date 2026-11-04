import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/permission_model.dart';
import '../../shared/models/membership_model.dart';
import '../constants/role_configs.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Populate a business with default roles
  Future<void> seedDefaultRoles(final String businessId) async {
    final batch = _firestore.batch();
    for (final role in RoleConfigs.defaultRoles) {
      final ref = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('roles')
          .doc(role.id);
      batch.set(ref, role.toJson());
    }
    await batch.commit();
  }

  // Fetch all custom roles for a business
  Future<List<RoleModel>> getRoles(final String businessId) async {
    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('roles')
        .get();

    return snapshot.docs.map((final doc) => RoleModel.fromJson(doc.data())).toList();
  }

  // Create or update a role
  Future<void> saveRole(final String businessId, final RoleModel role) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('roles')
        .doc(role.id)
        .set(role.toJson());
  }

  // Fetch a user's membership in a business
  Future<MembershipModel?> getMembership({
    required final String businessId,
    required final String userId,
  }) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('team')
        .doc(userId)
        .get();

    if (doc.exists) {
      return MembershipModel.fromJson(doc.data()!);
    }
    return null;
  }

  // Fetch a specific role by ID
  Future<RoleModel?> getRole({
    required final String businessId,
    required final String roleId,
  }) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('roles')
        .doc(roleId)
        .get();

    if (doc.exists) {
      return RoleModel.fromJson(doc.data()!);
    }
    return null;
  }

  // Atomic operation to update member role
  Future<void> updateMemberRole({
    required final String businessId,
    required final String userId,
    required final String newRoleId,
  }) async {
    final batch = _firestore.batch();

    // 1. Update business team sub-collection
    final teamRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('team')
        .doc(userId);
    batch.update(teamRef, {'roleId': newRoleId});

    // 2. Update user memberships sub-collection
    final membershipRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('memberships')
        .doc(businessId);
    batch.update(membershipRef, {'roleId': newRoleId});

    await batch.commit();
  }
}
