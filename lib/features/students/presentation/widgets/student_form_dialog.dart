import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/edu_note_theme.dart';
import '../../domain/entities/student.dart';
import '../../domain/usecases/create_student.dart';
import '../../domain/usecases/generate_registration_number.dart';
import '../../domain/usecases/update_student.dart';

class StudentFormDialog extends StatefulWidget {
  const StudentFormDialog({
    super.key,
    required this.classId,
    this.student,
  });

  final String classId;
  final Student? student;

  static Future<bool?> show(
    BuildContext context, {
    required String classId,
    Student? student,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudentFormDialog(
        classId: classId,
        student: student,
      ),
    );
  }

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _registrationNumberController;
  late final TextEditingController _orderNumberController;
  String _selectedGender = 'M';
  DateTime? _dateOfBirth;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _lastNameController = TextEditingController(text: s?.lastName ?? '');
    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _registrationNumberController =
        TextEditingController(text: s?.registrationNumber ?? '');
    _orderNumberController = TextEditingController(
      text: s?.orderNumber != null ? '${s!.orderNumber}' : '',
    );
    _selectedGender = s?.gender ?? 'M';
    _dateOfBirth = s?.dateOfBirth;

    if (s == null) {
      _autoGenerateRegistrationNumber();
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _registrationNumberController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<void> _autoGenerateRegistrationNumber() async {
    try {
      final generator = GetIt.I<GenerateRegistrationNumber>();
      final num = await generator(widget.classId);
      if (mounted && _registrationNumberController.text.isEmpty) {
        setState(() {
          _registrationNumberController.text = num;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 14, 1, 1),
      firstDate: DateTime(now.year - 40),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lastName = _lastNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final regNumber = _registrationNumberController.text.trim();
      final orderText = _orderNumberController.text.trim();
      final orderNumber = orderText.isNotEmpty ? int.tryParse(orderText) : null;

      if (widget.student == null) {
        final createStudent = GetIt.I<CreateStudent>();
        await createStudent(
          classId: widget.classId,
          lastName: lastName,
          firstName: firstName,
          gender: _selectedGender,
          dateOfBirth: _dateOfBirth,
          registrationNumber: regNumber.isNotEmpty ? regNumber : null,
          orderNumber: orderNumber,
        );
      } else {
        final updateStudent = GetIt.I<UpdateStudent>();
        await updateStudent(
          id: widget.student!.id,
          lastName: lastName,
          firstName: firstName,
          gender: _selectedGender,
          dateOfBirth: _dateOfBirth,
          registrationNumber: regNumber.isNotEmpty ? regNumber : null,
          orderNumber: orderNumber,
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
    final isEditing = widget.student != null;

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
                        Icons.person_add_outlined,
                        color: EduNoteColors.blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Modifier l\'élève' : 'Nouvel élève',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: EduNoteColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Mettez à jour le profil de l\'élève'
                                : 'Inscrivez un élève dans cette classe',
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
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nom de famille *',
                    hintText: 'Ex: HOUNNOU',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le nom de famille';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Prénoms *',
                    hintText: 'Ex: Jean-Paul',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir les prénoms';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Sexe',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'M',
                            child: Text('Masculin (M)'),
                          ),
                          DropdownMenuItem(
                            value: 'F',
                            child: Text('Féminin (F)'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedGender = val);
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _orderNumberController,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'N° d\'ordre',
                          hintText: 'Ex: 1, 2...',
                          prefixIcon: Icon(Icons.format_list_numbered_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isLoading ? null : _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de naissance',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                          : 'Non renseignée',
                      style: TextStyle(
                        color: _dateOfBirth != null
                            ? EduNoteColors.ink
                            : EduNoteColors.muted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _registrationNumberController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Matricule',
                    hintText: 'Ex: MAT-2026-001',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Régénérer automatiquement',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _isLoading
                          ? null
                          : _autoGenerateRegistrationNumber,
                    ),
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
                            : Text(isEditing ? 'Enregistrer' : 'Inscrire'),
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
