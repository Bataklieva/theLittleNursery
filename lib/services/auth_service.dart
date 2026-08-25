import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/child.dart';
import '../models/parent_profile.dart';

/// Owns the signed-in parent's auth state and Firestore profile, and
/// exposes their children as a live list.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? _user;
  ParentProfile? _profile;
  List<Child> _children = const [];

  User? get user => _user;
  ParentProfile? get profile => _profile;
  List<Child> get children => _children;
  bool get isSignedIn => _user != null;

  CollectionReference<Map<String, dynamic>> get _parents =>
      _firestore.collection('parents');

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user == null) {
      _profile = null;
      _children = const [];
      notifyListeners();
      return;
    }
    await _loadProfile(user.uid);
  }

  Future<void> _loadProfile(String uid) async {
    final doc = await _parents.doc(uid).get();
    if (doc.exists) {
      _profile = ParentProfile.fromMap(uid, doc.data()!);
    }
    final childrenSnap = await _parents.doc(uid).collection('children').get();
    _children = childrenSnap.docs
        .map((d) => Child.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.birthDate.compareTo(b.birthDate));
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final profile = ParentProfile(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
    );
    await _parents.doc(uid).set(profile.toMap());
    _profile = profile;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> addChild(Child child) async {
    final uid = _requireUid();
    final ref = await _parents.doc(uid).collection('children').add(
          child.toMap(),
        );
    _children = [..._children, Child.fromMap(ref.id, child.toMap())]
      ..sort((a, b) => a.birthDate.compareTo(b.birthDate));
    notifyListeners();
  }

  Future<void> updateChild(Child child) async {
    final uid = _requireUid();
    await _parents
        .doc(uid)
        .collection('children')
        .doc(child.id)
        .update(child.toMap());
    _children = [
      for (final c in _children) c.id == child.id ? child : c,
    ];
    notifyListeners();
  }

  Future<void> removeChild(String childId) async {
    final uid = _requireUid();
    await _parents.doc(uid).collection('children').doc(childId).delete();
    _children = _children.where((c) => c.id != childId).toList();
    notifyListeners();
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _parents.doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }

  String _requireUid() {
    final uid = _user?.uid;
    if (uid == null) {
      throw StateError('No signed-in parent.');
    }
    return uid;
  }
}
