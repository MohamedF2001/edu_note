import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/widgets/edu_ui_components.dart';
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
      return const Scaffold(
        backgroundColor: EduNoteColors.background,
        body: EduLottieState(
          lottieAsset: 'assets/lottie/loading.json',
          title: 'Chargement de votre profil...',
          message: 'Récupération de vos paramètres locaux.',
          height: 120,
        ),
      );
    }
    final teacher = _teacher;
    if (teacher == null) {
      return const Center(child: Text('Profil enseignant introuvable.'));
    }

    return Scaffold(
      backgroundColor: EduNoteColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // Header
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
                  child: const EduColorIcon(name: 'teacher', size: 26),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil enseignant',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: EduNoteColors.primaryDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Paramètres & Espace personnel',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: EduNoteColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Identity Card
            SoftCard(
              padding: const EdgeInsets.all(20),
              shadows: EduNoteShadows.soft,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: EduNoteColors.accentLight,
                    child: Text(
                      (teacher.lastName.isNotEmpty ? teacher.lastName[0] : '') +
                          (teacher.firstName.isNotEmpty ? teacher.firstName[0] : ''),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: EduNoteColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: EduNoteColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          teacher.profession,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: EduNoteColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: EduNoteColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              teacher.whatsappNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                color: EduNoteColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Unique Teaching Subject Card (Crucial V1 feature)
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EduNoteColors.amberLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const EduColorIcon(name: 'award', size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Matière enseignée unique',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: EduNoteColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subjectName ?? 'À définir',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: EduNoteColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (teacher.canChangeSubject)
                        BounceableTap(
                          onTap: _isSaving ? null : _changeSubject,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: EduNoteColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: EduNoteColors.accent,
                                    ),
                                  )
                                : const Text(
                                    'Modifier',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: EduNoteColors.accent,
                                    ),
                                  ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: EduNoteColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_rounded, size: 14, color: EduNoteColors.muted),
                              SizedBox(width: 4),
                              Text(
                                'Verrouillée',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: EduNoteColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (!teacher.canChangeSubject) ...[
                    const SizedBox(height: 12),
                    Text(
                      teacher.subjectId == null
                          ? 'Les évaluations historiques utilisent plusieurs matières. Une résolution explicite est requise avant de choisir la matière du profil.'
                          : 'Conformément aux règles métier V1, la matière ne peut plus être modifiée une fois les premières évaluations créées.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: EduNoteColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Security & Privacy Card
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EduNoteColors.emeraldLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const EduColorIcon(name: 'protect', size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sécurité & Confidentialité',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: EduNoteColors.primaryDark,
                              ),
                            ),
                            Text(
                              'Données 100% hors-ligne et chiffrées sur cet appareil',
                              style: TextStyle(
                                fontSize: 12,
                                color: EduNoteColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            BounceableTap(
              onTap: widget.onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: EduNoteColors.crimsonLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: EduNoteColors.crimson.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: EduNoteColors.crimson,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: EduNoteColors.crimson,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EduNoteColors.crimsonLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EduNoteColors.crimson,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          EduColorIcon(name: 'award', size: 24),
          SizedBox(width: 10),
          Text('Matière enseignée'),
        ],
      ),
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
