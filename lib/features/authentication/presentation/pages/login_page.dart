import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/database/app_database.dart' hide Teacher;
import '../../../../core/widgets/edu_ui_components.dart';
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
      backgroundColor: EduNoteColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: StaggeredFadeSlideList(
                children: [
                  // App Icon Badge
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: EduNoteColors.cardBorder, width: 1.5),
                        boxShadow: EduNoteShadows.floating,
                      ),
                      child: const EduColorIcon(name: 'teacher', size: 52),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Greeting Title
                  Text(
                    _teacher != null
                        ? 'Bonjour, ${_teacher!.firstName} 👋'
                        : 'Bon retour !',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: EduNoteColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entrez votre mot de passe pour accéder à votre espace EduNote.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EduNoteColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card container for form
                  SoftCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EduNoteColors.crimsonLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EduNoteColors.crimson.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: EduNoteColors.crimson,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: EduNoteColors.crimson,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
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
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: EduNoteColors.muted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: EduNoteColors.muted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        BounceableTap(
                          onTap: _isLoading ? null : _unlock,
                          child: Container(
                            height: 52,
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
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Déverrouiller',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.lock_open_rounded,
                                        size: 19,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EduColorIcon(name: 'protect', size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Données chiffrées & 100% hors-ligne',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: EduNoteColors.muted,
                            ),
                          ),
                        ),
                      ],
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
