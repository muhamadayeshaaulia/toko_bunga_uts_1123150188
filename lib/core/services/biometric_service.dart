import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricKey = 'biometric_enabled';

  /// Cek apakah perangkat mendukung biometrik
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Ambil status toggle biometrik dari SharedPreferences
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  /// Simpan status toggle biometrik
  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
  }

  /// Tampilkan dialog biometrik dan minta autentikasi
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk masuk ke aplikasi',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
