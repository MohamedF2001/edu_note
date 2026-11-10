import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
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
            Icon(Icons.warning_amber_rounded, color: EduNoteColors.red),
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
            style: FilledButton.styleFrom(backgroundColor: EduNoteColors.red),
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
              backgroundColor: EduNoteColors.navy,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression : $e'),
              backgroundColor: EduNoteColors.red,
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
        body: Center(
          child: CircularProgressIndicator(color: EduNoteColors.blue),
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
      appBar: AppBar(
        title: Text(
          school.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editSchool,
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: EduNoteColors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7EDF1)),
              ),
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
                          color: EduNoteColors.paleBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          school.type,
                          style: const TextStyle(
                            color: EduNoteColors.blue,
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
                        color: EduNoteColors.ink,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: EduNoteColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EduNoteColors.paleBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_classes.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: EduNoteColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _addClass,
                  style: FilledButton.styleFrom(
                    backgroundColor: EduNoteColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_classes.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7EDF1)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 40,
                      color: EduNoteColors.muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Aucune classe enregistrée',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: EduNoteColors.ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ajoutez votre première classe pour commencer à organiser les élèves et leurs notes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: EduNoteColors.muted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _classes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final schoolClass = _classes[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7EDF1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: EduNoteColors.paleBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.class_outlined,
                          color: EduNoteColors.blue,
                        ),
                      ),
                      title: Text(
                        schoolClass.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: EduNoteColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        'Niveau : ${schoolClass.level}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: EduNoteColors.muted,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: EduNoteColors.muted,
                      ),
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
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
