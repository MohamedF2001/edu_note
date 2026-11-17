import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/edu_ui_components.dart';

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.iconName,
    required this.accentColor,
    required this.tag,
  });

  final String title;
  final String description;
  final String iconName;
  final Color accentColor;
  final String tag;
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Établissements et Classes',
      description:
          'Organisez vos établissements scolaires, vos années académiques et vos classes en toute simplicité pour un suivi rigoureux.',
      iconName: 'school',
      accentColor: EduNoteColors.accent,
      tag: 'ESPACES INDÉPENDANTS',
    ),
    OnboardingItem(
      title: 'Évaluations et Notes',
      description:
          'Créez des interrogations et devoirs, saisissez vos notes en lot et gérez les statuts d’absence en toute fluidité.',
      iconName: 'notes',
      accentColor: EduNoteColors.emerald,
      tag: 'CALCUL AUTOMATIQUE',
    ),
    OnboardingItem(
      title: 'Résultats et Exports',
      description:
          'Bénéficiez de calculs de moyennes automatiques et exportez vos relevés en PDF ou XLSX, 100% hors-ligne et sécurisé.',
      iconName: 'trophy',
      accentColor: EduNoteColors.amber,
      tag: '100% CONFIDENTIEL & OFFLINE',
    ),
  ];

  Future<void> _completeOnboarding() async {
    try {
      final db = GetIt.I<AppDatabase>();
      await db.into(db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: 'has_seen_onboarding',
              value: 'true',
            ),
          );
    } catch (_) {
      // Fallback if db insertion fails or during testing
    }
    widget.onFinished();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduNoteColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with branding and Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              EduNoteColors.accentGradientStart,
                              EduNoteColors.accentGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: EduNoteShadows.primaryGlow,
                        ),
                        child: const EduColorIcon(name: 'graduation', size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'EduNote',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: EduNoteColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _items.length - 1)
                    BounceableTap(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: EduNoteColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: EduNoteColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            color: EduNoteColors.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                ],
              ),
            ),

            // Lottie Animation banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 180,
                alignment: Alignment.center,
                child: Lottie.asset(
                  'assets/lottie/onboarding.json',
                  height: 180,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: EduNoteColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 60,
                      color: EduNoteColors.accent,
                    ),
                  ),
                ),
              ),
            ),

            // PageView content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tag pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: item.accentColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.tag,
                            style: TextStyle(
                              color: item.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: EduNoteColors.primaryDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: EduNoteColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom indicators and action button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? EduNoteColors.accent
                              : EduNoteColors.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  BounceableTap(
                    onTap: () {
                      if (_currentPage < _items.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            EduNoteColors.accentGradientStart,
                            EduNoteColors.accentGradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: EduNoteShadows.primaryGlow,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _items.length - 1
                                ? 'Suivant'
                                : 'Commencer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage < _items.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_rounded,
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
          ],
        ),
      ),
    );
  }
}
