import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AuthGuard extends StatelessWidget {
  late final Widget child;
 
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

