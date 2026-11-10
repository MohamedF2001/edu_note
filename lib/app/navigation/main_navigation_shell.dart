import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/authentication/presentation/pages/teacher_profile_page.dart';
import '../../features/navigation/presentation/pages/class_workspace_page.dart';
import '../../features/schools/presentation/pages/schools_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  static const _sections = <_NavigationSection>[
    _NavigationSection('Accueil', Icons.home_rounded),
    _NavigationSection('Établissements', Icons.apartment_rounded),
    _NavigationSection('Évaluations', Icons.assignment_rounded),
    _NavigationSection('Résultats', Icons.bar_chart_rounded),
    _NavigationSection('Profil', Icons.person_rounded),
  ];

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(key: const ValueKey('dashboard'), onSelectTab: _onSelectTab),
      SchoolsPage(
        key: const ValueKey('schools'),
        isActive: _selectedIndex == 1,
      ),
      ClassWorkspacePage(
        key: const ValueKey('evaluations'),
        section: ClassWorkspaceSection.evaluations,
        isActive: _selectedIndex == 2,
        onOpenSchools: () => _onSelectTab(1),
        onOpenProfile: () => _onSelectTab(4),
      ),
      ClassWorkspacePage(
        key: const ValueKey('results'),
        section: ClassWorkspaceSection.results,
        isActive: _selectedIndex == 3,
        onOpenSchools: () => _onSelectTab(1),
        onOpenProfile: () => _onSelectTab(4),
      ),
      TeacherProfilePage(
        key: const ValueKey('profile'),
        isActive: _selectedIndex == 4,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onSelectTab,
        destinations: [
          for (final section in _sections)
            NavigationDestination(
              icon: Icon(section.icon),
              label: section.label,
            ),
        ],
      ),
    );
  }
}

class _NavigationSection {
  const _NavigationSection(this.label, this.icon);

  final String label;
  final IconData icon;
}
