import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  });

  Future<AppUserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> resetPassword(String email);

  Future<void> signOut();

  Stream<User?> authStateChanges();

  User? currentUser();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final doc = await _firestore.collection('users').doc(uid).get();

    return AppUserModel.fromMap(doc.data()!, uid);
  }

  @override
  Future<AppUserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    await user.updateDisplayName(name);

    final model = AppUserModel(
      id: user.uid,
      name: name,
      email: email,
      familyId: null,
      createdAt: DateTime.now(),
      emailVerified: user.emailVerified,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(model.toMap());

    return model;
  }

  @override
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  @override
  User? currentUser() {
    return _auth.currentUser;
  }
}
