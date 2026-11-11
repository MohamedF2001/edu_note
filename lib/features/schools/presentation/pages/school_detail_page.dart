import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../../core/widgets/edu_ui_components.dart';
import '../../../classes/domain/entities/school_class.dart';
import '../../../classes/domain/usecases/get_classes_by_school.dart';
import '../../../classes/presentation/pages/class_detail_page.dart';
import '../../../classes/presentation/widgets/class_form_dialog.dart';
import '../../domain/entities/school.dart';
import '../../domain/usecases/delete_school.dart';
import '../../domain/usecases/get_school_by_id.dart';
import '../widgets/school_form_dialog.dart';

class SchoolDetailPage extends StatefulWidget {
  const SchoolDetailPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  State<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends State<SchoolDetailPage> {
  School? _school;
  List<SchoolClass> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getSchool = GetIt.I<GetSchoolById>();
      final getClasses = GetIt.I<GetClassesBySchool>();

      final school = await getSchool(widget.schoolId);
      final classes = await getClasses(widget.schoolId);

      if (mounted) {
        setState(() {
          _school = school;
          _classes = classes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger l\'établissement.';
        });
      }
    }
  }

  Future<void> _editSchool() async {
    if (_school == null) return;
    final updated = await SchoolFormDialog.show(context, school: _school);
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _addClass() async {
    final created = await ClassFormDialog.show(
      context,
      schoolId: widget.schoolId,
    );
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: EduNoteColors.crimson),
            SizedBox(width: 10),
            Text('Supprimer l\'école ?'),
          ],
        ),
        content: const Text(
          'Cette action supprimera définitivement cet établissement ainsi que toutes les classes, élèves, évaluations et notes qui y sont rattachés.\n\nÊtes-vous sûr de vouloir continuer ?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduNoteColors.crimson),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final delete = GetIt.I<DeleteSchool>();
        await delete(widget.schoolId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Établissement supprimé avec succès.'),
              backgroundColor: EduNoteColors.primaryDark,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression : $e'),
              backgroundColor: EduNoteColors.crimson,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: EduNoteColors.background,
        body: EduLottieState(
          lottieAsset: 'assets/lottie/loading.json',
          title: 'Chargement de l\'établissement...',
          message: 'Récupération des classes associées.',
          height: 120,
        ),
      );
    }

    if (_school == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de l\'école')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'Établissement introuvable.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final school = _school!;

    return Scaffold(
      backgroundColor: EduNoteColors.background,
      appBar: AppBar(
        title: Text(
          school.name,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, color: EduNoteColors.muted),
            onPressed: _editSchool,
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: EduNoteColors.crimson),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: EduNoteColors.accent,
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // School Summary Card
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: EduNoteColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          school.type,
                          style: const TextStyle(
                            color: EduNoteColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: EduNoteColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        school.city,
                        style: const TextStyle(
                          color: EduNoteColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (school.address != null && school.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      school.address!,
                      style: const TextStyle(
                        color: EduNoteColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Header for Classes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Classes',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: EduNoteColors.primaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: EduNoteColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_classes.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: EduNoteColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                BounceableTap(
                  onTap: _addClass,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
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
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Ajouter',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_classes.isEmpty)
              SoftCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EduNoteColors.accentLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const EduColorIcon(name: 'book', size: 34),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Aucune classe enregistrée',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: EduNoteColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ajoutez votre première classe pour commencer à organiser les élèves et leurs notes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: EduNoteColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              )
            else
              StaggeredFadeSlideList(
                children: [
                  for (final schoolClass in _classes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ClassDetailPage(
                                classId: schoolClass.id,
                              ),
                            ),
                          );
                          if (changed == true) {
                            _loadData();
                          }
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: EduNoteColors.accentLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const EduColorIcon(name: 'book', size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    schoolClass.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.5,
                                      color: EduNoteColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Niveau : ${schoolClass.level}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: EduNoteColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: EduNoteColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
