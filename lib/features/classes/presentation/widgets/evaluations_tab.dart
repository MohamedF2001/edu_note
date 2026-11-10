import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../evaluations/domain/entities/evaluation.dart';
import '../../../evaluations/domain/usecases/create_evaluation.dart';
import '../../../evaluations/domain/usecases/delete_evaluation.dart';
import '../../../evaluations/domain/usecases/get_evaluations_by_class_subject.dart';
import '../../../evaluations/domain/usecases/get_grades_by_evaluation.dart';
import '../../../evaluations/domain/usecases/save_grades_batch.dart';
import '../../../evaluations/domain/entities/grade.dart';
import '../../../academic_years/domain/entities/academic_period.dart';
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
            backgroundColor: EduNoteColors.red,
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
            style: FilledButton.styleFrom(backgroundColor: EduNoteColors.red),
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
      padding: const EdgeInsets.all(20),
      children: [
        // Subject selector
        if (widget.classSubjects.isEmpty)
          _emptyCard(
            Icons.menu_book_outlined,
            'Aucune matière associée',
            'Associez d\'abord des matières à cette classe dans l\'onglet "Matières".',
          )
        else ...[
          // Subject chip selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.classSubjects.map((cs) {
                final selected = _selectedSubject?.id == cs.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cs.subjectName),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedSubject = cs);
                      _loadData();
                    },
                    selectedColor: EduNoteColors.paleBlue,
                    checkmarkColor: EduNoteColors.navy,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? EduNoteColors.navy
                          : EduNoteColors.muted,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Period selector
          if (widget.periods.isNotEmpty)
            DropdownButtonFormField<AcademicPeriod>(
              initialValue: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Période',
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
          // Action buttons
          if (widget.periods.isEmpty)
            _emptyCard(
              Icons.calendar_month_outlined,
              'Aucune période scolaire',
              'Ajoutez une période à l’année scolaire de cette classe avant de créer une évaluation.',
            ),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.quiz_outlined,
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
                  icon: Icons.assignment_outlined,
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
                  icon: Icons.assignment_outlined,
                  label: 'Devoir 2',
                  color: const Color(0xFFEC4899),
                  onTap: _selectedPeriod == null
                      ? null
                      : () => _createEvaluation(EvaluationType.homework2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: EduNoteColors.blue),
            )
          else if (_errorMessage != null)
            _emptyCard(
              Icons.cloud_off_outlined,
              _errorMessage!,
              'Actualisez pour réessayer.',
            )
          else if (_evaluations.isEmpty)
            _emptyCard(
              Icons.assignment_outlined,
              'Aucune évaluation',
              'Créez une interrogation ou un devoir pour commencer à saisir des notes.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _evaluations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final eval = _evaluations[i];
                return _EvaluationCard(
                  evaluation: eval,
                  studentCount: _students.length,
                  onTap: () => _openGradeEntry(eval),
                  onDelete: () => _deleteEvaluation(eval),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _emptyCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: EduNoteColors.muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: EduNoteColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: EduNoteColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Material(
      color: color.withValues(alpha: isEnabled ? 0.08 : 0.04),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                color: isEnabled ? color : EduNoteColors.muted,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? color : EduNoteColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.assignment_outlined, color: _typeColor, size: 20),
        ),
        title: Text(
          evaluation.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          '/${evaluation.maxScore.toStringAsFixed(evaluation.maxScore == evaluation.maxScore.truncate() ? 0 : 1)}  •  $studentCount élève${studentCount > 1 ? "s" : ""}',
          style: const TextStyle(fontSize: 12, color: EduNoteColors.muted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: EduNoteColors.red,
                size: 20,
              ),
              onPressed: onDelete,
            ),
            FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Notes', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
          ],
        ),
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
                  backgroundColor: EduNoteColors.red,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes enregistrées avec succès.'),
            backgroundColor: EduNoteColors.navy,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: EduNoteColors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evaluation.displayTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EduNoteColors.blue),
            )
          : widget.students.isEmpty
          ? const Center(
              child: Text(
                'Aucun élève dans cette classe.',
                style: TextStyle(color: EduNoteColors.muted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: widget.students.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final student = widget.students[i];
                final status = _statuses[student.id] ?? GradeStatus.notRecorded;
                final isAbsent = status == GradeStatus.absent;
                final initials =
                    (student.lastName.isNotEmpty ? student.lastName[0] : '') +
                    (student.firstName.isNotEmpty ? student.firstName[0] : '');

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAbsent
                          ? EduNoteColors.red.withValues(alpha: 0.3)
                          : const Color(0xFFE7EDF1),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: student.gender == 'F'
                            ? const Color(0xFFFDE8F1)
                            : EduNoteColors.paleBlue,
                        child: Text(
                          initials.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: student.gender == 'F'
                                ? const Color(0xFFD63384)
                                : EduNoteColors.blue,
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
                                fontSize: 14,
                              ),
                            ),
                            if (student.registrationNumber != null)
                              Text(
                                student.registrationNumber!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: EduNoteColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status toggles
                      _StatusToggle(
                        label: 'AB',
                        active: isAbsent,
                        activeColor: EduNoteColors.red,
                        onTap: () => setState(() {
                          _statuses[student.id] = isAbsent
                              ? GradeStatus.notRecorded
                              : GradeStatus.absent;
                          _controllers[student.id]!.clear();
                        }),
                      ),
                      const SizedBox(width: 8),
                      // Score input
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _controllers[student.id],
                          enabled: !isAbsent,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: isAbsent ? 'Abs.' : '–',
                            isDense: true,
                            filled: true,
                            fillColor: isAbsent
                                ? EduNoteColors.red.withValues(alpha: 0.05)
                                : EduNoteColors.paleBlue.withValues(alpha: 0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            suffix: Text(
                              '/${widget.evaluation.maxScore.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : EduNoteColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
