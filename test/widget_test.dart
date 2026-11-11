import 'dart:io';
import 'package:edu_note/app/app.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/core/services/sample_data_seeder.dart';
import 'package:edu_note/injection_container.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await configureDependencies(database: db);
    final file = File('sample_data.txt');
    if (file.existsSync()) {
      final json = await file.readAsString();
      await SampleDataSeeder(db).seedFromJson(json);
    }
  });

  testWidgets(
    'app automatically seeds sample data on first run and shows login',
    (tester) async {
      await tester.pumpWidget(const EduNoteApp());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Déverrouiller'), findsOneWidget);

      await tester.tap(find.text('Déverrouiller'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Moussa Kérékou'), findsOneWidget);
    },
  );

  testWidgets('main navigation opens each section with seeded data', (
    tester,
  ) async {
    await tester.pumpWidget(const EduNoteApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    if (find.text('Déverrouiller').evaluate().isNotEmpty) {
      await tester.tap(find.text('Déverrouiller'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.textContaining('Moussa Kérékou'), findsOneWidget);

    await tester.tap(find.text('Établissements'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Gérez vos écoles et collèges'), findsOneWidget);
    expect(find.text('Lycée Béhanzin'), findsOneWidget);
  });
}
