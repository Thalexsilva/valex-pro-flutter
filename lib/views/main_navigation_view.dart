import 'package:flutter/material.dart';

import '../services/student_context_service.dart';
import '../repositories/finance_repository.dart';
import '../repositories/sales_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import 'about/about_view.dart';
import 'dashboard/dashboard_view.dart';
import 'editor/editor_view.dart';
import 'finance/finance_view.dart';
import 'marketing/marketing_view.dart';
import 'presets/presets_view.dart';
import 'profile/profile_view.dart';
import 'sales/sales_view.dart';
import 'settings/settings_view.dart';
import 'students/students_view.dart';
import 'students/student_access_view.dart';

class MainNavigationView extends StatefulWidget {
  final VoidCallback onLogout;
  final StudentContextService? contextService;

  const MainNavigationView({
    super.key,
    required this.onLogout,
    this.contextService,
  });

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView>
    with SingleTickerProviderStateMixin {
  static const int _dashboardIndex = 0;
  static const int _studentsIndex = 3;
  static const int _financeIndex = 5;
  static const int _editorIndex = 6;

  late final StudentContextService _contextService;
  final FinanceRepository _financeRepository = FinanceRepository();
  int _currentIndex = _dashboardIndex;
  late final AnimationController _navigationMotion;
  late final Animation<double> _navigationOpacity;
  late final Animation<Offset> _navigationOffset;

  late final List<_AppDestination> _destinations;
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _contextService = widget.contextService ?? StudentContextService();
    _navigationMotion = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
      value: 1,
    );
    final curve = CurvedAnimation(
      parent: _navigationMotion,
      curve: AppMotion.easeOut,
    );
    _navigationOpacity = Tween<double>(begin: 0.86, end: 1).animate(curve);
    _navigationOffset = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(curve);
    _contextService.addListener(_onContextUpdate);
    _destinations = const [
      _AppDestination(
        'Visão Geral',
        'Início',
        Icons.home_outlined,
        Icons.home_rounded,
      ),
      _AppDestination(
        'Vendas & CRM',
        'Vendas',
        Icons.trending_up_outlined,
        Icons.trending_up_rounded,
      ),
      _AppDestination(
        'Mídia & Marketing',
        'Marketing',
        Icons.campaign_outlined,
        Icons.campaign_rounded,
      ),
      _AppDestination(
        'Alunos',
        'Alunos',
        Icons.people_outline,
        Icons.people_rounded,
      ),
      _AppDestination(
        'Biblioteca',
        'Biblioteca',
        Icons.menu_book_outlined,
        Icons.menu_book_rounded,
      ),
      _AppDestination(
        'Financeiro',
        'Financeiro',
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded,
      ),
      _AppDestination(
        'Editor Ativo',
        'Editor',
        Icons.edit_note_outlined,
        Icons.edit_note_rounded,
      ),
      _AppDestination(
        'Configurações',
        'Ajustes',
        Icons.settings_outlined,
        Icons.settings_rounded,
      ),
      _AppDestination(
        'Meu Perfil',
        'Perfil',
        Icons.account_circle_outlined,
        Icons.account_circle,
      ),
      _AppDestination('Sobre', 'Sobre', Icons.info_outline, Icons.info),
      _AppDestination(
        'Acessos dos alunos',
        'Acessos',
        Icons.analytics_outlined,
        Icons.analytics,
      ),
    ];
    _views = [
      DashboardView(
        studentContext: _contextService,
        financeRepository: _financeRepository,
        onOpenEditor: () => _selectDestination(_editorIndex),
        onOpenStudents: () => _selectDestination(_studentsIndex),
      ),
      SalesView(repository: SalesRepository()),
      const MarketingView(),
      Navigator(
        key: const ValueKey('students_navigator'),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => StudentsView(contextService: _contextService),
        ),
      ),
      PresetsView(onOpenEditor: () => _selectDestination(_editorIndex)),
      FinanceView(repository: _financeRepository),
      EditorView(
        contextService: _contextService,
        onOpenStudents: () => _selectDestination(_studentsIndex),
      ),
      SettingsView(onLogout: widget.onLogout),
      const ProfileView(),
      const AboutView(showAppBar: false),
      const StudentAccessView(),
    ];
    _initializeContext();
  }

  /// A navegação aparece imediatamente; cada tela mostra o próprio estado
  /// de carga enquanto o cache e o servidor são lidos em segundo plano.
  void _initializeContext() {
    _contextService.init();
  }

  @override
  void dispose() {
    _contextService.removeListener(_onContextUpdate);
    _navigationMotion.dispose();
    super.dispose();
  }

  void _onContextUpdate() {
    if (mounted) setState(() {});
  }

  void _selectDestination(int index) {
    if (index < 0 || index >= _views.length) return;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (MediaQuery.disableAnimationsOf(context)) {
      _navigationMotion.value = 1;
    } else {
      _navigationMotion.forward(from: 0);
    }
  }

  Widget _animatedContent() => FadeTransition(
    opacity: _navigationOpacity,
    child: SlideTransition(
      position: _navigationOffset,
      child: IndexedStack(index: _currentIndex, children: _views),
    ),
  );

  bool get _isMoreDestination => !{
    _dashboardIndex,
    _studentsIndex,
    _financeIndex,
    _editorIndex,
  }.contains(_currentIndex);

  Future<void> _showMoreDestinations() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.carbon2,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        const moreGroups = <String, List<int>>{
          'Crescimento': [1, 2],
          'Prescrição': [4],
          'Conta e aplicativo': [7, 8, 9],
          'Alunos': [10],
        };
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mais ferramentas', style: AppTheme.headlineMd()),
                    const SizedBox(height: 12),
                    for (final group in moreGroups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          group.key,
                          style: AppTheme.labelCaps(
                            color: AppColors.steelLight,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.value.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              mainAxisExtent: 64,
                            ),
                        itemBuilder: (context, position) {
                          final index = group.value[position];
                          final destination = _destinations[index];
                          final isSelected = index == _currentIndex;
                          return Material(
                            color: isSelected
                                ? AppColors.blue.withValues(alpha: 0.18)
                                : AppColors.carbon3,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              key: ValueKey('more_destination_$index'),
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? destination.selectedIcon
                                          : destination.icon,
                                      color: isSelected
                                          ? AppColors.blueLight
                                          : AppColors.steel,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        destination.mobileLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.bodyMd(
                                          color: isSelected
                                              ? AppColors.blueLight
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) _selectDestination(selected);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 800 ? _buildDesktop(width) : _buildMobile();
  }

  Widget _buildDesktop(double width) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: Row(
        children: [
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height,
              ),
              child: IntrinsicHeight(
                child: NavigationRail(
                  backgroundColor: AppColors.carbon1,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectDestination,
                  extended: width >= 1180,
                  minWidth: 76,
                  minExtendedWidth: 236,
                  useIndicator: true,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                      semanticLabel: 'VALEX',
                    ),
                  ),
                  destinations: _destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(
                            destination.selectedIcon,
                            color: AppColors.blueLight,
                          ),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.carbon3,
          ),
          Expanded(child: _animatedContent()),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    final activeStudent = _contextService.activeStudent;
    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _destinations[_currentIndex].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headlineSm(),
              ),
            ),
          ],
        ),
        actions: [
          if (activeStudent != null)
            Semantics(
              button: true,
              label: 'Abrir ficha de ${activeStudent.name}',
              child: IconButton(
                tooltip: 'Ficha de ${activeStudent.name}',
                onPressed: () => _selectDestination(_editorIndex),
                icon: const Icon(Icons.person_pin_circle_outlined),
              ),
            ),
        ],
      ),
      body: _animatedContent(),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _isMoreDestination
            ? 4
            : [
                _dashboardIndex,
                _studentsIndex,
                _editorIndex,
                _financeIndex,
              ].indexOf(_currentIndex),
        onDestinationSelected: (position) {
          if (position == 4) {
            _showMoreDestinations();
            return;
          }
          const indexes = [
            _dashboardIndex,
            _studentsIndex,
            _editorIndex,
            _financeIndex,
          ];
          _selectDestination(indexes[position]);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Alunos',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Financeiro',
          ),
          NavigationDestination(
            key: const ValueKey('more_nav_destination'),
            icon: const Icon(Icons.more_horiz),
            label: _isMoreDestination
                ? _destinations[_currentIndex].mobileLabel
                : 'Mais',
            tooltip: _isMoreDestination
                ? 'Mais ferramentas: ${_destinations[_currentIndex].label}'
                : 'Mais ferramentas',
          ),
        ],
      ),
    );
  }
}

class _AppDestination {
  final String label;
  final String mobileLabel;
  final IconData icon;
  final IconData selectedIcon;

  const _AppDestination(
    this.label,
    this.mobileLabel,
    this.icon,
    this.selectedIcon,
  );
}
