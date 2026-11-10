import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../domain/entities/school.dart';
import '../../domain/usecases/create_school.dart';
import '../../domain/usecases/update_school.dart';

class SchoolFormDialog extends StatefulWidget {
  const SchoolFormDialog({super.key, this.school});

  final School? school;

  static Future<bool?> show(BuildContext context, {School? school}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SchoolFormDialog(school: school),
    );
  }

  @override
  State<SchoolFormDialog> createState() => _SchoolFormDialogState();
}

class _SchoolFormDialogState extends State<SchoolFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late String _selectedType;

  bool _isLoading = false;
  String? _errorMessage;

  static const _schoolTypes = ['Primaire', 'Collège', 'Lycée', 'Autre'];

  @override
  void initState() {
    super.initState();
    final school = widget.school;
    _nameController = TextEditingController(text: school?.name ?? '');
    _cityController = TextEditingController(text: school?.city ?? '');
    _addressController = TextEditingController(text: school?.address ?? '');
    _selectedType = (school != null && _schoolTypes.contains(school.type))
        ? school.type
        : 'Collège';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final city = _cityController.text.trim();
      final address = _addressController.text.trim();
      final addressValue = address.isEmpty ? null : address;

      if (widget.school == null) {
        final createSchool = GetIt.I<CreateSchool>();
        await createSchool(
          name: name,
          type: _selectedType,
          city: city,
          address: addressValue,
        );
      } else {
        final updateSchool = GetIt.I<UpdateSchool>();
        await updateSchool(
          id: widget.school!.id,
          name: name,
          type: _selectedType,
          city: city,
          address: addressValue,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Une erreur est survenue : ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.school != null;

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
                        Icons.apartment_rounded,
                        color: EduNoteColors.blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Modifier l\'établissement'
                                : 'Nouvel établissement',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: EduNoteColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Mettez à jour les coordonnées'
                                : 'Renseignez les détails de l\'école',
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
                    labelText: 'Nom de l\'établissement *',
                    hintText: 'Ex: CEG Porto-Novo',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le nom de l\'établissement';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'établissement *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _schoolTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedType = val);
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Ville ou commune *',
                    hintText: 'Ex: Porto-Novo, Cotonou...',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez renseigner la ville ou la commune';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Adresse ou quartier (facultatif)',
                    hintText: 'Ex: Quartier Avakpa',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
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
