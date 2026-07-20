import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Text(label);

    if (icon == null) {
      return FilledButton(onPressed: onPressed, child: buttonChild);
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: buttonChild,
    );
  }
}
