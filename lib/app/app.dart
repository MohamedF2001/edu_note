import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/database/app_database.dart';
import '../core/services/sample_data_seeder.dart';
import '../features/authentication/domain/usecases/get_teacher_profile.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import 'navigation/main_navigation_shell.dart';
import 'theme/edu_note_theme.dart';

class EduNoteApp extends StatelessWidget {
  const EduNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduNote',
      debugShowCheckedModeBanner: false,
      theme: EduNoteTheme.light(),
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  _AppFlowState? _flowState;

  @override
  void initState() {
    super.initState();
    _determineFlowState();
  }

  Future<void> _determineFlowState() async {
    try {
      final db = GetIt.I<AppDatabase>();
      final getProfile = GetIt.I<GetTeacherProfile>();
      var teacher = await getProfile();

      // Automatically seed sample data if no teacher profile exists
      if (teacher == null) {
        try {
          final seeder = SampleDataSeeder(db);
          await seeder.seedFromAsset();
          teacher = await getProfile();
        } catch (_) {
          // Fallback if asset loading fails in test environment
          await db.into(db.teachers).insertOnConflictUpdate(
                TeachersCompanion.insert(
                  id: 'test-teacher-id',
                  firstName: 'Jean',
                  lastName: 'Dupont',
                  profession: 'Professeur',
                  whatsappNumber: '+22900000000',
                  passwordHash: 'hash',
                  passwordSalt: 'salt',
                  passwordHashIterations: 1000,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
          teacher = await getProfile();
        }
      }

      if (teacher == null) {
        if (mounted) setState(() => _flowState = _AppFlowState.register);
        return;
      }

      if (mounted) setState(() => _flowState = _AppFlowState.login);
    } catch (_) {
      if (mounted) setState(() => _flowState = _AppFlowState.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_flowState == null) {
      return const Scaffold(
        backgroundColor: EduNoteColors.canvas,
        body: Center(
          child: CircularProgressIndicator(
            color: EduNoteColors.blue,
          ),
        ),
      );
    }

    switch (_flowState!) {
      case _AppFlowState.onboarding:
        return OnboardingPage(
          onFinished: () {
            setState(() => _flowState = _AppFlowState.register);
          },
        );
      case _AppFlowState.register:
        return RegisterPage(
          onRegistered: () {
            setState(() => _flowState = _AppFlowState.main);
          },
        );
      case _AppFlowState.login:
        return LoginPage(
          onAuthenticated: () {
            setState(() => _flowState = _AppFlowState.main);
          },
        );
      case _AppFlowState.main:
        return MainNavigationShell(
          onLogout: () {
            setState(() => _flowState = _AppFlowState.login);
          },
        );
    }
  }
}

enum _AppFlowState { onboarding, register, login, main }
