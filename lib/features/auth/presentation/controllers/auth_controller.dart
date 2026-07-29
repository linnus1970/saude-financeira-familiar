import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository)
      : super(const AuthState());

  final AuthRepository _repository;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final user = await _repository.signIn(
        email: email,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _repository.signOut();

    state = const AuthState(
      status: AuthStatus.unauthenticated,
    );
  }
}
