import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/business_model.dart';
import '../../shared/models/membership_model.dart';
import '../../shared/models/user_model.dart';
import '../constants/role_configs.dart';
import 'role_service.dart';
import 'auth_service.dart';

class OnboardingData {
  final String businessName;
  final String industry;
  final String businessSize;
  final List<String> locations;
  final List<String> goals;
  final List<String> selectedModules;
  final String currency;
  final String language;

  OnboardingData({
    required this.businessName,
    required this.industry,
    required this.businessSize,
    required this.locations,
    required this.goals,
    required this.selectedModules,
    required this.currency,
    required this.language,
  });
}

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();

  Future<String> createBusinessWithOnboarding({
    required final OnboardingData data,
    required final String ownerId,
  }) async {
    final businessId = _firestore.collection('businesses').doc().id;
    final now = DateTime.now();

    // 1. Create Business Document
    final business = BusinessModel(
      id: businessId,
      name: data.businessName,
      industry: data.industry,
      size: data.businessSize,
      goals: data.goals,
      language: data.language,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
      settings: {
        'currency': data.currency,
      },
    );

    await _firestore.collection('businesses').doc(businessId).set(business.toJson());

    // 2. Initialize Info sub-collection (to stay compatible with current AuthService logic)
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('info')
        .set({
      'name': data.businessName,
      'industry': data.industry,
      'category': data.industry,
      'createdAt': now.toIso8601String(),
    });

    // 3. Initialize Modules
    final Map<String, bool> moduleStates = {};
    for (final moduleId in data.selectedModules) {
      moduleStates[moduleId] = true;
    }
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('modules')
        .set(moduleStates);

    // 4. Seed Default Roles
    await _roleService.seedDefaultRoles(businessId);

    // 5. Atomic setup for Membership and User link
    final batch = _firestore.batch();

    // Add to business team
    final membership = MembershipModel(
      businessId: businessId,
      userId: ownerId,
      roleId: RoleConfigs.ownerId,
      status: 'active',
      joinedAt: now,
    );
    final teamRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('team')
        .doc(ownerId);
    batch.set(teamRef, membership.toJson());

    // Add to user memberships
    final userMembershipRef = _firestore
        .collection('users')
        .doc(ownerId)
        .collection('memberships')
        .doc(businessId);
    batch.set(userMembershipRef, membership.toJson());

    // Update user root document
    final userRef = _firestore.collection('users').doc(ownerId);
    batch.update(userRef, {
      'businessIds': FieldValue.arrayUnion([businessId]),
      'onboardingCompleted': true,
      'updatedAt': now.toIso8601String(),
    });

    await batch.commit();

    // 6. Refresh Local Storage (Triggering a refresh in AuthProvider)
    final userDoc = await _firestore.collection('users').doc(ownerId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      userData['id'] = ownerId;
      if (userData['displayName'] != null) userData['name'] = userData['displayName'];
      if (userData['photoURL'] != null) userData['photoUrl'] = userData['photoURL'];

      final updatedUser = UserModel.fromJson(userData);
      await AuthService.saveUserToLocalStorage(updatedUser);
      await AuthService.saveBusinessToLocalStorage(business);
    }

    return businessId;
  }

  Future<Map<String, bool>> getBusinessModules(final String businessId) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('modules')
        .get();
    
    if (doc.exists) {
      return Map<String, bool>.from(doc.data()!);
    }
    return {};
  }

  Future<void> updateBusinessOnboarding({
    required final String businessId,
    required final OnboardingData data,
    required final String ownerId,
  }) async {
    final now = DateTime.now();

    // 1. Update Business Document
    await _firestore.collection('businesses').doc(businessId).update({
      'name': data.businessName,
      'industry': data.industry,
      'size': data.businessSize,
      'goals': data.goals,
      'language': data.language,
      'updatedAt': now,
      'settings.currency': data.currency,
    });

    // 2. Update Info sub-collection
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('info')
        .update({
          'name': data.businessName,
          'industry': data.industry,
          'category': data.industry,
          'updatedAt': now.toIso8601String(),
        });

    // 3. Update Modules
    final Map<String, bool> moduleStates = {};
    for (final moduleId in data.selectedModules) {
      moduleStates[moduleId] = true;
    }
    // Note: This replaces existing module settings. If we want to merge, we should fetch first.
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('modules')
        .set(moduleStates);

    // 4. Update user status if needed
    await _firestore.collection('users').doc(ownerId).update({
      'onboardingCompleted': true,
      'updatedAt': now.toIso8601String(),
    });

    // 5. Refresh Local Storage
    final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
    final userDoc = await _firestore.collection('users').doc(ownerId).get();
    
    if (businessDoc.exists && userDoc.exists) {
      final userData = userDoc.data()!;
      userData['id'] = ownerId;
      // Handle displayName mapping if necessary, although name is nullable
      if (userData['displayName'] != null) userData['name'] = userData['displayName'];
      if (userData['photoURL'] != null) userData['photoUrl'] = userData['photoURL'];

      final updatedBusiness = await AuthService.getBusinessFromFirestore(businessId);
      final updatedUser = UserModel.fromJson(userData);
      
      if (updatedBusiness != null) {
        await AuthService.saveBusinessToLocalStorage(updatedBusiness);
      }
      await AuthService.saveUserToLocalStorage(updatedUser);
    }
  }
}
