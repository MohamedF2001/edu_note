import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../academic_years/domain/entities/academic_period.dart';
import '../../../academic_years/domain/usecases/get_academic_periods.dart';
import '../../../classes/domain/entities/school_class.dart';
import '../../../classes/domain/usecases/get_all_classes.dart';
import '../../../classes/presentation/widgets/evaluations_tab.dart';
import '../../../classes/presentation/widgets/results_tab.dart';
import '../../../schools/domain/entities/school.dart';
import '../../../schools/domain/usecases/get_schools.dart';
import '../../../subjects/domain/entities/class_subject.dart';
import '../../../subjects/domain/usecases/get_subjects_by_class.dart';

enum ClassWorkspaceSection { evaluations, results }

class ClassWorkspacePage extends StatefulWidget {
  const ClassWorkspacePage({
    super.key,
    required this.section,
    required this.isActive,
    required this.onOpenSchools,
    required this.onOpenProfile,
  });

  final ClassWorkspaceSection section;
  final bool isActive;
  final VoidCallback onOpenSchools;
  final VoidCallback onOpenProfile;

  @override
  State<ClassWorkspacePage> createState() => _ClassWorkspacePageState();
}

class _ClassWorkspacePageState extends State<ClassWorkspacePage> {
  List<SchoolClass> _classes = [];
  Map<String, School> _schoolsById = {};
  SchoolClass? _selectedClass;
  List<ClassSubject> _subjects = [];
  List<AcademicPeriod> _periods = [];
  bool _isLoading = true;
  bool _isLoadingSelection = false;
  String? _errorMessage;
  int _selectionRequest = 0;

  bool get _isEvaluations =>
      widget.section == ClassWorkspaceSection.evaluations;

  String get _title => _isEvaluations ? 'Évaluations' : 'Résultats';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void didUpdateWidget(covariant ClassWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await Future.wait([
        GetIt.I<GetAllClasses>()(),
        GetIt.I<GetSchools>()(),
      ]);
      final classes = data[0] as List<SchoolClass>;
      final schools = data[1] as List<School>;
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _schoolsById = {for (final school in schools) school.id: school};
        _selectedClass = classes.isEmpty
            ? null
            : classes.firstWhere(
                (item) => item.id == _selectedClass?.id,
                orElse: () => classes.first,
              );
        _isLoading = false;
      });
      if (_selectedClass != null) await _loadSelection(_selectedClass!);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger vos classes.';
        });
      }
    }
  }

  Future<void> _loadSelection(SchoolClass schoolClass) async {
    final request = ++_selectionRequest;
    setState(() {
      _selectedClass = schoolClass;
      _isLoadingSelection = true;
      _errorMessage = null;
      _subjects = [];
      _periods = [];
    });
    try {
      final subjects = await GetIt.I<GetSubjectsByClass>()(schoolClass.id);
      final periods = await GetIt.I<GetAcademicPeriods>()(schoolClass.academicYearId);
      if (!mounted || request != _selectionRequest) return;
      setState(() {
        _subjects = subjects;
        _periods = periods;
        _isLoadingSelection = false;
      });
    } catch (_) {
      if (mounted && request == _selectionRequest) {
        setState(() {
          _isLoadingSelection = false;
          _errorMessage = 'Impossible de charger les données de cette classe.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadClasses,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EduNoteColors.blue),
            )
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadClasses)
          : _classes.isEmpty
          ? _EmptyState(
              icon: Icons.class_outlined,
              title: 'Aucune classe pour le moment',
              message:
                  'Créez un établissement et une classe pour gérer vos évaluations et consulter les résultats.',
              actionLabel: 'Ouvrir les établissements',
              onAction: widget.onOpenSchools,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEvaluations
                            ? 'Choisissez une classe pour créer des évaluations et saisir les notes.'
                            : 'Consultez les moyennes calculées à partir des notes enregistrées.',
                        style: const TextStyle(
                          color: EduNoteColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<SchoolClass>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Classe',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        items: _classes.map((schoolClass) {
                          final school = _schoolsById[schoolClass.schoolId];
                          final details = [
                            if (school != null) school.name,
                            if (schoolClass.level.isNotEmpty)
                              schoolClass.level,
                          ].join(' · ');
                          return DropdownMenuItem(
                            value: schoolClass,
                            child: Text(
                              details.isEmpty
                                  ? schoolClass.name
                                  : '${schoolClass.name} · $details',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (schoolClass) {
                          if (schoolClass != null) _loadSelection(schoolClass);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildSelectedContent()),
              ],
            ),
    );
  }

  Widget _buildSelectedContent() {
    if (_isLoadingSelection) {
      return const Center(
        child: CircularProgressIndicator(color: EduNoteColors.blue),
      );
    }
    if (_subjects.isEmpty) {
      return _EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Aucune matière associée à cette classe',
        message:
            'Définissez votre matière dans le profil enseignant pour pouvoir créer des évaluations et calculer les résultats.',
        actionLabel: 'Ouvrir le profil',
        onAction: widget.onOpenProfile,
      );
    }
    final selectedClass = _selectedClass!;
    if (_isEvaluations) {
      if (_periods.isEmpty) {
        return _EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'Aucune période scolaire disponible',
          message:
              'Ajoutez une période à l’année scolaire de cette classe avant de créer une évaluation.',
          actionLabel: 'Ouvrir les établissements',
          onAction: widget.onOpenSchools,
        );
      }
      return EvaluationsTab(
        key: ValueKey('evaluations-${selectedClass.id}'),
        classId: selectedClass.id,
        schoolId: selectedClass.schoolId,
        classSubjects: _subjects,
        periods: _periods,
      );
    }
    return ResultsTab(
      key: ValueKey('results-${selectedClass.id}'),
      classId: selectedClass.id,
      classSubjects: _subjects,
      periods: _periods,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: EduNoteColors.paleBlue,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 36, color: EduNoteColors.blue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: EduNoteColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EduNoteColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 44,
            color: EduNoteColors.muted,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
