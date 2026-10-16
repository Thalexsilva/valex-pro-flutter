import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class StudentFormDialog extends StatefulWidget {
  final Student? student;
  final Future<bool> Function(Student student) onSave;

  const StudentFormDialog({super.key, this.student, required this.onSave});

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cpfController;
  late final TextEditingController _gymNameController;
  late final TextEditingController _monthController;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final st = widget.student;
    _nameController = TextEditingController(text: st?.name ?? '');
    _emailController = TextEditingController(text: st?.email ?? '');
    _phoneController = TextEditingController(text: st?.phone ?? '');
    _cpfController = TextEditingController(text: st?.cpf ?? '');
    _gymNameController = TextEditingController(text: st?.gymName ?? '');
    _monthController = TextEditingController(text: st?.month ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _gymNameController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  String _newStudentId() => Formatters.generateUuidV4();

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final updated = (widget.student ?? Student(id: _newStudentId(), name: ''))
        .copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          phone: _phoneController.text.trim(),
          cpf: _cpfController.text.trim(),
          gymName: _gymNameController.text.trim(),
          month: _monthController.text.trim(),
        );

    final saved = await widget.onSave(updated);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = false;
      _saveError = 'Não foi possível salvar o aluno. Tente novamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar Aluno' : 'Novo Aluno'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo *',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nome é obrigatório'
                      : null,
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gymNameController,
                        decoration: const InputDecoration(
                          labelText: 'Academia',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _monthController,
                        decoration: const InputDecoration(
                          labelText: 'Mês/Ano Vigência',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpfController,
                  decoration: const InputDecoration(labelText: 'CPF'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    helperText: 'O aluno entra no portal com este e-mail.',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    return Validators.isValidEmail(text)
                        ? null
                        : 'Informe um e-mail válido, como nome@exemplo.com.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone / Emergência',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }
}
