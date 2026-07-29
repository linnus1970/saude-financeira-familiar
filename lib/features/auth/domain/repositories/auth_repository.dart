import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> resetPassword(String email);

  Future<void> signOut();

  Stream<AppUser?> authStateChanges();

  Future<AppUser?> currentUser();
}
