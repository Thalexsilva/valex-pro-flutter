import 'package:flutter/material.dart';

/// Ritmo compartilhado para mudanças de estado na interface operacional.
abstract final class AppMotion {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 180);
  static const entrance = Duration(milliseconds: 240);
  static const easeOut = Curves.easeOutCubic;
}

/// Transição de rota discreta; preserva o gesto nativo no iOS.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst || MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.90, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.016),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
