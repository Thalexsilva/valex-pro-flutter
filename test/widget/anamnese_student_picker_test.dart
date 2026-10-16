import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/views/students/anamnese_student_picker.dart';

void main() {
  testWidgets('filters active students and returns the selected identity', (
    tester,
  ) async {
    Student? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showDialog<Student>(
                  context: context,
                  builder: (_) => AnamneseStudentPicker(
                    students: [
                      Student(id: 'a', name: 'Ana'),
                      Student(id: 'b', name: 'Bruno'),
                      Student(
                        id: 'c',
                        name: 'Arquivado',
                        status: StudentStatus.archived,
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Arquivado'), findsNothing);
    await tester.enterText(find.byType(TextField), 'brun');
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsNothing);
    await tester.tap(find.text('Bruno'));
    await tester.pumpAndSettle();
    expect(selected?.id, 'b');
  });
}
