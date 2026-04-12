import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  bool  _showPass   = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return const Placeholder();
  }
}