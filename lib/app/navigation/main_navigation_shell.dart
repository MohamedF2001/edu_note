import 'package:flutter/material.dart';

import '../../app/theme/edu_note_theme.dart';
import '../../core/widgets/edu_ui_components.dart';
import '../../features/authentication/presentation/pages/teacher_profile_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
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
    _NavigationSection('Accueil', Icons.home_rounded, 'calendar'),
    _NavigationSection('Établissements', Icons.apartment_rounded, 'school'),
    _NavigationSection('Évaluations', Icons.assignment_rounded, 'notes'),
    _NavigationSection('Résultats', Icons.bar_chart_rounded, 'chart'),
    _NavigationSection('Profil', Icons.person_rounded, 'teacher'),
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: IndexedStack(
            key: ValueKey<int>(_selectedIndex),
            index: _selectedIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: EduNoteColors.cardBorder, width: 1),
          ),
          boxShadow: EduNoteShadows.soft,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < _sections.length; i++)
                  _buildNavItem(i, _sections[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavigationSection section) {
    final isSelected = _selectedIndex == index;
    return BounceableTap(
      onTap: () => _onSelectTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? EduNoteColors.accentLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                section.icon,
                size: 22,
                color: isSelected ? EduNoteColors.accent : EduNoteColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              section.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? EduNoteColors.accent : EduNoteColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationSection {
  const _NavigationSection(this.label, this.icon, this.iconName);

  final String label;
  final IconData icon;
  final String iconName;
}
