import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../services/backup_service.dart';
import '../../services/file_export_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../about/about_view.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsView({super.key, required this.onLogout});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final BackupService _backupService = BackupService();
  BackupDiagnostics? _diagnostics;
  bool _isLoading = true;
  bool _backupBusy = false;
  String? _diagnosticsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);
    try {
      final diag = await _backupService.getDiagnostics();
      if (mounted) {
        setState(() {
          _diagnostics = diag;
          _diagnosticsError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _diagnosticsError =
              'Não foi possível carregar os diagnósticos. Verifique sua conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final jsonStr = await _backupService.exportFullBackup();
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final saved = await FileExportService.downloadText(
        'valex-backup-$date.json',
        jsonStr,
        'application/json',
      );
      if (!saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exportação cancelada. Nenhum arquivo foi salvo.'),
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup JSON baixado com sucesso.'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível exportar os dados. Verifique sua conexão e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackupFile() async {
    if (_backupBusy) return;
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Backup VALEX JSON',
            extensions: ['json'],
            mimeTypes: ['application/json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        throw const FormatException('O arquivo excede o limite de 20 MB.');
      }
      final content = utf8.decode(bytes);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic> ||
          (decoded['valex_backup_version'] ?? decoded['schemaVersion']) != 3 ||
          decoded['data'] is! Map<String, dynamic>) {
        throw const FormatException('Selecione um backup VALEX JSON versão 3.');
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.carbon2,
          title: const Text('Restaurar backup?'),
          content: Text(
            'Arquivo: ${file.name}\n\nAlunos, fichas, presets, leads e dados financeiros serão importados. '
            'Anexos, anamneses, marketing e histórico de versões não fazem parte deste backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _backupBusy = true);
      final result = await _backupService.importFullBackup(content);
      if (!mounted) return;
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Falha ao importar.'),
          backgroundColor: success ? AppColors.emerald : AppColors.crimson,
        ),
      );
      if (success) await _loadDiagnostics();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Não foi possível ler o backup JSON. Tente novamente.',
          ),
          backgroundColor: AppColors.crimson,
        ),
      );
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _confirmResetDialog() async {
    final confirmController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.crimson),
            const SizedBox(width: 8),
            Text(
              'ZONA DE PERIGO',
              style: AppTheme.headlineMd(color: AppColors.crimson),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta ação apagará permanentemente todos os alunos, fichas, treinos, presets e dados financeiros armazenados localmente.\n\nPara confirmar a destruição, digite "RESETAR" abaixo:',
              style: AppTheme.bodyMd(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'RESETAR',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.crimson),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.steel),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: confirmController,
            builder: (context, value, _) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
              ),
              onPressed: value.text.trim() == 'RESETAR'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Confirmar Reset Total'),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final ok = await _backupService.resetDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Banco de dados resetado com sucesso.'
                  : 'Falha ao resetar banco.',
            ),
            backgroundColor: ok ? AppColors.emerald : AppColors.crimson,
          ),
        );
        _loadDiagnostics();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon2,
        title: Text('Configurações', style: AppTheme.headlineMd()),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.steelLight,
          unselectedLabelColor: AppColors.steel,
          indicatorColor: AppColors.blueLight,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dados e Backup'),
            Tab(text: 'Diagnósticos'),
            Tab(text: 'Sobre'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba 1: Dados e Backup
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.carbon2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exportação & Importação de Dados',
                        style: AppTheme.headlineMd(color: AppColors.blueLight),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exporta alunos, fichas, presets, leads e financeiro local. Não inclui anexos, anamneses, marketing ou histórico de versões. Esta exportação não substitui o backup do servidor.',
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Exportar Dados (JSON)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                            ),
                            onPressed: _backupBusy ? null : _exportBackup,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.upload),
                            label: const Text('Importar Backup JSON'),
                            onPressed: _backupBusy ? null : _importBackupFile,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.carbon2,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.crimson, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.crimson,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Zona de Perigo (Destrutivo)',
                              style: AppTheme.headlineMd(
                                color: AppColors.crimson,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Apagar o banco de dados local removerá permanentemente todos os alunos, treinos e faturas deste dispositivo.',
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Limpar Dados Locais'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                        ),
                        onPressed: _confirmResetDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Aba 2: Diagnósticos e Auditoria
          _diagnosticsError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_diagnosticsError!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _loadDiagnostics,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _isLoading || _diagnostics == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blueLight),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: AppColors.carbon2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Integridade e Diagnóstico do Sistema',
                              style: AppTheme.headlineMd(
                                color: AppColors.blueLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DiagRow(
                              'Versão do Aplicativo',
                              _diagnostics!.appVersion,
                            ),
                            _DiagRow(
                              'Integridade do Schema',
                              _diagnostics!.cacheIntegrity,
                            ),
                            _DiagRow(
                              'Total de Alunos',
                              '${_diagnostics!.totalStudents} cadastrados',
                            ),
                            _DiagRow(
                              'Total de Fichas de Treino',
                              '${_diagnostics!.totalWorkouts} ativas',
                            ),
                            _DiagRow(
                              'Total de Presets',
                              '${_diagnostics!.totalPresets} salvos',
                            ),
                            _DiagRow(
                              'Total de Leads (CRM)',
                              '${_diagnostics!.totalLeads} registros',
                            ),
                            _DiagRow(
                              'Total de Faturas',
                              '${_diagnostics!.totalInvoices} geradas',
                            ),
                            _DiagRow(
                              'Supabase Conectado',
                              _diagnostics!.hasAuthenticatedUser
                                  ? 'Sim (Autenticado)'
                                  : 'Não (Local/Offline)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

          // Aba 3: Sobre
          const AboutView(showAppBar: false),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.steel, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
