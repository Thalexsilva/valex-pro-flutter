import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/models/sales_model.dart';
import 'package:valex_app/repositories/sales_repository.dart';

List<Student> get testStudents => [
  Student(
    id: 'st_1',
    name: 'Carlos Silva',
    email: 'carlos@example.com',
    gymName: 'Academia Teste',
  ),
  Student(id: 'st_2', name: 'Mariana Costa', email: 'mariana@example.com'),
  Student(id: 'st_3', name: 'Aluno Arquivado', status: StudentStatus.archived),
];

class EmptySalesRepository extends SalesRepository {
  @override
  Future<List<LeadItem>> fetchLeads() async => [];
}
