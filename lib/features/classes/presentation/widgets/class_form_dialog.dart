import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../../academic_years/domain/entities/academic_year.dart';
import '../../../academic_years/domain/repositories/academic_year_repository.dart';
import '../../domain/entities/school_class.dart';
import '../../domain/usecases/create_class.dart';
import '../../domain/usecases/update_class.dart';

class ClassFormDialog extends StatefulWidget {
  const ClassFormDialog({
    super.key,
    required this.schoolId,
    this.schoolClass,
  });

  final String schoolId;
  final SchoolClass? schoolClass;

  static Future<bool?> show(
    BuildContext context, {
    required String schoolId,
    SchoolClass? schoolClass,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClassFormDialog(
        schoolId: schoolId,
        schoolClass: schoolClass,
      ),
    );
  }

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedLevel;
  String? _selectedYearId;
  List<AcademicYear> _academicYears = [];

  bool _isLoading = false;
  String? _errorMessage;

  static const _levels = [
    '6e',
    '5e',
    '4e',
    '3e',
    '2nde',
    '1ère',
    'Tle',
    'Primaire',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.schoolClass;
    _nameController = TextEditingController(text: c?.name ?? '');
    _selectedLevel = (c != null && _levels.contains(c.level)) ? c.level : '6e';
    _selectedYearId = c?.academicYearId;
    _loadYears();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadYears() async {
    try {
      final repo = GetIt.I<AcademicYearRepository>();
      await repo.ensureDefaultAcademicYear();
      final years = await repo.getAcademicYears();
      final active = await repo.getActiveAcademicYear();

      if (mounted) {
        setState(() {
          _academicYears = years;
          _selectedYearId ??= active?.id ?? (years.isNotEmpty ? years.first.id : null);
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedYearId == null) {
      setState(() => _errorMessage = 'Veuillez sélectionner une année scolaire.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();

      if (widget.schoolClass == null) {
        final createClass = GetIt.I<CreateClass>();
        await createClass(
          schoolId: widget.schoolId,
          academicYearId: _selectedYearId!,
          name: name,
          level: _selectedLevel,
        );
      } else {
        final updateClass = GetIt.I<UpdateClass>();
        await updateClass(
          id: widget.schoolClass!.id,
          name: name,
          level: _selectedLevel,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schoolClass != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: EduNoteColors.paleBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.class_outlined,
                        color: EduNoteColors.blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Modifier la classe' : 'Nouvelle classe',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: EduNoteColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Mettez à jour les informations'
                                : 'Rattachez une classe à cet établissement',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EduNoteColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: EduNoteColors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la classe *',
                    hintText: 'Ex: 6e A, 3e C, Tle D...',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le nom de la classe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Niveau d\'enseignement *',
                    prefixIcon: Icon(Icons.stairs_outlined),
                  ),
                  items: _levels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedLevel = val);
                          }
                        },
                ),
                if (!isEditing && _academicYears.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedYearId,
                    decoration: const InputDecoration(
                      labelText: 'Année scolaire *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    items: _academicYears
                        .map(
                          (y) => DropdownMenuItem(
                            value: y.id,
                            child: Text(
                              '${y.label}${y.isActive ? ' (Active)' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedYearId = val);
                            }
                          },
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: EduNoteColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEditing ? 'Enregistrer' : 'Créer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
