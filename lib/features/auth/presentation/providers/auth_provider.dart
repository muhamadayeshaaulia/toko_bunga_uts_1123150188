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

 }

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

