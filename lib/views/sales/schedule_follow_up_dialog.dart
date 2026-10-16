import 'package:flutter/material.dart';
import '../../models/sales_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class ScheduleFollowUpDialog extends StatefulWidget {
  final LeadItem lead;
  final Function(DateTime? scheduledDate, String? note) onSave;

  const ScheduleFollowUpDialog({
    super.key,
    required this.lead,
    required this.onSave,
  });

  @override
  State<ScheduleFollowUpDialog> createState() => _ScheduleFollowUpDialogState();
}

class _ScheduleFollowUpDialogState extends State<ScheduleFollowUpDialog> {
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    if (widget.lead.scheduledFollowUpDate != null &&
        widget.lead.scheduledFollowUpDate!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(widget.lead.scheduledFollowUpDate!);
        _selectedDate = parsed;
        _selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {}
    }
    _noteController = TextEditingController(
      text: widget.lead.scheduledFollowUpNote ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _setShortcutDate(int daysFromNow, {String defaultNote = ''}) {
    final now = DateTime.now();
    final target = now.add(Duration(days: daysFromNow));
    setState(() {
      _selectedDate = DateTime(
        target.year,
        target.month,
        target.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      if (defaultNote.isNotEmpty && _noteController.text.trim().isEmpty) {
        _noteController.text = defaultNote;
      }
    });
  }

  void _setNextDayOfMonth(int dayOfMonth, {String defaultNote = ''}) {
    final now = DateTime.now();
    DateTime target;
    if (now.day < dayOfMonth) {
      target = DateTime(
        now.year,
        now.month,
        dayOfMonth,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    } else {
      // Próximo mês
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      target = DateTime(
        nextYear,
        nextMonth,
        dayOfMonth,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    }
    setState(() {
      _selectedDate = target;
      if (defaultNote.isNotEmpty && _noteController.text.trim().isEmpty) {
        _noteController.text = defaultNote;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue,
              surface: AppColors.carbon2,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue,
              surface: AppColors.carbon2,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        if (_selectedDate != null) {
          _selectedDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  void _submit() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma data para o retorno.')),
      );
      return;
    }

    final finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    widget.onSave(finalDateTime, _noteController.text.trim());
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onSave(null, null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.lead.hasScheduledFollowUp;

    return Dialog(
      backgroundColor: AppColors.carbon2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alarm_on_rounded,
                          color: AppColors.goldLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AGENDAR RETORNO',
                            style: AppTheme.headlineMd(color: Colors.white),
                          ),
                          Text(
                            'Lembrete para ${widget.lead.name}',
                            style: const TextStyle(
                              color: AppColors.steelDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.steelDim),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.carbon3, height: 20),

              // Atalhos Rápidos (1-Toque)
              Text(
                'ATALHOS RÁPIDOS (QUANDO O CLIENTE PEDE):',
                style: AppTheme.labelCaps(color: AppColors.steelDim),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ShortcutButton(
                    label: '⏰ Amanhã',
                    onTap: () => _setShortcutDate(
                      1,
                      defaultNote: 'Pediu contato amanhã',
                    ),
                  ),
                  _ShortcutButton(
                    label: '📅 Em 3 Dias',
                    onTap: () =>
                        _setShortcutDate(3, defaultNote: 'Retorno em 3 dias'),
                  ),
                  _ShortcutButton(
                    label: '🚀 Próx. Segunda',
                    onTap: () => _setShortcutDate(
                      7,
                      defaultNote: 'Retorno no início da semana',
                    ),
                  ),
                  _ShortcutButton(
                    label: '💰 Dia 5 (Salário)',
                    onTap: () => _setNextDayOfMonth(
                      5,
                      defaultNote: 'Contato no dia do pagamento (Dia 5)',
                    ),
                  ),
                  _ShortcutButton(
                    label: '💰 Dia 10 (Salário)',
                    onTap: () => _setNextDayOfMonth(
                      10,
                      defaultNote: 'Contato no dia do pagamento (Dia 10)',
                    ),
                  ),
                  _ShortcutButton(
                    label: '💰 Dia 20 (Adiantamento)',
                    onTap: () => _setNextDayOfMonth(
                      20,
                      defaultNote: 'Contato no adiantamento (Dia 20)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seletor de Data e Hora
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedDate != null
                            ? AppColors.blueLight
                            : AppColors.steel,
                        side: BorderSide(
                          color: _selectedDate != null
                              ? AppColors.blueLight
                              : AppColors.carbon3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                            : 'Escolher Data',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldLight,
                        side: const BorderSide(color: AppColors.carbon3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Motivo / Anotação
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo do Retorno / O que o cliente disse',
                  hintText: 'Ex: Pediu para ligar sexta-feira após o almoço...',
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: AppColors.steelDim,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasExisting)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.crimson,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text(
                        'REMOVER LEMBRETE',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: _clear,
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(color: AppColors.steelDim),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusBtn,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'SALVAR LEMBRETE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ShortcutButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.carbon1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.steel,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
