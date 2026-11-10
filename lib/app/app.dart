import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/database/app_database.dart';
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
  late Future<_AppFlowState> _flowFuture;
  bool _sessionUnlocked = false;

  @override
  void initState() {
    super.initState();
    _flowFuture = _determineFlowState();
  }

  Future<_AppFlowState> _determineFlowState() async {
    try {
      final db = GetIt.I<AppDatabase>();
      final setting = await (db.select(
        db.appSettings,
      )..where((t) => t.key.equals('has_seen_onboarding'))).getSingleOrNull();
      final hasSeenOnboarding = setting?.value == 'true';
      if (!hasSeenOnboarding) {
        return _AppFlowState.onboarding;
      }

      final getProfile = GetIt.I<GetTeacherProfile>();
      final teacher = await getProfile();
      if (teacher == null) {
        return _AppFlowState.register;
      }

      return _sessionUnlocked ? _AppFlowState.main : _AppFlowState.login;
    } catch (_) {
      return _AppFlowState.onboarding;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppFlowState>(
      future: _flowFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: EduNoteColors.canvas,
            body: Center(
              child: CircularProgressIndicator(color: EduNoteColors.blue),
            ),
          );
        }
        final state = snapshot.data ?? _AppFlowState.onboarding;
        switch (state) {
          case _AppFlowState.onboarding:
            return OnboardingPage(
              onFinished: () {
                setState(() {
                  _flowFuture = _determineFlowState();
                });
              },
            );
          case _AppFlowState.register:
            return RegisterPage(
              onRegistered: () {
                setState(() {
                  _sessionUnlocked = true;
                  _flowFuture = _determineFlowState();
                });
              },
            );
          case _AppFlowState.login:
            return LoginPage(
              onAuthenticated: () {
                setState(() {
                  _sessionUnlocked = true;
                  _flowFuture = _determineFlowState();
                });
              },
            );
          case _AppFlowState.main:
            return MainNavigationShell(
              onLogout: () {
                setState(() {
                  _sessionUnlocked = false;
                  _flowFuture = _determineFlowState();
                });
              },
            );
        }
      },
    );
  }
}

enum _AppFlowState { onboarding, register, login, main }
