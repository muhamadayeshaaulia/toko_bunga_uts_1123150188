import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_router.dart';
import '../providers/auth_provider.dart';

import '../widgets/auth_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/loading_overlay.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Fungsi Login menggunakan Email & Password
  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    _handleLoginResult(ok, auth);
  }

  // Fungsi Login menggunakan Google
  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    
    if (!mounted) return;
    _handleLoginResult(ok, auth);
  }

  // Helper untuk menangani hasil navigasi setelah login
  void _handleLoginResult(bool ok, AuthProvider auth) {
    if (ok) {
      // Jika berhasil dan sudah terverifikasi, masuk ke Dashboard
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } 
    else if (auth.status == AuthStatus.emailNotVerified) {
      // Jika login berhasil tapi email belum diverifikasi
      Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
    } else {
      // Tampilkan error jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login gagal, silakan cek kembali'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog untuk Lupa Password
  void _showForgotPasswordDialog(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan email Anda untuk menerima link reset password:'),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              hint: 'contoh@email.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (!EmailValidator.validate(email)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Format email salah'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx);
              
              final auth = context.read<AuthProvider>();
              final ok = await auth.resetPassword(email);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link reset password telah dikirim ke email Anda'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(auth.errorMessage ?? 'Gagal mengirim email reset'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Kirim Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Memantau status loading dari AuthProvider
    final authWatch = context.watch<AuthProvider>();
    final isLoading = authWatch.isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Masuk ke akun...',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const AuthHeader(
                    icon: Icons.lock_open_outlined,
                    title: 'Selamat Datang',
                    subtitle: 'Masuk ke akun Anda untuk melanjutkan',
                  ),
                  const SizedBox(height: 32),
                  
                  // Input Email
                  CustomTextField(
                    label: 'Email',
                    hint: 'contoh@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email wajib diisi';
                      if (!EmailValidator.validate(v!)) return 'Format email salah';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Input Password
                  CustomTextField(
                    label: 'Password',
                    hint: 'Masukkan password',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Password wajib diisi' : null,
                  ),
                  
                  // Lupa Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tombol Login Utama
                  CustomButton(
                    label: 'Masuk',
                    onPressed: _loginEmail,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),
                  
                  const DividerWithText(text: 'atau masuk dengan'),
                  const SizedBox(height: 20),
                  
                  // Tombol Login Google
                  GoogleSignInButton(
                    onPressed: _loginGoogle,
                    isLoading: isLoading,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Navigasi ke Halaman Daftar (Register)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigasi ke rute Register
                          Navigator.pushNamed(context, AppRouter.register);
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}