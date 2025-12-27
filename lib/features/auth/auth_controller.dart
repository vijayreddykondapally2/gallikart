// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/auth_service.dart';

class AuthState {
  const AuthState({this.loading = false, this.error});

  final bool loading;
  final String? error;

  AuthState copyWith({bool? loading, String? error}) {
    return AuthState(
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState());

  final AuthService _service;

  Future<void> loginAnonymously() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.signInAnonymously();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authServiceProvider)),
);
