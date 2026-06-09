import 'package:flutter/material.dart';

/// Envolve o conteúdo respeitando notch, status bar e áreas do sistema.
class BylabSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const BylabSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  /// Para [Scaffold] com barra inferior — evita padding duplo embaixo.
  const BylabSafeArea.withBottomNav({super.key, required this.child})
    : top = true,
      bottom = false,
      left = true,
      right = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
