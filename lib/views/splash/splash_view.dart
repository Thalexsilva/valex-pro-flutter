import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';

/// Abertura da experiência VALEX, com a mesma paleta e ritmo do aplicativo.
class SplashView extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashView({super.key, required this.onComplete});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // main() termina a inicialização antes de criar a árvore de widgets.
    // Uma frame permite pintar a abertura sem atrasar a primeira ação.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.carbon1,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.carbon1,
                      AppColors.carbon,
                      AppColors.carbon2,
                    ],
                    stops: [0, 0.62, 1],
                  ),
                ),
              ),
              Align(
                alignment: wide ? Alignment.centerRight : Alignment.center,
                child: Container(
                  width: wide ? 700 : 440,
                  height: wide ? 700 : 440,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: 0.12),
                        AppColors.blue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 64 : 24,
                    vertical: wide ? 36 : 24,
                  ),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: _BrandAndProgress(
                                  logoWidth: 220,
                                  reducedMotion: reducedMotion,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _Character(reducedMotion: reducedMotion),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 12),
                            const _Brand(logoWidth: 170),
                            const SizedBox(height: 22),
                            Expanded(
                              child: _Character(reducedMotion: reducedMotion),
                            ),
                            const SizedBox(height: 20),
                            _Progress(reducedMotion: reducedMotion),
                            const SizedBox(height: 12),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandAndProgress extends StatelessWidget {
  final double logoWidth;
  final bool reducedMotion;

  const _BrandAndProgress({
    required this.logoWidth,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Brand(logoWidth: logoWidth),
      const SizedBox(height: 58),
      _Progress(reducedMotion: reducedMotion),
    ],
  );
}

class _Brand extends StatelessWidget {
  final double logoWidth;

  const _Brand({required this.logoWidth});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/images/logo_final.png',
        width: logoWidth,
        filterQuality: FilterQuality.high,
        semanticLabel: 'VALEX Pro',
      ),
      const SizedBox(height: 14),
      const Text(
        'PRECISION TRAINING PROTOCOL',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: AppColors.steel,
        ),
      ),
    ],
  );
}

class _Character extends StatelessWidget {
  final bool reducedMotion;

  const _Character({required this.reducedMotion});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: reducedMotion ? Duration.zero : AppMotion.entrance,
    curve: AppMotion.easeOut,
    tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
    builder: (context, value, child) => Opacity(opacity: value, child: child),
    child: Image.asset(
      'assets/images/character.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    ),
  );
}

class _Progress extends StatelessWidget {
  final bool reducedMotion;

  const _Progress({required this.reducedMotion});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando o aplicativo VALEX Pro',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: reducedMotion
              ? const Icon(
                  Icons.bolt_rounded,
                  size: 24,
                  color: AppColors.blueLight,
                )
              : const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blueLight,
                  backgroundColor: AppColors.carbon3,
                ),
        ),
        const SizedBox(height: 20),
        const Text(
          'PREPARANDO SEU TREINO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: AppColors.steelLight,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tudo pronto em instantes',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.steel),
        ),
      ],
    ),
  );
}
