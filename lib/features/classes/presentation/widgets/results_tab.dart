import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../evaluations/domain/entities/evaluation.dart';
import '../../../evaluations/domain/entities/grade.dart';
import '../../../evaluations/domain/usecases/get_evaluations_by_class_subject.dart';
import '../../../evaluations/domain/usecases/get_grades_by_evaluation.dart';
import '../../../results/domain/entities/result_input.dart';
import '../../../results/domain/entities/student_subject_result.dart';
import '../../../results/domain/usecases/calculate_student_subject_result.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/usecases/get_students_by_class.dart';
import '../../../subjects/domain/entities/class_subject.dart';

class ResultsTab extends StatefulWidget {
  const ResultsTab({
    super.key,
    required this.classId,
    required this.classSubjects,
  });

  final String classId;
  final List<ClassSubject> classSubjects;

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  ClassSubject? _selectedSubject;
  List<Student> _students = [];
  Map<String, StudentSubjectResult> _results = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasEvaluations = false;

  @override
  void initState() {
    super.initState();
    if (widget.classSubjects.isNotEmpty) {
      _selectedSubject = widget.classSubjects.first;
    }
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (_selectedSubject == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getStudents = GetIt.I<GetStudentsByClass>();
      final getEvals = GetIt.I<GetEvaluationsByClassSubject>();
      final getGrades = GetIt.I<GetGradesByEvaluation>();
      const calculator = CalculateStudentSubjectResult();

      final students = await getStudents(widget.classId);
      final evaluations = await getEvals(_selectedSubject!.id);

      // Build a map: studentId -> grades per evaluation
      final Map<String, List<(Evaluation, Grade?)>> studentGradeMap = {};
      for (final s in students) {
        studentGradeMap[s.id] = [];
      }

      for (final eval in evaluations) {
        final grades = await getGrades(eval.id);
        final gradeByStudent = {for (final g in grades) g.studentId: g};
        for (final s in students) {
          studentGradeMap[s.id]!.add((eval, gradeByStudent[s.id]));
        }
      }

      // Compute results per student
      final Map<String, StudentSubjectResult> results = {};
      for (final s in students) {
        final inputs = <ResultInput>[];
        for (final (eval, grade) in studentGradeMap[s.id]!) {
          ResultInputStatus status;
          if (grade == null) {
            status = ResultInputStatus.notRecorded;
          } else if (grade.status == GradeStatus.absent) {
            status = ResultInputStatus.absent;
          } else if (grade.status == GradeStatus.recorded &&
              grade.score != null) {
            status = ResultInputStatus.recorded;
          } else {
            status = ResultInputStatus.notRecorded;
          }

          EvaluationKind kind;
          switch (eval.type) {
            case EvaluationType.interrogation:
              kind = EvaluationKind.interrogation;
            case EvaluationType.homework1:
              kind = EvaluationKind.homework1;
            case EvaluationType.homework2:
              kind = EvaluationKind.homework2;
          }

          inputs.add(
            ResultInput(
              kind: kind,
              status: status,
              maxScore: eval.maxScore,
              score: grade?.score,
            ),
          );
        }
        try {
          results[s.id] = calculator(inputs);
        } catch (_) {
          results[s.id] = const StudentSubjectResult(
            interrogationMean: null,
            homework1: null,
            homework2: null,
            finalMean: null,
          );
        }
      }

      if (mounted) {
        setState(() {
          _students = students;
          _results = results;
          _hasEvaluations = evaluations.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de calculer les résultats.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.classSubjects.isEmpty)
          _emptyCard(
            Icons.bar_chart_rounded,
            'Aucune matière associée',
            'Associez des matières à cette classe pour voir les résultats.',
          )
        else ...[
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
                      _loadResults();
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
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: EduNoteColors.blue),
            )
          else if (_errorMessage != null)
            _emptyCard(
              Icons.cloud_off_outlined,
              _errorMessage!,
              'Réessayez en actualisant la page.',
            )
          else if (_students.isEmpty)
            _emptyCard(
              Icons.people_outline_rounded,
              'Aucun élève',
              'Inscrivez des élèves pour calculer les résultats.',
            )
          else ...[
            if (!_hasEvaluations) ...[
              _emptyCard(
                Icons.assignment_outlined,
                'Aucune évaluation enregistrée',
                'Les moyennes apparaîtront ici après la création des évaluations et la saisie des notes.',
              ),
              const SizedBox(height: 16),
            ],
            // Summary row
            _SummaryRow(students: _students, results: _results),
            const SizedBox(height: 16),
            // Results list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7EDF1)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: EduNoteColors.navy.withValues(alpha: 0.04),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Élève',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: EduNoteColors.muted,
                            ),
                          ),
                        ),
                        _HeaderCell('Moy. Interros'),
                        _HeaderCell('Devoir 1'),
                        _HeaderCell('Devoir 2'),
                        _HeaderCell('Moy. Finale'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _students.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (_, i) {
                      final student = _students[i];
                      final result = _results[student.id];
                      final initials =
                          (student.lastName.isNotEmpty
                              ? student.lastName[0]
                              : '') +
                          (student.firstName.isNotEmpty
                              ? student.firstName[0]
                              : '');
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: student.gender == 'F'
                                        ? const Color(0xFFFDE8F1)
                                        : EduNoteColors.paleBlue,
                                    child: Text(
                                      initials.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: student.gender == 'F'
                                            ? const Color(0xFFD63384)
                                            : EduNoteColors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      student.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _ScoreCell(result?.interrogationMean),
                            _ScoreCell(result?.homework1),
                            _ScoreCell(result?.homework2),
                            _ScoreCell(result?.finalMean, isFinal: true),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.students, required this.results});

  final List<Student> students;
  final Map<String, StudentSubjectResult> results;

  @override
  Widget build(BuildContext context) {
    final completed = results.values.where((r) => r.isComplete).length;
    final completedResults = results.values
        .where((r) => r.isComplete)
        .map((r) => r.finalMean!)
        .toList();
    final avg = completedResults.isEmpty
        ? null
        : completedResults.reduce((a, b) => a + b) / completedResults.length;

    final above10 = completedResults.where((m) => m >= 10).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Notes complètes',
            value: '$completed/${students.length}',
            icon: Icons.check_circle_outline,
            color: EduNoteColors.navy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Moyenne classe',
            value: avg != null ? avg.toStringAsFixed(2) : '—',
            icon: Icons.calculate_outlined,
            color: avg != null
                ? (avg >= 10 ? const Color(0xFF10B981) : EduNoteColors.red)
                : EduNoteColors.muted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Admis (≥10)',
            value: completedResults.isEmpty ? '—' : '$above10',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: EduNoteColors.muted),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: EduNoteColors.muted,
        ),
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell(this.value, {this.isFinal = false});

  final double? value;
  final bool isFinal;

  Color get _color {
    if (value == null) return EduNoteColors.muted;
    if (value! >= 16) return const Color(0xFF10B981);
    if (value! >= 10) return EduNoteColors.navy;
    return EduNoteColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final text = value != null ? value!.toStringAsFixed(2) : '—';
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: isFinal
            ? const EdgeInsets.symmetric(vertical: 4, horizontal: 6)
            : EdgeInsets.zero,
        decoration: isFinal && value != null
            ? BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isFinal ? FontWeight.w800 : FontWeight.w600,
            fontSize: isFinal ? 13 : 12,
            color: _color,
          ),
        ),
      ),
    );
  }
}
