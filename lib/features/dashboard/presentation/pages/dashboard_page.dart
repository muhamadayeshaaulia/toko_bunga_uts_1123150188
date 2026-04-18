import 'package:flutter/material.dart';
import '../../../auth/presentation/widgets/main_navigation.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DashboardPage sekarang fokus menjadi "Shell" atau pembungkus utama
    // yang isinya dikendalikan oleh MainNavigation
    return const MainNavigation();
  }
}