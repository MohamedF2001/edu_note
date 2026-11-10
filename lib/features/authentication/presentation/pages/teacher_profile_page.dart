import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/usecases/get_teacher_profile.dart';
import '../../domain/usecases/set_teacher_subject.dart';
import '../../../subjects/domain/usecases/get_subject_by_id.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({
    super.key,
    required this.onLogout,
    this.isActive = false,
  });

  final VoidCallback onLogout;
  final bool isActive;

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  static const _standardSubjects = [
    'Mathématiques',
    'Français',
    'PCT',
    'SVT',
    'Anglais',
    'Histoire-Géographie',
  ];

  Teacher? _teacher;
  String? _subjectName;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant TeacherProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final teacher = await GetIt.I<GetTeacherProfile>()();
      String? subjectName;
      if (teacher?.subjectId != null) {
        final subject = await GetIt.I<GetSubjectById>()(teacher!.subjectId!);
        subjectName = subject?.name;
      }
      if (!mounted) return;
      setState(() {
        _teacher = teacher;
        _subjectName = subjectName;
        _isLoading = false;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger votre profil.';
        _isLoading = false;
        _isSaving = false;
      });
    }
  }

  Future<void> _changeSubject() async {
    final teacher = _teacher;
    if (teacher == null || !teacher.canChangeSubject) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _SubjectPickerDialog(
        currentSubject: _subjectName,
        standardSubjects: _standardSubjects,
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await GetIt.I<SetTeacherSubject>()(selected);
      await _loadProfile();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Bad state: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EduNoteColors.blue),
      );
    }
    final teacher = _teacher;
    if (teacher == null) {
      return const Center(child: Text('Profil enseignant introuvable.'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Profil enseignant',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: EduNoteColors.ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(teacher.fullName),
          subtitle: Text(teacher.profession),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Matière enseignée'),
          subtitle: Text(_subjectName ?? 'À définir'),
          trailing: IconButton(
            tooltip: teacher.canChangeSubject
                ? 'Modifier la matière'
                : 'Modification verrouillée après les évaluations',
            onPressed: teacher.canChangeSubject && !_isSaving
                ? _changeSubject
                : null,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined),
          ),
        ),
        if (!teacher.canChangeSubject)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              teacher.subjectId == null
                  ? 'Les évaluations historiques utilisent plusieurs matières. Une résolution explicite est requise avant de choisir la matière du profil.'
                  : 'La matière ne peut plus être modifiée après la création d’évaluations.',
              style: const TextStyle(color: EduNoteColors.muted),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Se déconnecter'),
          onTap: widget.onLogout,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: EduNoteColors.red),
          ),
        ],
      ],
    );
  }
}

class _SubjectPickerDialog extends StatefulWidget {
  const _SubjectPickerDialog({
    required this.currentSubject,
    required this.standardSubjects,
  });

  final String? currentSubject;
  final List<String> standardSubjects;

  @override
  State<_SubjectPickerDialog> createState() => _SubjectPickerDialogState();
}

class _SubjectPickerDialogState extends State<_SubjectPickerDialog> {
  late String _selected =
      widget.currentSubject != null &&
          widget.standardSubjects.contains(widget.currentSubject)
      ? widget.currentSubject!
      : 'Autre';
  late final TextEditingController _customController = TextEditingController(
    text: _selected == 'Autre' ? widget.currentSubject ?? '' : '',
  );

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = [...widget.standardSubjects, 'Autre'];
    return AlertDialog(
      title: const Text('Matière enseignée'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selected,
            items: options
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selected = value);
            },
          ),
          if (_selected == 'Autre') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                labelText: 'Précisez la matière',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final value = _selected == 'Autre'
                ? _customController.text.trim()
                : _selected;
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
