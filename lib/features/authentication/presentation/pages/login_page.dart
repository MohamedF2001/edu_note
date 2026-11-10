import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/database/app_database.dart' hide Teacher;
import '../../domain/entities/teacher.dart';
import '../../domain/usecases/authenticate_teacher.dart';
import '../../domain/usecases/get_teacher_profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  Teacher? _teacher;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    try {
      final getProfile = GetIt.I<GetTeacherProfile>();
      final teacher = await getProfile();
      if (mounted) {
        setState(() => _teacher = teacher);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final database = GetIt.I<AppDatabase>();
      final lockout =
          await (database.select(database.appSettings)
                ..where((row) => row.key.equals('login_lockout_until')))
              .getSingleOrNull();
      final lockoutTime = lockout == null
          ? null
          : DateTime.tryParse(lockout.value);
      if (lockoutTime != null && lockoutTime.isAfter(DateTime.now())) {
        setState(() {
          _errorMessage = 'Trop de tentatives. Réessayez plus tard.';
          _isLoading = false;
        });
        return;
      }

      final authenticate = GetIt.I<AuthenticateTeacher>();
      final success = await authenticate(_passwordController.text);
      if (success) {
        await (database.delete(database.appSettings)..where(
              (row) => row.key.isIn([
                'login_failed_attempts',
                'login_lockout_until',
              ]),
            ))
            .go();
        widget.onAuthenticated();
      } else {
        final attemptsSetting =
            await (database.select(database.appSettings)
                  ..where((row) => row.key.equals('login_failed_attempts')))
                .getSingleOrNull();
        final attempts = int.tryParse(attemptsSetting?.value ?? '') ?? 0;
        final nextAttempts = attempts + 1;
        await database
            .into(database.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: 'login_failed_attempts',
                value: nextAttempts.toString(),
              ),
            );
        if (nextAttempts >= 5) {
          final lockoutMinutes = (nextAttempts - 4).clamp(1, 30);
          final until = DateTime.now().add(Duration(minutes: lockoutMinutes));
          await database
              .into(database.appSettings)
              .insertOnConflictUpdate(
                AppSettingsCompanion.insert(
                  key: 'login_lockout_until',
                  value: until.toIso8601String(),
                ),
              );
        }
        setState(() {
          _errorMessage = nextAttempts >= 5
              ? 'Trop de tentatives. Réessayez dans quelques minutes.'
              : 'Mot de passe incorrect';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: EduNoteColors.paleBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 36,
                        color: EduNoteColors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _teacher != null
                        ? 'Bonjour, ${_teacher!.firstName} 👋'
                        : 'Bon retour !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: EduNoteColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entrez votre mot de passe pour accéder à votre espace EduNote.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EduNoteColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onSubmitted: (_) => _unlock(),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
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
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: EduNoteColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _unlock,
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
                              'Déverrouiller',
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
    );
  }
}
