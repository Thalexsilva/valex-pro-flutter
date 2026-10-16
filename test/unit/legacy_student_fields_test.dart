import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/student_model.dart';

void main() {
  test('student model reads CPF stored in legacy extra fields', () {
    final student = Student.fromJson({
      'id': 'legacy-student',
      'name': 'Aluno',
      'extra': {'cpf': '000.000.000-00'},
    });
    expect(student.cpf, '000.000.000-00');
  });
}
