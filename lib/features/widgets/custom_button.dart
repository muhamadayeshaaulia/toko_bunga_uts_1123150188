import 'package:flutter/material.dart';
enum ButtonType { primary, outline, text }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final Widget? icon;

  const CustomButton({super.key,
  required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}