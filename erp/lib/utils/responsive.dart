import 'package:flutter/material.dart';

/// Helpers de layout responsivo (mobile / landscape / tablet / desktop).
class AppResponsive {
  AppResponsive._();

  /// Sidebar completa só com largura e altura suficientes.
  /// Em landscape de celular (ex.: 900x390) evita menu lateral que some itens.
  static bool useSideNav(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 900 && size.height >= 520;
  }

  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  static bool isVeryCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 400;
  }

  /// Padding de conteúdo conforme o breakpoint.
  static EdgeInsets contentPadding(BuildContext context) {
    if (useSideNav(context)) return const EdgeInsets.all(24);
    if (isCompact(context)) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }
}
