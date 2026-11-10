import 'package:edu_note/app/app.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/injection_container.dart';
import 'package:edu_note/features/authentication/data/utils/password_hasher.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  setUpAll(() async {
    await configureDependencies(
      database: AppDatabase.forTesting(NativeDatabase.memory()),
    );
  });

  testWidgets(
    'onboarding flow appears on first run and leads to registration',
    (tester) async {
      await tester.pumpWidget(const EduNoteApp());
      await tester.pumpAndSettle();

      // Verify onboarding screen is shown
      expect(find.text('Établissements et Classes'), findsOneWidget);

      // Tap Suivant
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Évaluations et Notes'), findsOneWidget);

      // Tap Suivant
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('Résultats et Exports'), findsOneWidget);

      // Tap Commencer
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // Now should be on RegisterPage (Inscription)
      expect(find.text('Créer votre compte local'), findsOneWidget);
    },
  );

  testWidgets('main navigation opens each section when registered', (
    tester,
  ) async {
    // Seed onboarding as seen and teacher profile
    final db = getIt<AppDatabase>();
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'has_seen_onboarding',
            value: 'true',
          ),
        );
    final salt = PasswordHasher.generateSalt();
    await db
        .into(db.teachers)
        .insert(
          TeachersCompanion.insert(
            id: 'test-teacher-id',
            firstName: 'Jean',
            lastName: 'Dupont',
            profession: 'Professeur',
            whatsappNumber: '+22900000000',
            passwordHash: PasswordHasher.hashPassword(
              'password1',
              salt,
              iterations: 1000,
            ),
            passwordSalt: salt,
            passwordHashIterations: 1000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(const EduNoteApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'password1');
    await tester.tap(find.text('Déverrouiller'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur EduNote !'), findsOneWidget);

    await tester.tap(find.text('Établissements'));
    await tester.pumpAndSettle();
    expect(find.text('Gérez vos écoles et collèges'), findsOneWidget);
    expect(find.text('Aucun établissement enregistré'), findsOneWidget);

    await tester.tap(find.text('Évaluations'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Créez des interrogations et des devoirs pour saisir les notes.',
      ),
      findsOneWidget,
    );
  });
}
