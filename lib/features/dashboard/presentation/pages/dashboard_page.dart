import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/database/app_database.dart' hide Teacher;
import '../../../authentication/domain/entities/teacher.dart';
import '../../../authentication/domain/usecases/get_teacher_profile.dart';
import '../../../schools/presentation/widgets/school_form_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Teacher? _teacher;
  int _schoolsCount = 0;
  int _classesCount = 0;
  int _studentsCount = 0;
  int _evaluationsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final getProfile = GetIt.I<GetTeacherProfile>();
      final teacher = await getProfile();

      final db = GetIt.I<AppDatabase>();
      final schools = await db.select(db.schools).get();
      final classes = await db.select(db.schoolClasses).get();
      final students = await db.select(db.students).get();
      final evaluations = await db.select(db.evaluations).get();

      if (mounted) {
        setState(() {
          _teacher = teacher;
          _schoolsCount = schools.length;
          _classesCount = classes.length;
          _studentsCount = students.length;
          _evaluationsCount = evaluations.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSchool() async {
    final created = await SchoolFormDialog.show(context);
    if (created == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EduNoteColors.blue),
      );
    }

    final teacherName = _teacher != null
        ? '${_teacher!.firstName} ${_teacher!.lastName}'.trim()
        : '';

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverList.list(
              children: [
                _buildHeader(teacherName),
                const SizedBox(height: 28),
                if (_schoolsCount == 0) ...[
                  _buildEmptyState(),
                  const SizedBox(height: 20),
                  const _PrivacyNote(),
                ] else ...[
                  _buildKpiGrid(),
                  const SizedBox(height: 28),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  const _PrivacyNote(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String teacherName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: EduNoteColors.paleBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: EduNoteColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EduNote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: EduNoteColors.navy,
                  ),
                ),
                Text(
                  'Gestion scolaire, simplement',
                  style: TextStyle(
                    fontSize: 12,
                    color: EduNoteColors.muted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune nouvelle notification locale.'),
                  ),
                );
              },
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          teacherName.isNotEmpty ? 'Bonjour, $teacherName 👋' : 'Bonjour 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: EduNoteColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _schoolsCount == 0
              ? 'Votre espace de suivi scolaire est prêt.'
              : 'Voici le récapitulatif de votre activité.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: EduNoteColors.muted),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: EduNoteColors.paleBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 30,
              color: EduNoteColors.blue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bienvenue sur EduNote !',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: EduNoteColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ajoutez votre premier établissement scolaire pour commencer à organiser vos classes et suivre les résultats de vos élèves.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: EduNoteColors.muted,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addSchool,
              style: FilledButton.styleFrom(
                backgroundColor: EduNoteColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une école'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EduNoteColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Écoles',
                count: '$_schoolsCount',
                icon: Icons.apartment_rounded,
                color: EduNoteColors.blue,
                onTap: () => widget.onSelectTab?.call(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Classes',
                count: '$_classesCount',
                icon: Icons.class_outlined,
                color: const Color(0xFF6C5CE7),
                onTap: () => widget.onSelectTab?.call(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Élèves',
                count: '$_studentsCount',
                icon: Icons.people_outline_rounded,
                color: EduNoteColors.green,
                onTap: () => widget.onSelectTab?.call(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Évaluations',
                count: '$_evaluationsCount',
                icon: Icons.assignment_outlined,
                color: const Color(0xFFE17055),
                onTap: () => widget.onSelectTab?.call(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EduNoteColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _ActionTile(
              label: 'Ajouter une école',
              icon: Icons.apartment_rounded,
              onTap: _addSchool,
            ),
            _ActionTile(
              label: 'Gérer les classes',
              icon: Icons.class_outlined,
              onTap: () => widget.onSelectTab?.call(1),
            ),
            _ActionTile(
              label: 'Évaluations',
              icon: Icons.assignment_add,
              onTap: () => widget.onSelectTab?.call(2),
            ),
            _ActionTile(
              label: 'Voir les résultats',
              icon: Icons.bar_chart_rounded,
              onTap: () => widget.onSelectTab?.call(3),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: EduNoteColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: EduNoteColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: EduNoteColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: EduNoteColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: EduNoteColors.green),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vos données restent sur cet appareil. EduNote fonctionne sans connexion Internet.',
              style: TextStyle(
                color: EduNoteColors.ink,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
