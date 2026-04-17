import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uts_1123150188_semester6/features/auth/presentation/pages/Register_page.dart';
import 'package:uts_1123150188_semester6/features/auth/presentation/pages/login_page.dart';
import 'package:uts_1123150188_semester6/features/auth/presentation/pages/verify_email_page.dart';
import 'package:uts_1123150188_semester6/features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';


class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
 
    return switch (status) {
      AuthStatus.authenticated    => child,                   // Lanjut
      AuthStatus.emailNotVerified => const VerifyEmailPage(), // Redirect
      _                           => const LoginPage(),       // Redirect login
    };
  }
}

class AppRouter {
  static const String splash      = '/';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String verifyEmail = '/verify-email';
  static const String dashboard   = '/dashboard';


  static Map<String, WidgetBuilder> get routes => {
    splash:      (_) => const SplashPage(),
    login:       (_) => const LoginPage(),
    register:    (_) => const RegisterPage(),
    verifyEmail: (_) => const VerifyEmailPage(),
    dashboard:   (_) => const AuthGuard(child: DashboardPage()),

  };

  class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title:                  'My App',
        debugShowCheckedModeBanner: false,
        theme:                  AppTheme.light,
        initialRoute:           AppRouter.splash,
        routes:                 AppRouter.routes,
      ),
    );
  }
}


// SplashPage: cek token tersimpan, redirect otomatis
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override State<SplashPage> createState() => _SplashPageState();
}


class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }


  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Animasi splash
    if (!mounted) return;


    final token = await SecureStorageService.getToken();
    final route = token != null ? AppRouter.dashboard : AppRouter.login;
    Navigator.pushReplacementNamed(context, route);
  }


  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

}