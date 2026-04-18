import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/secure_storage.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  String? _backendToken;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  String? get backendToken => _backendToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  /// Inisialisasi Auth saat aplikasi pertama kali dibuka (Auto Login)
  Future<void> initializeAuth() async {
    _status = AuthStatus.loading;
    
    _firebaseUser = _auth.currentUser;
    final savedToken = await SecureStorageService.getToken();

    if (_firebaseUser != null && savedToken != null) {
      // Wajib reload untuk memastikan status verifikasi email terbaru
      await _firebaseUser?.reload();
      _firebaseUser = _auth.currentUser;

      if (_firebaseUser!.emailVerified) {
        _backendToken = savedToken;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.emailNotVerified;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser = credential.user;

      if (_firebaseUser != null) {
        await _firebaseUser?.updateDisplayName(name);
        await DioClient.instance.post(
          '/auth/register', 
          data: {
            'uid': _firebaseUser!.uid,
            'name': name,
            'email': email,
          },
        );

        await _firebaseUser?.sendEmailVerification();
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    } catch (e) {
      _setError('Gagal mendaftar ke server: $e');
      return false;
    }
  }

  /// Login Email & Password
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

      // PENTING: Reload user untuk sinkronisasi status emailVerified
      await _firebaseUser?.reload();
      _firebaseUser = _auth.currentUser;

      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      return await _verifyTokenToBackend();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  /// Login Menggunakan Google
  Future<bool> loginWithGoogle() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      _firebaseUser = userCred.user;

      return await _verifyTokenToBackend();
    } catch (e) {
      _setError('Gagal login dengan Google: $e');
      return false;
    }
  }

  /// Verifikasi Token ke Backend (Laravel/Golang)
  Future<bool> _verifyTokenToBackend() async {
    try {
      final firebaseToken = await _firebaseUser?.getIdToken();

      final response = await DioClient.instance.post(
        ApiConstants.verifyToken,
        data: {'firebase_token': firebaseToken},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      _backendToken = data['access_token'] as String;

      await SecureStorageService.saveToken(_backendToken!);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal verifikasi ke server.');
      return false;
    }
  }
Future<bool> checkEmailVerified() async {
  try {
    await _auth.currentUser?.reload();
    _firebaseUser = _auth.currentUser;

    if (_firebaseUser?.emailVerified ?? false) {

      final isBackendVerified = await _verifyTokenToBackend();
      
      if (isBackendVerified) {
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return true; 
      }
    }
  } catch (e) {
    debugPrint("Gagal polling email: $e");
  }
  return false;
}

  Future<void> resendVerificationEmail() async {
    await _firebaseUser?.sendEmailVerification();
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
        'email-already-in-use' => 'Email sudah terdaftar.',
        'user-not-found' => 'Akun tidak ditemukan.',
        'wrong-password' => 'Password salah.',
        'invalid-email' => 'Format email tidak valid.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        _ => 'Terjadi kesalahan: $code',
      };
}