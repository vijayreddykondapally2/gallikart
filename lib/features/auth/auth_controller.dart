// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/auth_service.dart';

class AuthState {
  const AuthState({
    this.sendingCode = false,
    this.verifying = false,
    this.codeSent = false,
    this.verificationId,
    this.resendToken,
    this.error,
    this.phone,
  });

  final bool sendingCode;
  final bool verifying;
  final bool codeSent;
  final String? verificationId;
  final int? resendToken;
  final String? error;
  final String? phone;

  AuthState copyWith({
    bool? sendingCode,
    bool? verifying,
    bool? codeSent,
    String? verificationId,
    int? resendToken,
    String? error,
    String? phone,
  }) {
    return AuthState(
      sendingCode: sendingCode ?? this.sendingCode,
      verifying: verifying ?? this.verifying,
      codeSent: codeSent ?? this.codeSent,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      error: error,
      phone: phone ?? this.phone,
    );
  }
}

class AuthResult {
  const AuthResult({
    required this.uid,
    required this.phone,
    required this.needsRoleSelection,
    this.role,
  });

  final String uid;
  final String phone;
  final bool needsRoleSelection;
  final String? role;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service, this._firestore) : super(const AuthState());

  final AuthService _service;
  final FirebaseFirestore _firestore;

  Future<void> sendOtp({
    required String mobile,
    required void Function() onCodeSent,
    required void Function(AuthResult result) onAutoVerified,
    int? forceResendToken,
  }) async {
    final phone = _formatPhone(mobile);
    state = state.copyWith(sendingCode: true, error: null, phone: phone);
    try {
      await _service.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: forceResendToken,
        onVerificationCompleted: (credential) async {
          final result = await _handleCredential(credential);
          if (result != null) onAutoVerified(result);
        },
        onVerificationFailed: (error) {
          state = state.copyWith(
            sendingCode: false,
            error: error.message ?? error.code,
          );
        },
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            sendingCode: false,
            codeSent: true,
            verificationId: verificationId,
            resendToken: resendToken,
          );
          onCodeSent();
        },
        onCodeTimeout: (verificationId) {
          state = state.copyWith(
            sendingCode: false,
            verificationId: verificationId,
          );
        },
      );
    } catch (error) {
      state = state.copyWith(sendingCode: false, error: error.toString());
    }
  }

  Future<AuthResult?> verifyOtp({required String smsCode}) async {
    if (state.verificationId == null) {
      state = state.copyWith(error: 'No verification id. Please request OTP again.');
      return null;
    }
    state = state.copyWith(verifying: true, error: null);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );
      return await _handleCredential(credential);
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    } finally {
      state = state.copyWith(verifying: false);
    }
  }

  Future<void> saveUserRole({required String role, required String phone}) async {
    final user = _service.currentUser;
    if (user == null) {
      throw StateError('Cannot save role without signed in user');
    }
    await _firestore.collection('users').doc(user.uid).set(
      {
        'mobile': _formatPhone(phone),
        'role': role.toLowerCase().trim(),
        'name': '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _formatPhone(String mobile) {
    final digitsOnly = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('91') && digitsOnly.length == 12) {
      return '+$digitsOnly';
    }
    if (digitsOnly.length == 10) {
      return '+91$digitsOnly';
    }
    if (mobile.startsWith('+')) return mobile;
    return '+91$digitsOnly';
  }

  Future<AuthResult?> _handleCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _service.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        state = state.copyWith(error: 'Unable to sign in');
        return null;
      }
      final phone = user.phoneNumber ?? state.phone ?? '';
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data();
        final roleRaw = (data?['role'] as String?)?.toLowerCase();
        await docRef.set(
          {
            'mobile': phone,
            'lastLogin': FieldValue.serverTimestamp(),
            'isActive': data?['isActive'] ?? true,
          },
          SetOptions(merge: true),
        );
        return AuthResult(
          uid: user.uid,
          phone: phone,
          needsRoleSelection: roleRaw == null || roleRaw.isEmpty,
          role: roleRaw,
        );
      }
      // Create user document on first login
      await docRef.set({
        'name': '',
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      return AuthResult(
        uid: user.uid,
        phone: phone,
        needsRoleSelection: true,
        role: null,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    ref.read(authServiceProvider),
    ref.read(firebaseFirestoreProvider),
  ),
);
