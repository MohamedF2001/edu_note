import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/widgets/edu_ui_components.dart';
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

  void _showCelebrationDialog(double classAvg, int totalAdmis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/celebration.json',
              height: 140,
              repeat: false,
            ),
            const SizedBox(height: 12),
            const Text(
              'Félicitations pour la période ! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: EduNoteColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Moyenne de classe : ${classAvg.toStringAsFixed(2)}/20\n$totalAdmis élève(s) avec la moyenne.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EduNoteColors.textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedResults = _results.values
        .where((r) => r.isComplete)
        .map((r) => r.finalMean!)
        .toList();
    final avg = completedResults.isEmpty
        ? null
        : completedResults.reduce((a, b) => a + b) / completedResults.length;
    final above10 = completedResults.where((m) => m >= 10).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        if (widget.classSubjects.isEmpty)
          _emptyCard(
            'book',
            'Aucune matière associée',
            'Associez votre matière à cette classe pour voir les résultats.',
          )
        else ...[
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (avg != null && avg >= 10)
                BounceableTap(
                  onTap: () => _showCelebrationDialog(avg, above10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: EduNoteColors.amberLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EduNoteColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        EduColorIcon(name: 'trophy', size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Célébrer',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: EduNoteColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

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
              'Réessayez en actualisant la page.',
            )
          else if (_students.isEmpty)
            _emptyCard(
              'student',
              'Aucun élève inscrit',
              'Inscrivez des élèves pour calculer les résultats.',
            )
          else ...[
            if (!_hasEvaluations) ...[
              _emptyCard(
                'notes',
                'Aucune évaluation enregistrée',
                'Les moyennes apparaîtront ici après la création des évaluations et la saisie des notes.',
              ),
              const SizedBox(height: 16),
            ],

            // Summary cards
            _SummaryRow(
              students: _students,
              results: _results,
              avg: avg,
              above10: above10,
            ),
            const SizedBox(height: 18),

            // Results Table Card
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: EduNoteColors.accentLight.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ÉLÈVE',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              color: EduNoteColors.primaryDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        _HeaderCell('MOY. INT'),
                        _HeaderCell('DEV. 1'),
                        _HeaderCell('DEV. 2'),
                        _HeaderCell('MOY. FINALE'),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: EduNoteColors.cardBorder),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _students.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 16,
                      color: EduNoteColors.cardBorder,
                    ),
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
                          vertical: 11,
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
                                        : EduNoteColors.accentLight,
                                    child: Text(
                                      initials.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: student.gender == 'F'
                                            ? const Color(0xFFD63384)
                                            : EduNoteColors.accent,
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
                                        color: EduNoteColors.primaryDark,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.students,
    required this.results,
    required this.avg,
    required this.above10,
  });

  final List<Student> students;
  final Map<String, StudentSubjectResult> results;
  final double? avg;
  final int above10;

  @override
  Widget build(BuildContext context) {
    final completed = results.values.where((r) => r.isComplete).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Notes complètes',
            value: '$completed/${students.length}',
            iconName: 'survey',
            color: EduNoteColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Moyenne classe',
            value: avg != null ? '${avg!.toStringAsFixed(2)}/20' : '—',
            iconName: 'calculator',
            color: avg != null
                ? (avg! >= 10 ? EduNoteColors.emerald : EduNoteColors.crimson)
                : EduNoteColors.muted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Admis (≥10)',
            value: avg != null ? '$above10' : '—',
            iconName: 'trophy',
            color: EduNoteColors.amber,
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
    required this.iconName,
    required this.color,
  });

  final String label;
  final String value;
  final String iconName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EduColorIcon(name: iconName, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: EduNoteColors.muted,
            ),
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
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: EduNoteColors.muted,
          letterSpacing: 0.2,
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
    if (value! >= 16) return EduNoteColors.emerald;
    if (value! >= 10) return EduNoteColors.accent;
    return EduNoteColors.crimson;
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
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
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
