import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return _remote.signIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _remote.register(
      name: name,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> resetPassword(String email) {
    return _remote.resetPassword(email);
  }

  @override
  Future<void> signOut() {
    return _remote.signOut();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remote.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      return _remote.signIn(
        email: firebaseUser.email!,
        password: '',
      );
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    final firebaseUser = _remote.currentUser();

    if (firebaseUser == null) {
      return null;
    }

    // Será substituído por leitura direta do Firestore
    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      familyId: null,
      createdAt: DateTime.now(),
      emailVerified: firebaseUser.emailVerified,
    );
  }
}
