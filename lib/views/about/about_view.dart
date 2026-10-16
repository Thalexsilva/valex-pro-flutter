import 'package:flutter/material.dart';

import '../../config/app_info.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Tela "Sobre" (RF004): objetivo do app, equipe e dados institucionais.
class AboutView extends StatelessWidget {
  const AboutView({super.key, this.showAppBar = true});

  /// Falso quando embutida em outra tela que já possui AppBar.
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 56,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppColors.carbon2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppInfo.name,
                  style: AppTheme.headlineMd(color: AppColors.blueLight),
                ),
                const SizedBox(height: 8),
                Text(
                  AppInfo.versionLabel,
                  style: AppTheme.bodyMd(color: AppColors.steel),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          icon: Icons.flag_outlined,
          title: 'Objetivo',
          child: Text(
            AppInfo.objective,
            style: AppTheme.bodyLg(color: Colors.white),
          ),
        ),
        _Section(
          icon: Icons.groups_outlined,
          title: 'Equipe de desenvolvimento',
          child: Column(
            children: [
              for (final member in AppInfo.team)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.carbon3,
                    child: Icon(Icons.person, color: AppColors.blueLight),
                  ),
                  title: Text(
                    member,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        _Section(
          icon: Icons.school_outlined,
          title: 'Informações acadêmicas',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Instituição', AppInfo.institution),
              if (AppInfo.course.isNotEmpty)
                _InfoRow('Disciplina', AppInfo.course),
              if (AppInfo.professor.isNotEmpty)
                _InfoRow('Professor(a)', AppInfo.professor),
              _InfoRow('Versão', AppInfo.version),
            ],
          ),
        ),
        _Section(
          icon: Icons.apps_outlined,
          title: 'Funcionalidades',
          child: Column(
            children: [
              for (final feature in AppInfo.features)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.emerald,
                  ),
                  title: Text(
                    feature,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (!showAppBar) return content;
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(title: const Text('Sobre')),
      body: content,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.carbon2,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blueLight, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTheme.headlineSm())),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.steel),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
