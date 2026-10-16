import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// StatusDot — ponto de status animado (pulse-subtle) do Carbon Pro Stitch.
/// Cores: emerald (ativo), amber (pendente), outline (inativo), crimson (atrasado)
class StatusDot extends StatefulWidget {
  final StatusType status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 6});

  @override
  State<StatusDot> createState() => _StatusDotState();
}

enum StatusType { active, pending, overdue, inactive }

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.status) {
      case StatusType.active:
        return AppColors.emerald;
      case StatusType.pending:
        return AppColors.amber;
      case StatusType.overdue:
        return AppColors.crimson;
      case StatusType.inactive:
        return AppColors.outline;
    }
  }

  bool get _shouldAnimate =>
      widget.status == StatusType.active || widget.status == StatusType.pending;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: _shouldAnimate
            ? [
                BoxShadow(
                  color: _color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    if (!_shouldAnimate) return dot;

    return FadeTransition(opacity: _opacity, child: dot);
  }
}

/// Label de status legível ao lado do dot
class StatusLabel extends StatelessWidget {
  final StatusType status;

  const StatusLabel({super.key, required this.status});

  String get _label {
    switch (status) {
      case StatusType.active:
        return 'Ativo';
      case StatusType.pending:
        return 'Pendente';
      case StatusType.overdue:
        return 'Atrasado';
      case StatusType.inactive:
        return 'Inativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(status: status),
        const SizedBox(width: 6),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
