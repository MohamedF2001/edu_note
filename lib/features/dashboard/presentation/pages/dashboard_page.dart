import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/database/app_database.dart' hide Teacher;
import '../../../../core/widgets/edu_ui_components.dart';
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
      return const EduLottieState(
        lottieAsset: 'assets/lottie/loading.json',
        title: 'Chargement de votre espace...',
        message: 'Préparation de vos données scolaires sécurisées.',
        height: 120,
      );
    }

    final teacherName = _teacher != null
        ? '${_teacher!.firstName} ${_teacher!.lastName}'.trim()
        : '';

    return RefreshIndicator(
      color: EduNoteColors.accent,
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList.list(
              children: [
                _buildHeader(teacherName),
                const SizedBox(height: 24),
                if (_schoolsCount == 0) ...[
                  _buildEmptyState(),
                  const SizedBox(height: 20),
                  const _PrivacyNote(),
                ] else ...[
                  _buildKpiGrid(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 22),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    EduNoteColors.accentGradientStart,
                    EduNoteColors.accentGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: EduNoteShadows.primaryGlow,
              ),
              child: const EduColorIcon(name: 'graduation', size: 26),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EduNote',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: EduNoteColors.primaryDark,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  _teacher?.profession != null && _teacher!.profession.isNotEmpty
                      ? _teacher!.profession
                      : 'Espace Enseignant',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: EduNoteColors.accent,
                  ),
                ),
              ],
            ),
            const Spacer(),
            BounceableTap(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune nouvelle notification locale.'),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EduNoteColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EduNoteColors.cardBorder),
                  boxShadow: EduNoteShadows.soft,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 21,
                  color: EduNoteColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          teacherName.isNotEmpty ? 'Bonjour, $teacherName 👋' : 'Bonjour 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: EduNoteColors.primaryDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _schoolsCount == 0
              ? 'Votre espace de suivi scolaire est prêt.'
              : 'Voici le récapitulatif de votre activité pédagogique.',
          style: const TextStyle(
            color: EduNoteColors.textSecondary,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SoftCard(
      padding: const EdgeInsets.all(24),
      shadows: EduNoteShadows.floating,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduNoteColors.accentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const EduColorIcon(name: 'school', size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue sur EduNote !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: EduNoteColors.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ajoutez votre premier établissement scolaire pour commencer à organiser vos classes et suivre les résultats de vos élèves.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: EduNoteColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          BounceableTap(
            onTap: _addSchool,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    EduNoteColors.accentGradientStart,
                    EduNoteColors.accentGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: EduNoteShadows.primaryGlow,
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ajouter une école',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: EduNoteColors.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Établissements',
                count: '$_schoolsCount',
                iconName: 'school',
                accentColor: EduNoteColors.accent,
                onTap: () => widget.onSelectTab?.call(1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _KpiCard(
                title: 'Classes',
                count: '$_classesCount',
                iconName: 'book',
                accentColor: const Color(0xFF6366F1),
                onTap: () => widget.onSelectTab?.call(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Élèves suivis',
                count: '$_studentsCount',
                iconName: 'student',
                accentColor: EduNoteColors.emerald,
                onTap: () => widget.onSelectTab?.call(1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _KpiCard(
                title: 'Évaluations',
                count: '$_evaluationsCount',
                iconName: 'survey',
                accentColor: EduNoteColors.amber,
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: EduNoteColors.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            _ActionTile(
              label: 'Ajouter une école',
              iconName: 'school',
              onTap: _addSchool,
            ),
            _ActionTile(
              label: 'Gérer les classes',
              iconName: 'book',
              onTap: () => widget.onSelectTab?.call(1),
            ),
            _ActionTile(
              label: 'Évaluations',
              iconName: 'notes',
              onTap: () => widget.onSelectTab?.call(2),
            ),
            _ActionTile(
              label: 'Voir les résultats',
              iconName: 'chart',
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
    required this.iconName,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final String count;
  final String iconName;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EduColorIcon(name: iconName, size: 28),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            count,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: EduNoteColors.primaryDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              color: EduNoteColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.iconName,
    required this.onTap,
  });

  final String label;
  final String iconName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          EduColorIcon(name: iconName, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EduNoteColors.primaryDark,
              ),
            ),
          ),
        ],
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
        color: EduNoteColors.emeraldLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EduNoteColors.emerald.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EduColorIcon(name: 'protect', size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vos données restent sur cet appareil. EduNote fonctionne sans connexion Internet.',
              style: TextStyle(
                color: EduNoteColors.primaryDark,
                height: 1.4,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
