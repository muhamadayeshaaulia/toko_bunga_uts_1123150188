import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Wajib tambahkan ini
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as gap;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    await context.read<gap.AuthProvider>().initializeAuth();

    if (!mounted) return;

    final auth = context.read<gap.AuthProvider>();
    if (auth.status == gap.AuthStatus.authenticated) {
      // Cek apakah biometrik diaktifkan oleh user
      final isBiometricEnabled = await BiometricService.isEnabled();
      if (isBiometricEnabled) {
        final authenticated = await BiometricService.authenticate();
        if (!mounted) return;
        if (!authenticated) {
          // Gagal / batal → logout dan kembali ke login
          await auth.logout();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRouter.login);
          return;
        }
      }
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else if (auth.status == gap.AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}