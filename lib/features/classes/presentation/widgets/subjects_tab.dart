import 'package:flutter/material.dart';

import '../../../../app/theme/edu_note_theme.dart';

class SubjectsTab extends StatelessWidget {
  const SubjectsTab({super.key, required this.subjectName});

  final String? subjectName;

  @override
  Widget build(BuildContext context) {
    final name = subjectName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 44,
              color: EduNoteColors.navy,
            ),
            const SizedBox(height: 12),
            Text(
              name ?? 'Matière à définir',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: EduNoteColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name == null
                  ? 'Complétez la matière de votre profil avant de créer de nouvelles évaluations.'
                  : 'Cette matière s’applique à toutes vos classes et à tous vos établissements.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: EduNoteColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
