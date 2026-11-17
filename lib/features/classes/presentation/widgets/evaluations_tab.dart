import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/widgets/edu_ui_components.dart';
import '../../../academic_years/domain/entities/academic_period.dart';
import '../../../evaluations/domain/entities/evaluation.dart';
import '../../../evaluations/domain/entities/grade.dart';
import '../../../evaluations/domain/usecases/create_evaluation.dart';
import '../../../evaluations/domain/usecases/delete_evaluation.dart';
import '../../../evaluations/domain/usecases/get_evaluations_by_class_subject.dart';
import '../../../evaluations/domain/usecases/get_grades_by_evaluation.dart';
import '../../../evaluations/domain/usecases/save_grades_batch.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/usecases/get_students_by_class.dart';
import '../../../subjects/domain/entities/class_subject.dart';

class EvaluationsTab extends StatefulWidget {
  const EvaluationsTab({
    super.key,
    required this.classId,
    required this.schoolId,
    required this.classSubjects,
    required this.periods,
  });

  final String classId;
  final String schoolId;
  final List<ClassSubject> classSubjects;
  final List<AcademicPeriod> periods;

  @override
  State<EvaluationsTab> createState() => _EvaluationsTabState();
}

class _EvaluationsTabState extends State<EvaluationsTab> {
  ClassSubject? _selectedSubject;
  AcademicPeriod? _selectedPeriod;
  List<Evaluation> _evaluations = [];
  List<Student> _students = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.classSubjects.isNotEmpty) {
      _selectedSubject = widget.classSubjects.first;
    }
    if (widget.periods.isNotEmpty) {
      _selectedPeriod = widget.periods.first;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedSubject == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final getEvals = GetIt.I<GetEvaluationsByClassSubject>();
      final getStudents = GetIt.I<GetStudentsByClass>();
      final evals = await getEvals(_selectedSubject!.id);
      final students = await getStudents(widget.classId);
      if (mounted) {
        setState(() {
          _evaluations = evals;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les évaluations.';
        });
      }
    }
  }

  Future<void> _createEvaluation(EvaluationType type) async {
    if (_selectedSubject == null || _selectedPeriod == null) return;
    try {
      final create = GetIt.I<CreateEvaluation>();
      await create(
        classSubjectId: _selectedSubject!.id,
        academicPeriodId: _selectedPeriod!.id,
        type: type,
        evaluationDate: DateTime.now(),
        maxScore: 20,
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: EduNoteColors.crimson,
          ),
        );
      }
    }
  }

  Future<void> _openGradeEntry(Evaluation evaluation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GradeEntryPage(
          schoolId: widget.schoolId,
          evaluation: evaluation,
          students: _students,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _deleteEvaluation(Evaluation eval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer cette évaluation ?'),
        content: Text(
          'Toutes les notes de "${eval.displayTitle}" seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduNoteColors.crimson),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final delete = GetIt.I<DeleteEvaluation>();
      await delete(eval.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        if (widget.classSubjects.isEmpty)
          _emptyCard(
            'book',
            'Aucune matière associée',
            'Associez d\'abord des matières à cette classe dans l\'onglet "Matière".',
          )
        else ...[
          // Subject pill indicator (Unique subject)
          Row(
            children: widget.classSubjects.map((cs) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: EduNoteColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EduNoteColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const EduColorIcon(name: 'award', size: 18),
                    const SizedBox(width: 8),
                    Text(
                      cs.subjectName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: EduNoteColors.accent,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Period selector
          if (widget.periods.isNotEmpty)
            DropdownButtonFormField<AcademicPeriod>(
              initialValue: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Période scolaire',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                isDense: true,
              ),
              items: widget.periods.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (p) {
                if (p != null) {
                  setState(() => _selectedPeriod = p);
                }
              },
            ),
          const SizedBox(height: 16),

          // Action buttons for evaluations
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  iconName: 'notes',
                  label: 'Interro.',
                  color: const Color(0xFF3B82F6),
                  onTap: _selectedPeriod == null
                      ? null
                      : () => _createEvaluation(EvaluationType.interrogation),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  iconName: 'survey',
                  label: 'Devoir 1',
                  color: const Color(0xFF8B5CF6),
                  onTap: _selectedPeriod == null
                      ? null
                      : () => _createEvaluation(EvaluationType.homework1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  iconName: 'survey',
                  label: 'Devoir 2',
                  color: const Color(0xFFEC4899),
                  onTap: _selectedPeriod == null
                      ? null
                      : () => _createEvaluation(EvaluationType.homework2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28.0),
                child: CircularProgressIndicator(color: EduNoteColors.accent),
              ),
            )
          else if (_errorMessage != null)
            _emptyCard(
              'empty_box',
              _errorMessage!,
              'Actualisez pour réessayer.',
            )
          else if (_evaluations.isEmpty)
            _emptyCard(
              'notes',
              'Aucune évaluation créée',
              'Créez une interrogation ou un devoir ci-dessus pour commencer à saisir vos notes.',
            )
          else
            StaggeredFadeSlideList(
              children: [
                for (final eval in _evaluations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EvaluationCard(
                      evaluation: eval,
                      studentCount: _students.length,
                      onTap: () => _openGradeEntry(eval),
                      onDelete: () => _deleteEvaluation(eval),
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _emptyCard(String iconName, String title, String subtitle) {
    return SoftCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduNoteColors.accentLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: EduColorIcon(name: iconName, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: EduNoteColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: EduNoteColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconName,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String iconName;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return BounceableTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isEnabled ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isEnabled ? 0.25 : 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            EduColorIcon(name: iconName, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : EduNoteColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({
    required this.evaluation,
    required this.studentCount,
    required this.onTap,
    required this.onDelete,
  });

  final Evaluation evaluation;
  final int studentCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color get _typeColor {
    switch (evaluation.type) {
      case EvaluationType.interrogation:
        return const Color(0xFF3B82F6);
      case EvaluationType.homework1:
        return const Color(0xFF8B5CF6);
      case EvaluationType.homework2:
        return const Color(0xFFEC4899);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: EduColorIcon(name: 'survey', size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evaluation.displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: EduNoteColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/${evaluation.maxScore.toStringAsFixed(evaluation.maxScore == evaluation.maxScore.truncate() ? 0 : 1)}  •  $studentCount élève${studentCount > 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: EduNoteColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: EduNoteColors.crimson,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
              BounceableTap(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: EduNoteColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: EduNoteColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Grade Entry Page
// ─────────────────────────────────────────────────────────

class GradeEntryPage extends StatefulWidget {
  const GradeEntryPage({
    super.key,
    required this.evaluation,
    required this.schoolId,
    required this.students,
  });

  final Evaluation evaluation;
  final String schoolId;
  final List<Student> students;

  @override
  State<GradeEntryPage> createState() => _GradeEntryPageState();
}

class _GradeEntryPageState extends State<GradeEntryPage> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, GradeStatus> _statuses;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _statuses = {};
    for (final s in widget.students) {
      _controllers[s.id] = TextEditingController();
      _statuses[s.id] = GradeStatus.notRecorded;
    }
    _loadExistingGrades();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingGrades() async {
    try {
      final getGrades = GetIt.I<GetGradesByEvaluation>();
      final grades = await getGrades(widget.evaluation.id);
      for (final g in grades) {
        if (_controllers.containsKey(g.studentId)) {
          _statuses[g.studentId] = g.status;
          if (g.score != null) {
            final s = g.score!;
            _controllers[g.studentId]!.text = s == s.truncateToDouble()
                ? s.toInt().toString()
                : s.toStringAsFixed(2);
          }
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final grades = <Grade>[];
      final now = DateTime.now();
      for (final student in widget.students) {
        final status = _statuses[student.id] ?? GradeStatus.notRecorded;
        double? score;
        if (status == GradeStatus.recorded) {
          final text = _controllers[student.id]!.text.trim();
          score = double.tryParse(text.replaceAll(',', '.'));
          if (score != null &&
              (score < 0 || score > widget.evaluation.maxScore)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Note invalide pour ${student.fullName} : doit être entre 0 et ${widget.evaluation.maxScore}.',
                  ),
                  backgroundColor: EduNoteColors.crimson,
                ),
              );
            }
            setState(() => _isSaving = false);
            return;
          }
        }
        grades.add(
          Grade(
            id: '',
            evaluationId: widget.evaluation.id,
            studentId: student.id,
            status: status,
            score: status == GradeStatus.recorded ? score : null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final saveBatch = GetIt.I<SaveGradesBatch>();
      await saveBatch(schoolId: widget.schoolId, grades: grades);

      if (mounted) {
        // Show success dialog with Lottie animation
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/success.json',
                  height: 120,
                  repeat: false,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notes enregistrées !',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: EduNoteColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Les moyennes ont été automatiquement recalculées.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EduNoteColors.muted,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: EduNoteColors.crimson,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduNoteColors.background,
      appBar: AppBar(
        title: Text(
          widget.evaluation.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: BounceableTap(
              onTap: _isSaving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      EduNoteColors.accentGradientStart,
                      EduNoteColors.accentGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: EduNoteShadows.primaryGlow,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        children: [
                          Icon(Icons.save_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Enregistrer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EduNoteColors.accent),
            )
          : widget.students.isEmpty
          ? const Center(
              child: Text(
                'Aucun élève dans cette classe.',
                style: TextStyle(color: EduNoteColors.muted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: widget.students.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final student = widget.students[i];
                final status = _statuses[student.id] ?? GradeStatus.notRecorded;
                final isAbsent = status == GradeStatus.absent;
                final initials =
                    (student.lastName.isNotEmpty ? student.lastName[0] : '') +
                    (student.firstName.isNotEmpty ? student.firstName[0] : '');

                return SoftCard(
                  padding: const EdgeInsets.all(14),
                  borderColor: isAbsent
                      ? EduNoteColors.crimson.withValues(alpha: 0.3)
                      : EduNoteColors.cardBorder,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: student.gender == 'F'
                            ? const Color(0xFFFDE8F1)
                            : EduNoteColors.accentLight,
                        child: Text(
                          initials.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: student.gender == 'F'
                                ? const Color(0xFFD63384)
                                : EduNoteColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: EduNoteColors.primaryDark,
                              ),
                            ),
                            if (student.registrationNumber != null)
                              Text(
                                student.registrationNumber!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: EduNoteColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status toggles
                      _StatusToggle(
                        label: 'ABS',
                        active: isAbsent,
                        activeColor: EduNoteColors.crimson,
                        onTap: () => setState(() {
                          _statuses[student.id] = isAbsent
                              ? GradeStatus.notRecorded
                              : GradeStatus.absent;
                          _controllers[student.id]!.clear();
                        }),
                      ),
                      const SizedBox(width: 10),
                      // Score input
                      SizedBox(
                        width: 76,
                        child: TextField(
                          controller: _controllers[student.id],
                          enabled: !isAbsent,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: EduNoteColors.primaryDark,
                          ),
                          decoration: InputDecoration(
                            hintText: isAbsent ? 'Abs.' : '–',
                            isDense: true,
                            filled: true,
                            fillColor: isAbsent
                                ? EduNoteColors.crimson.withValues(alpha: 0.06)
                                : EduNoteColors.accentLight.withValues(alpha: 0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: EduNoteColors.cardBorder,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            suffix: Text(
                              '/${widget.evaluation.maxScore.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: EduNoteColors.muted,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              setState(
                                () => _statuses[student.id] =
                                    GradeStatus.recorded,
                              );
                            } else {
                              setState(
                                () => _statuses[student.id] =
                                    GradeStatus.notRecorded,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BounceableTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeColor : EduNoteColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : EduNoteColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}
