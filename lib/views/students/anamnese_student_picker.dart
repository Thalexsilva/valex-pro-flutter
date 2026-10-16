import 'package:flutter/material.dart';
import '../../models/student_model.dart';

class AnamneseStudentPicker extends StatefulWidget {
  final List<Student> students;
  const AnamneseStudentPicker({super.key, required this.students});

  @override
  State<AnamneseStudentPicker> createState() => _AnamneseStudentPickerState();
}

class _AnamneseStudentPickerState extends State<AnamneseStudentPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final students = widget.students
        .where(
          (s) =>
              !s.isArchived &&
              s.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return AlertDialog(
      title: const Text('Selecionar aluno'),
      content: SizedBox(
        width: 440,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar aluno',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('Nenhum aluno encontrado.'))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (ctx, index) {
                        final student = students[index];
                        return ListTile(
                          title: Text(student.name),
                          subtitle: student.email.isEmpty
                              ? null
                              : Text(student.email),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, student),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
