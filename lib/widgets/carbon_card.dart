import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Superfície padrão do app. O vidro fica reservado para telas com imagem de fundo.
class CarbonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool premiumBorder;
  final bool solid;
  final double blurSigma;
  final VoidCallback? onTap;

  const CarbonCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.premiumBorder = false,
    this.solid = true,
    this.blurSigma = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppColors.radiusCard);
    final effectivePadding =
        padding ?? const EdgeInsets.all(AppColors.densityComfortable);

    if (solid && onTap != null && !premiumBorder) {
      return Material(
        color: AppColors.carbon2,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.carbon3,
          focusColor: AppColors.blue.withValues(alpha: 0.18),
          splashColor: AppColors.blue.withValues(alpha: 0.14),
          child: Padding(padding: effectivePadding, child: child),
        ),
      );
    }

    Widget card = solid
        ? Container(
            decoration: BoxDecoration(
              color: AppColors.carbon2,
              borderRadius: radius,
              border: Border.all(color: AppColors.dividerColor),
            ),
            padding: effectivePadding,
            child: child,
          )
        : ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 1.0],
                    colors: [
                      Color(0x80272A30), // rgba(39,42,48,0.5)
                      Color(0xB3191C22), // rgba(25,28,34,0.7)
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  padding: effectivePadding,
                  child: child,
                ),
              ),
            ),
          );

    if (premiumBorder) {
      card = _PremiumBorderWrapper(radius: radius, child: card);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Gradient border sutil (azul → branco → azul) — premium-border::after do Stitch
class _PremiumBorderWrapper extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;

  const _PremiumBorderWrapper({required this.child, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientBorderPainter(radius: radius),
      child: child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final BorderRadius radius;
  _GradientBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
        colors: [
          Color(0x4D2F8FE6), // rgba(47,143,230,0.3)
          Color(0x1AFFFFFF), // rgba(255,255,255,0.1)
          Color(0x1A2F8FE6), // rgba(47,143,230,0.1)
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) => false;
}
