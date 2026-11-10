import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../academic_years/domain/entities/academic_period.dart';
import '../../../academic_years/domain/usecases/get_academic_periods.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/usecases/get_students_by_class.dart';
import '../../../students/presentation/pages/student_profile_page.dart';
import '../../../students/presentation/widgets/student_form_dialog.dart';
import '../../../authentication/domain/usecases/get_teacher_profile.dart';
import '../../../subjects/domain/entities/class_subject.dart';
import '../../../subjects/domain/repositories/subject_repository.dart';
import '../../../subjects/domain/usecases/get_subjects_by_class.dart';
import '../../domain/entities/school_class.dart';
import '../../domain/usecases/delete_class.dart';
import '../../domain/usecases/get_class_by_id.dart';
import '../widgets/class_form_dialog.dart';
import '../widgets/evaluations_tab.dart';
import '../widgets/results_tab.dart';
import '../widgets/subjects_tab.dart';

class ClassDetailPage extends StatefulWidget {
  const ClassDetailPage({super.key, required this.classId});

  final String classId;

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  SchoolClass? _schoolClass;
  List<ClassSubject> _classSubjects = [];
  List<Student> _students = [];
  String? _teacherSubjectName;
  List<AcademicPeriod> _periods = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getClass = GetIt.I<GetClassById>();
      final getStudents = GetIt.I<GetStudentsByClass>();
      final getTeacher = GetIt.I<GetTeacherProfile>();
      final getSubjectsByClass = GetIt.I<GetSubjectsByClass>();
      final getPeriods = GetIt.I<GetAcademicPeriods>();

      final schoolClass = await getClass(widget.classId);
      final students = await getStudents(widget.classId);

      final teacher = await getTeacher();
      final classSubjects = await getSubjectsByClass(widget.classId);
      final subject = teacher?.subjectId == null
          ? null
          : await GetIt.I<SubjectRepository>().getSubjectById(
              teacher!.subjectId!,
            );
      final periods = schoolClass != null
          ? await getPeriods(schoolClass.academicYearId)
          : <AcademicPeriod>[];

      if (mounted) {
        setState(() {
          _schoolClass = schoolClass;
          _students = students;
          _teacherSubjectName = subject?.name;
          _classSubjects = classSubjects;
          _periods = periods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les données de la classe.';
        });
      }
    }
  }

  Future<void> _editClass() async {
    if (_schoolClass == null) return;
    final updated = await ClassFormDialog.show(
      context,
      schoolId: _schoolClass!.schoolId,
      schoolClass: _schoolClass,
    );
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _addStudent() async {
    final created = await StudentFormDialog.show(
      context,
      classId: widget.classId,
    );
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete() async {
    if (_schoolClass == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: EduNoteColors.red),
            SizedBox(width: 10),
            Text('Supprimer la classe ?'),
          ],
        ),
        content: Text(
          'Supprimer la classe "${_schoolClass!.name}" supprimera également tous les élèves inscrits ainsi que leurs évaluations et leurs notes.\n\nCette action est irréversible.',
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
        final delete = GetIt.I<DeleteClass>();
        await delete(widget.classId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Classe supprimée avec succès.'),
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

    if (_schoolClass == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de la classe')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'Classe introuvable.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final c = _schoolClass!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier la classe',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editClass,
          ),
          IconButton(
            tooltip: 'Supprimer la classe',
            icon: const Icon(Icons.delete_outline, color: EduNoteColors.red),
            onPressed: _confirmDelete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: EduNoteColors.navy,
          unselectedLabelColor: EduNoteColors.muted,
          indicatorColor: EduNoteColors.blue,
          tabs: [
            Tab(text: 'Élèves (${_students.length})'),
            const Tab(text: 'Matière'),
            const Tab(text: 'Évaluations'),
            const Tab(text: 'Résultats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          SubjectsTab(subjectName: _teacherSubjectName),
          EvaluationsTab(
            classId: widget.classId,
            schoolId: c.schoolId,
            classSubjects: _classSubjects,
            periods: _periods,
          ),
          ResultsTab(classId: widget.classId, classSubjects: _classSubjects),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    final filtered = _students.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          (s.registrationNumber?.toLowerCase().contains(q) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Effectif',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: EduNoteColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: EduNoteColors.paleBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_students.length} élève${_students.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: EduNoteColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _addStudent,
                style: FilledButton.styleFrom(
                  backgroundColor: EduNoteColors.navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Inscrire'),
              ),
            ],
          ),
          if (_students.isNotEmpty) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _studentSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Rechercher un élève, matricule...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _studentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _studentSearchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_students.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7EDF1)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 44,
                    color: EduNoteColors.muted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucun élève inscrit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: EduNoteColors.ink,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Inscrivez vos élèves pour enregistrer leurs notes et suivre leurs moyennes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: EduNoteColors.muted),
                  ),
                ],
              ),
            )
          else if (filtered.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun élève ne correspond à votre recherche.',
                  style: TextStyle(color: EduNoteColors.muted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final student = filtered[index];
                final initials =
                    (student.lastName.isNotEmpty ? student.lastName[0] : '') +
                    (student.firstName.isNotEmpty ? student.firstName[0] : '');

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7EDF1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: student.gender == 'F'
                          ? const Color(0xFFFDE8F1)
                          : EduNoteColors.paleBlue,
                      child: Text(
                        initials.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: student.gender == 'F'
                              ? const Color(0xFFD63384)
                              : EduNoteColors.blue,
                        ),
                      ),
                    ),
                    title: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: EduNoteColors.ink,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        if (student.orderNumber != null) ...[
                          Text(
                            'N° ${student.orderNumber} • ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EduNoteColors.muted,
                            ),
                          ),
                        ],
                        Text(
                          student.registrationNumber ?? 'Sans matricule',
                          style: const TextStyle(
                            fontSize: 12,
                            color: EduNoteColors.muted,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: EduNoteColors.muted,
                    ),
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentProfilePage(studentId: student.id),
                        ),
                      );
                      if (changed == true) {
                        _loadData();
                      }
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
