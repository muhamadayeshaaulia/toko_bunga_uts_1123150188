import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

 enum AuthStatus{
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNoVerified,
  error,
 }
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus _status = AuthStatus.initial;
  User?     _firebaseUser;
  String?   _backendToken; 
  String?   _errorMessage;

  AuthStatus get status       => _status;
  User?      get firebaseUser  => _firebaseUser;
  String?    get backendToken  => _backendToken;
  String?    get errorMessage  => _errorMessage;
  bool       get isLoading     => _status == AuthStatus.loading; 



 Future<bool> _verifyTokenToBackend() async {
  // Ambil Firebase ID Token (expired tiap 1 jam)
  final firebaseToken = await _firebaseUser?.getIdToken();
 
  // POST ke backend — DioClient interceptor sudah handle logging
  final response = await DioClient.instance.post(
    ApiConstants.verifyToken,
    data: {'firebase_token': firebaseToken},
  );
 
  // Backend return JWT milik sistem kita
  final data = response.data['data'] as Map<String, dynamic>;
  final backendToken = data['access_token'] as String;
 
  // Simpan aman di device (encrypted)
  await SecureStorageService.saveToken(backendToken);
 
  _status = AuthStatus.authenticated;
  notifyListeners();
  return true;
}

Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser = credential.user;


      // Cek apakah email sudah diverifikasi
      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }


      // Email terverifikasi → dapatkan token Firebase → kirim ke backend
      return await _verifyTokenToBackend();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

Future<bool> loginWithGoogle() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setError('Login Google dibatalkan');
        return false;
      }


      final googleAuth  = await googleUser.authentication;
      final credential  = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      _firebaseUser  = userCred.user;


      // Google login → email otomatis terverifikasi
      return await _verifyTokenToBackend();
    } catch (e) {
      _setError('Gagal login dengan Google: $e');
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    await _firebaseUser?.sendEmailVerification();
  }


  Future<bool> checkEmailVerified() async {
    await _firebaseUser?.reload();
    _firebaseUser = _auth.currentUser;


    if (_firebaseUser?.emailVerified ?? false) {
      return await _verifyTokenToBackend();
    }
    return false;
  }

Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await SecureStorageService.clearAll();
    _firebaseUser = null;
    _backendToken = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }


  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }


  String _mapFirebaseError(String code) => switch (code) {
    'email-already-in-use'  => 'Email sudah terdaftar. Gunakan email lain.',
    'user-not-found'        => 'Akun tidak ditemukan. Silakan daftar.',
    'wrong-password'        => 'Password salah. Coba lagi.',
    'invalid-email'        => 'Format email tidak valid.',
    'weak-password'        => 'Password terlalu lemah. Minimal 6 karakter.',
    'network-request-failed'=> 'Tidak ada koneksi internet.',
    _                      => 'Terjadi kesalahan. Coba lagi.',
  };
}

