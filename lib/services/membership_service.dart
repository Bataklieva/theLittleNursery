import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership_plan.dart';

class MembershipService {
  MembershipService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('membershipPlans');

  Stream<List<MembershipPlan>> watchActive() {
    return _plans.where('active', isEqualTo: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => MembershipPlan.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<MembershipPlan>> watchAllForAdmin() {
    return _plans.snapshots().map(
          (snap) => snap.docs
              .map((d) => MembershipPlan.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> createPlan(MembershipPlan plan) {
    return _plans.add(plan.toMap());
  }

  Future<void> updatePlan(MembershipPlan plan) {
    return _plans.doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String planId) {
    return _plans.doc(planId).delete();
  }
}
