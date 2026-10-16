import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../repositories/student_access_repository.dart';
import '../../repositories/student_repository.dart';
import '../../theme/app_colors.dart';

class StudentAccessView extends StatefulWidget {
  const StudentAccessView({super.key});

  @override
  State<StudentAccessView> createState() => _StudentAccessViewState();
}

class _StudentAccessViewState extends State<StudentAccessView> {
  final _accessRepository = StudentAccessRepository();
  final _studentRepository = StudentRepository();
  List<StudentAccessEvent> _events = [];
  List<Student> _students = [];
  (int, int) _summary = (0, 0);
  bool _loading = true;
  String? _error;
  int _days = 30;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _studentRepository.fetchStudentsOrThrow(),
        _accessRepository.recent(days: _days),
        _accessRepository.summary(days: _days),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0] as List<Student>;
        _events = results[1] as List<StudentAccessEvent>;
        _summary = results[2] as (int, int);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível carregar os acessos. Confira a conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(DateTime value) {
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  String _location(StudentAccessEvent event) {
    final parts = [
      event.city,
      event.region,
      event.country,
    ].whereType<String>().where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Região indisponível' : parts.join(', ');
  }

  Widget _metric(String label, String value, IconData icon) => Container(
    width: 176,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.carbon2,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.carbon3),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blueLight),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: AppColors.steelDim)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final names = {for (final student in _students) student.id: student.name};
    final filtered = _events.where((event) {
      final query = _search.trim().toLowerCase();
      return query.isEmpty ||
          (names[event.studentId] ?? '').toLowerCase().contains(query) ||
          (event.ipAddress ?? '').contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Acessos dos alunos',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar acessos',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Logins confirmados no app. A região é estimada pela rede e pode estar indisponível ou imprecisa.',
              style: TextStyle(color: AppColors.steelDim),
            ),
            const SizedBox(height: 20),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 dias')),
                ButtonSegment(value: 30, label: Text('30 dias')),
              ],
              selected: {_days},
              onSelectionChanged: (selection) {
                setState(() => _days = selection.first);
                _load();
              },
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: AppColors.crimsonText),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric(
                    'Alunos que acessaram',
                    '${_summary.$2}',
                    Icons.people_alt_outlined,
                  ),
                  _metric('Logins registrados', '${_summary.$1}', Icons.login),
                  _metric(
                    'Sem acesso no período',
                    '${(_students.length - _summary.$2).clamp(0, _students.length)}',
                    Icons.person_off_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Histórico: até 500 acessos recentes no período. Os totais consideram todos os registros.',
                style: TextStyle(color: AppColors.steelDim, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar aluno ou IP',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhum acesso encontrado neste período.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final event in filtered)
                Card(
                  key: ValueKey(
                    'access_${event.studentId}_${event.occurredAt.toIso8601String()}',
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              names[event.studentId] ?? 'Aluno',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _date(event.occurredAt),
                              style: const TextStyle(color: AppColors.steelDim),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('IP: ${event.ipAddress ?? 'Indisponível'}'),
                        Text('Região: ${_location(event)}'),
                        Text('Plataforma: ${event.platform ?? 'Indisponível'}'),
                        if (event.timeZone != null)
                          Text('Fuso do dispositivo: ${event.timeZone}'),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
