// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(FirebaseAuthException error) onVerificationFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onCodeTimeout,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
