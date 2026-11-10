import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../domain/entities/school.dart';
import '../../domain/usecases/delete_school.dart';
import '../../domain/usecases/get_schools.dart';
import '../widgets/school_form_dialog.dart';
import 'school_detail_page.dart';

class SchoolsPage extends StatefulWidget {
  const SchoolsPage({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends State<SchoolsPage> {
  final _searchController = TextEditingController();
  List<School> _allSchools = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void didUpdateWidget(covariant SchoolsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadSchools();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getSchools = GetIt.I<GetSchools>();
      final schools = await getSchools();
      if (mounted) {
        setState(() {
          _allSchools = schools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les établissements.';
        });
      }
    }
  }

  Future<void> _createSchool() async {
    final created = await SchoolFormDialog.show(context);
    if (created == true) {
      _loadSchools();
    }
  }

  Future<void> _editSchool(School school) async {
    final updated = await SchoolFormDialog.show(context, school: school);
    if (updated == true) {
      _loadSchools();
    }
  }

  Future<void> _deleteSchool(School school) async {
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
        content: Text(
          'Supprimer "${school.name}" supprimera également toutes ses classes, élèves et notes associées.\n\nCette action est irréversible.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: EduNoteColors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final delete = GetIt.I<DeleteSchool>();
        await delete(school.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${school.name}" a été supprimé.'),
              backgroundColor: EduNoteColors.navy,
            ),
          );
          _loadSchools();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: EduNoteColors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSchools = _allSchools.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          s.type.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EduNoteColors.paleBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: EduNoteColors.navy,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Établissements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: EduNoteColors.navy,
                          ),
                        ),
                        Text(
                          'Gérez vos écoles et collèges',
                          style: TextStyle(
                            fontSize: 12,
                            color: EduNoteColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _createSchool,
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
            ),
            if (_allSchools.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une école, une ville...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            Expanded(
              child: _buildBody(filteredSchools),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<School> schools) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EduNoteColors.blue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadSchools,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_allSchools.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: EduNoteColors.paleBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 40,
                  color: EduNoteColors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun établissement enregistré',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: EduNoteColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez vos établissements pour organiser vos classes, élèves et notes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: EduNoteColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _createSchool,
                style: FilledButton.styleFrom(
                  backgroundColor: EduNoteColors.navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un établissement'),
              ),
            ],
          ),
        ),
      );
    }

    if (schools.isEmpty) {
      return const Center(
        child: Text(
          'Aucun établissement ne correspond à votre recherche.',
          style: TextStyle(color: EduNoteColors.muted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchools,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: schools.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final school = schools[index];
          return _SchoolCard(
            school: school,
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => SchoolDetailPage(schoolId: school.id),
                ),
              );
              if (changed == true) {
                _loadSchools();
              }
            },
            onEdit: () => _editSchool(school),
            onDelete: () => _deleteSchool(school),
          );
        },
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({
    required this.school,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final School school;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EduNoteColors.paleBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: EduNoteColors.blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: EduNoteColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                school.type,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: EduNoteColors.navy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: EduNoteColors.muted,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                school.city,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: EduNoteColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: EduNoteColors.red,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: EduNoteColors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (school.address != null && school.address!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  school.address!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EduNoteColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
