import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/database/app_database.dart' hide Student;
import '../../domain/entities/student.dart';
import '../../domain/usecases/delete_student.dart';
import '../../domain/usecases/get_student_by_id.dart';
import '../widgets/student_form_dialog.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Student? _student;
  List<(Evaluation, Grade, String)> _evaluationGrades = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = GetIt.I<AppDatabase>();
      final getStudent = GetIt.I<GetStudentById>();
      final s = await getStudent(widget.studentId);

      final query = db.select(db.grades).join([
        innerJoin(
          db.evaluations,
          db.evaluations.id.equalsExp(db.grades.evaluationId),
        ),
        innerJoin(
          db.classSubjects,
          db.classSubjects.id.equalsExp(db.evaluations.classSubjectId),
        ),
        innerJoin(
          db.subjects,
          db.subjects.id.equalsExp(db.classSubjects.subjectId),
        ),
      ])
        ..where(db.grades.studentId.equals(widget.studentId))
        ..orderBy([OrderingTerm.desc(db.evaluations.evaluationDate)]);

      final rows = await query.get();
      final evalGrades = rows.map((row) {
        final eval = row.readTable(db.evaluations);
        final grade = row.readTable(db.grades);
        final subject = row.readTable(db.subjects);
        return (eval, grade, subject.name);
      }).toList();

      if (mounted) {
        setState(() {
          _student = s;
          _evaluationGrades = evalGrades;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger le profil de l\'élève.';
        });
      }
    }
  }

  Future<void> _editStudent() async {
    if (_student == null) return;
    final updated = await StudentFormDialog.show(
      context,
      classId: _student!.classId,
      student: _student,
    );
    if (updated == true) {
      _loadStudent();
    }
  }

  Future<void> _confirmDelete() async {
    if (_student == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: EduNoteColors.red),
            SizedBox(width: 10),
            Text('Supprimer l\'élève ?'),
          ],
        ),
        content: Text(
          'Voulez-vous supprimer définitivement "${_student!.fullName}" ainsi que toutes ses notes enregistrées ?\n\nCette action est irréversible.',
          style: const TextStyle(height: 1.4),
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

    if (confirmed == true && mounted) {
      try {
        final delete = GetIt.I<DeleteStudent>();
        await delete(widget.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Élève supprimé avec succès.'),
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
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: EduNoteColors.blue),
        ),
      );
    }

    if (_student == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil de l\'élève')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'Élève introuvable.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadStudent,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final s = _student!;
    final initials = (s.lastName.isNotEmpty ? s.lastName[0] : '') +
        (s.firstName.isNotEmpty ? s.firstName[0] : '');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil élève',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editStudent,
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: EduNoteColors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7EDF1)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: s.gender == 'F'
                      ? const Color(0xFFFDE8F1)
                      : EduNoteColors.paleBlue,
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: s.gender == 'F'
                          ? const Color(0xFFD63384)
                          : EduNoteColors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  s.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: EduNoteColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.registrationNumber != null &&
                          s.registrationNumber!.isNotEmpty
                      ? 'Matricule : ${s.registrationNumber}'
                      : 'Aucun matricule',
                  style: const TextStyle(
                    fontSize: 13,
                    color: EduNoteColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.orderNumber != null) ...[
                      _Badge(
                        label: 'N° ${s.orderNumber}',
                        color: EduNoteColors.navy,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _Badge(
                      label: s.gender == 'F' ? 'Féminin' : 'Masculin',
                      color: s.gender == 'F'
                          ? const Color(0xFFD63384)
                          : EduNoteColors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7EDF1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EduNoteColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Date de naissance',
                  value: s.dateOfBirth != null
                      ? '${s.dateOfBirth!.day.toString().padLeft(2, '0')}/${s.dateOfBirth!.month.toString().padLeft(2, '0')}/${s.dateOfBirth!.year}'
                      : 'Non renseignée',
                  icon: Icons.cake_outlined,
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Matricule officiel',
                  value: s.registrationNumber ?? 'Non attribué',
                  icon: Icons.badge_outlined,
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Numéro d\'ordre dans la classe',
                  value: s.orderNumber != null
                      ? '${s.orderNumber}'
                      : 'Non renseigné',
                  icon: Icons.format_list_numbered_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7EDF1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: EduNoteColors.accent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Historique des évaluations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: EduNoteColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_evaluationGrades.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Aucune note enregistrée pour cet élève.',
                        style: TextStyle(
                            fontSize: 13, color: EduNoteColors.muted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _evaluationGrades.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final (eval, grade, subjectName) =
                          _evaluationGrades[index];
                      final scoreText = grade.status == 'absent'
                          ? 'Absent(e)'
                          : grade.score != null
                              ? '${grade.score!.toStringAsFixed(2)} / ${eval.maxScore.toStringAsFixed(0)}'
                              : 'Non noté';
                      final color = grade.status == 'absent'
                          ? EduNoteColors.crimson
                          : grade.score != null
                              ? (grade.score! >= 10
                                  ? EduNoteColors.emerald
                                  : EduNoteColors.crimson)
                              : EduNoteColors.muted;

                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eval.title ?? 'Évaluation',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: EduNoteColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$subjectName • ${eval.evaluationDate.day.toString().padLeft(2, '0')}/${eval.evaluationDate.month.toString().padLeft(2, '0')}/${eval.evaluationDate.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: EduNoteColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              scoreText,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: EduNoteColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: EduNoteColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: EduNoteColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
