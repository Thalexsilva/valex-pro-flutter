import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/marketing_models.dart';
import '../../theme/app_colors.dart';

class TeleprompterDialog extends StatefulWidget {
  final AdCreativeItem creative;

  const TeleprompterDialog({super.key, required this.creative});

  @override
  State<TeleprompterDialog> createState() => _TeleprompterDialogState();
}

class _TeleprompterDialogState extends State<TeleprompterDialog> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  bool _isPlaying = false;
  double _scrollSpeed = 1.0; // 0.5x, 1.0x, 1.5x, 2.0x
  double _fontSize = 20.0;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 3);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        setState(() {
          _countdown = 0;
          _isPlaying = true;
        });
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    final intervalMs = (40 / _scrollSpeed).round();
    _scrollTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_isPlaying || !mounted || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current < maxScroll) {
        _scrollController.jumpTo(current + 1.5);
      } else {
        setState(() => _isPlaying = false);
        timer.cancel();
      }
    });
  }

  void _togglePlayPause() {
    if (_countdown > 0) return;
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      _scrollTimer?.cancel();
    } else {
      if (_scrollController.hasClients && _scrollController.offset == 0) {
        _startCountdown();
      } else {
        setState(() => _isPlaying = true);
        _startAutoScroll();
      }
    }
  }

  void _resetScroll() {
    _scrollTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _countdown = 0;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyToClipboard() {
    final text =
        '''
🔥 GANCHO (3s):
${widget.creative.hookText}

📖 CORPO DO VÍDEO:
${widget.creative.bodyScript}

🚀 CTA FINAL:
${widget.creative.ctaText}
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Roteiro copiado para o WhatsApp!'),
        backgroundColor: AppColors.emerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.carbon1,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.carbon2,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.crimson.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPlaying
                                  ? Icons.fiber_manual_record
                                  : Icons.play_circle_fill,
                              color: _isPlaying
                                  ? AppColors.crimson
                                  : AppColors.steel,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isPlaying
                                  ? 'GRAVANDO (PROMPTER ATIVO)'
                                  : 'MODO TELEPROMPTER',
                              style: const TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 12,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.creative.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: AppColors.steel,
                          size: 20,
                        ),
                        tooltip: 'Copiar Script',
                        onPressed: _copyToClipboard,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.steel),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Área do Teleprompter com Scroll
                Expanded(
                  child: Container(
                    color: const Color(0xFF0A0C10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ListView(
                      controller: _scrollController,
                      physics: _isPlaying
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      children: [
                        const SizedBox(height: 20),
                        // Dica de Gravação
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.carbon3.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mic,
                                color: AppColors.gold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Guia: ${widget.creative.audioGuide}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.steel,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Bloco 1: Gancho (Hook)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.crimson.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔥 GANCHO INICIAL (3 SEGUNDOS) — OLHE FIXO NA CÂMERA:',
                                style: TextStyle(
                                  fontFamily: 'BebasNeue',
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                  color: AppColors.crimson,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.creative.hookText,
                                style: TextStyle(
                                  fontSize: _fontSize + 2,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Bloco 2: Corpo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.carbon2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.carbon3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📖 CORPO DO ANÚNCIO (MÉTODO & QUEBRA DE CRENÇA):',
                                style: TextStyle(
                                  fontFamily: 'BebasNeue',
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                  color: AppColors.blueLight,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.creative.bodyScript,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.paper,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Bloco 3: CTA
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🚀 CHAMADA PARA AÇÃO (CTA FINAL):',
                                style: TextStyle(
                                  fontFamily: 'BebasNeue',
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                  color: AppColors.emerald,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.creative.ctaText,
                                style: TextStyle(
                                  fontSize: _fontSize + 1,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Barra de Controles Inferiores (Ergonomia Android)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.carbon2,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Botão Play / Pause Gigante
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isPlaying
                                ? AppColors.crimson
                                : AppColors.blue,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isPlaying
                                            ? AppColors.crimson
                                            : AppColors.blue)
                                        .withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isPlaying ? 'PAUSAR' : 'INICIAR PROMPTER',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reset
                      IconButton(
                        icon: const Icon(
                          Icons.restart_alt,
                          color: AppColors.steel,
                        ),
                        tooltip: 'Reiniciar do topo',
                        onPressed: _resetScroll,
                      ),
                      const Spacer(),

                      // Tamanho da Fonte
                      IconButton(
                        icon: const Icon(
                          Icons.text_decrease,
                          color: AppColors.steel,
                          size: 20,
                        ),
                        tooltip: 'Diminuir fonte',
                        onPressed: () {
                          if (_fontSize > 14) setState(() => _fontSize -= 2);
                        },
                      ),
                      Text(
                        '${_fontSize.toInt()}pt',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.steelDim,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.text_increase,
                          color: AppColors.steel,
                          size: 20,
                        ),
                        tooltip: 'Aumentar fonte',
                        onPressed: () {
                          if (_fontSize < 32) setState(() => _fontSize += 2);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Velocidade
                      PopupMenuButton<double>(
                        initialValue: _scrollSpeed,
                        tooltip: 'Velocidade de rolagem',
                        color: AppColors.carbon3,
                        onSelected: (spd) {
                          setState(() => _scrollSpeed = spd);
                          if (_isPlaying) _startAutoScroll();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 0.6,
                            child: Text('0.6x (Lento)'),
                          ),
                          const PopupMenuItem(
                            value: 1.0,
                            child: Text('1.0x (Normal)'),
                          ),
                          const PopupMenuItem(
                            value: 1.4,
                            child: Text('1.4x (Rápido)'),
                          ),
                          const PopupMenuItem(
                            value: 2.0,
                            child: Text('2.0x (Ultra)'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.carbon1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.carbon3),
                          ),
                          child: Text(
                            '${_scrollSpeed}x',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blueLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Overlay de Contagem Regressiva 3..2..1
            if (_countdown > 0)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PREPARE-SE PARA GRAVAR:',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 24,
                            letterSpacing: 1.5,
                            color: AppColors.steelDim,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_countdown',
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: AppColors.crimson,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Olhe para a lente do celular!',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
