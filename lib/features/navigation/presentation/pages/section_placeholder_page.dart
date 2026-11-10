import 'package:flutter/material.dart';

import '../../../../app/theme/edu_note_theme.dart';

class SectionPlaceholderPage extends StatelessWidget {
  const SectionPlaceholderPage({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: EduNoteColors.blue),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: EduNoteColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: EduNoteColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
