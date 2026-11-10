import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../domain/usecases/register_teacher.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onRegistered});

  final VoidCallback onRegistered;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _whatsappController = TextEditingController(text: '+229 ');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _customProfessionController = TextEditingController();
  final _customSubjectController = TextEditingController();

  String _selectedProfession = 'Professeur de Collège / Lycée';
  String _selectedSubject = 'Mathématiques';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _professions = [
    'Professeur de Collège / Lycée',
    'Professeur des Écoles / Instituteur',
    'Professeur de Mathématiques',
    'Professeur de Français',
    'Professeur de Physique-Chimie',
    'Professeur d’Histoire-Géographie',
    'Autre',
  ];

  final List<String> _subjects = [
    'Mathématiques',
    'Français',
    'PCT',
    'SVT',
    'Anglais',
    'Histoire-Géographie',
    'Autre',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customProfessionController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profession = _selectedProfession == 'Autre'
          ? _customProfessionController.text.trim()
          : _selectedProfession;
      final subjectName = _selectedSubject == 'Autre'
          ? _customSubjectController.text.trim()
          : _selectedSubject;

      if (profession.isEmpty) {
        setState(() {
          _errorMessage = 'Veuillez spécifier votre profession';
          _isLoading = false;
        });
        return;
      }
      if (subjectName.isEmpty) {
        setState(() {
          _errorMessage = 'Veuillez préciser la matière enseignée';
          _isLoading = false;
        });
        return;
      }

      final registerTeacher = GetIt.I<RegisterTeacher>();
      await registerTeacher(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        profession: profession,
        subjectName: subjectName,
        whatsappNumber: _whatsappController.text.trim(),
        password: _passwordController.text,
      );

      widget.onRegistered();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l’inscription : $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduNoteColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: EduNoteColors.paleBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: EduNoteColors.navy,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EduNote',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: EduNoteColors.navy,
                              ),
                            ),
                            Text(
                              'Espace Enseignant',
                              style: TextStyle(
                                fontSize: 13,
                                color: EduNoteColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Créer votre compte local',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: EduNoteColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vos informations restent strictement confidentielles et stockées localement sur cet appareil.',
                      style: TextStyle(
                        fontSize: 14,
                        color: EduNoteColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Champ requis'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Champ requis'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedProfession,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Profession',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                      items: _professions
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedProfession = val);
                        }
                      },
                    ),

                    if (_selectedProfession == 'Autre') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customProfessionController,
                        decoration: const InputDecoration(
                          labelText: 'Précisez votre profession',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        validator: (v) {
                          if (_selectedProfession == 'Autre' &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Veuillez préciser votre profession';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Matière enseignée',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: _subjects
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSubject = value);
                        }
                      },
                    ),
                    if (_selectedSubject == 'Autre') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customSubjectController,
                        decoration: const InputDecoration(
                          labelText: 'Précisez la matière',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        validator: (value) =>
                            _selectedSubject == 'Autre' &&
                                (value == null || value.trim().isEmpty)
                            ? 'Veuillez préciser la matière enseignée'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Numéro WhatsApp',
                        prefixIcon: Icon(Icons.phone_outlined),
                        helperText: 'Par défaut +229 (Bénin)',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe sécurisé',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
                            !RegExp(r'\d').hasMatch(v)) {
                          return 'Ajoutez au moins une lettre et un chiffre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: EduNoteColors.navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Créer mon compte',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
