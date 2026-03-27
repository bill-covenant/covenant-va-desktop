import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class ExtendedProfileCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUpdated;

  const ExtendedProfileCard({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<ExtendedProfileCard> createState() => _ExtendedProfileCardState();
}

class _ExtendedProfileCardState extends State<ExtendedProfileCard> {
  final _repo = GetIt.I<UserRepository>();
  bool _saving = false;

  // Contact
  late TextEditingController _phoneCtrl;
  late TextEditingController _secondaryEmailCtrl;
  late TextEditingController _whatsappCtrl;

  // Demographics
  DateTime? _dateOfBirth;
  String? _gender;
  late TextEditingController _nationalityCtrl;

  // Emergency
  late TextEditingController _emergNameCtrl;
  late TextEditingController _emergPhoneCtrl;
  late TextEditingController _emergRelCtrl;

  // Professional
  late TextEditingController _bioCtrl;
  late TextEditingController _skillInputCtrl;
  late TextEditingController _langInputCtrl;
  List<String> _skills = [];
  List<String> _languages = [];

  @override
  void initState() {
    super.initState();
    final p = widget.user.profile;
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _secondaryEmailCtrl = TextEditingController(text: p?.secondaryEmail ?? '');
    _whatsappCtrl = TextEditingController(text: p?.whatsapp ?? '');
    _dateOfBirth = p?.dateOfBirth;
    _gender = p?.gender;
    _nationalityCtrl = TextEditingController(text: p?.nationality ?? '');
    _emergNameCtrl = TextEditingController(text: p?.emergencyContactName ?? '');
    _emergPhoneCtrl = TextEditingController(text: p?.emergencyContactPhone ?? '');
    _emergRelCtrl = TextEditingController(text: p?.emergencyContactRelationship ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _skillInputCtrl = TextEditingController();
    _langInputCtrl = TextEditingController();
    _skills = List<String>.from(p?.skills ?? []);
    _languages = List<String>.from(p?.languages ?? []);
  }

  @override
  void didUpdateWidget(covariant ExtendedProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      final p = widget.user.profile;
      _phoneCtrl.text = p?.phone ?? '';
      _secondaryEmailCtrl.text = p?.secondaryEmail ?? '';
      _whatsappCtrl.text = p?.whatsapp ?? '';
      _dateOfBirth = p?.dateOfBirth;
      _gender = p?.gender;
      _nationalityCtrl.text = p?.nationality ?? '';
      _emergNameCtrl.text = p?.emergencyContactName ?? '';
      _emergPhoneCtrl.text = p?.emergencyContactPhone ?? '';
      _emergRelCtrl.text = p?.emergencyContactRelationship ?? '';
      _bioCtrl.text = p?.bio ?? '';
      _skills = List<String>.from(p?.skills ?? []);
      _languages = List<String>.from(p?.languages ?? []);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _secondaryEmailCtrl.dispose();
    _whatsappCtrl.dispose();
    _nationalityCtrl.dispose();
    _emergNameCtrl.dispose();
    _emergPhoneCtrl.dispose();
    _emergRelCtrl.dispose();
    _bioCtrl.dispose();
    _skillInputCtrl.dispose();
    _langInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSection(Map<String, dynamic> fields) async {
    setState(() => _saving = true);
    try {
      // Build the call dynamically based on keys
      await _repo.updateProfile(
        phone: fields['phone'],
        secondaryEmail: fields['secondaryEmail'],
        whatsapp: fields['whatsapp'],
        dateOfBirth: fields['dateOfBirth'] as DateTime?,
        gender: fields['gender'],
        nationality: fields['nationality'],
        emergencyContactName: fields['emergencyContactName'],
        emergencyContactPhone: fields['emergencyContactPhone'],
        emergencyContactRelationship: fields['emergencyContactRelationship'],
        bio: fields['bio'],
        skills: fields['skills'] as List<String>?,
        languages: fields['languages'] as List<String>?,
      );
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeProvider().isDarkMode;

    return Column(
      children: [
        // Row 1: Contact + Demographics side by side
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildSection(
                dark: dark,
                icon: Icons.phone_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Contact Info',
                onSave: () => _saveSection({
                  'phone': _phoneCtrl.text,
                  'secondaryEmail': _secondaryEmailCtrl.text,
                  'whatsapp': _whatsappCtrl.text,
                }),
                children: [
                  _buildReadOnlyField(dark, 'Primary Email', widget.user.email, Icons.email_rounded),
                  const SizedBox(height: 10),
                  _buildTextField(dark, 'Phone Number', _phoneCtrl, Icons.phone_rounded),
                  const SizedBox(height: 10),
                  _buildTextField(dark, 'Secondary Email', _secondaryEmailCtrl, Icons.email_outlined),
                  const SizedBox(height: 10),
                  _buildTextField(dark, 'WhatsApp Number', _whatsappCtrl, Icons.chat_rounded),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSection(
                dark: dark,
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Demographics',
                onSave: () => _saveSection({
                  'dateOfBirth': _dateOfBirth,
                  'gender': _gender,
                  'nationality': _nationalityCtrl.text,
                }),
                children: [
                  _buildDateField(dark),
                  const SizedBox(height: 10),
                  _buildGenderField(dark),
                  const SizedBox(height: 10),
                  _buildTextField(dark, 'Nationality', _nationalityCtrl, Icons.flag_rounded),
                ],
              ),
            ),
          ],
        )),
        const SizedBox(height: 16),
        // Row 2: Emergency + Professional side by side
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildSection(
                dark: dark,
                icon: Icons.emergency_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Emergency Contact',
                onSave: () => _saveSection({
                  'emergencyContactName': _emergNameCtrl.text,
                  'emergencyContactPhone': _emergPhoneCtrl.text,
                  'emergencyContactRelationship': _emergRelCtrl.text,
                }),
                children: [
                  _buildTextField(dark, 'Contact Name', _emergNameCtrl, Icons.person_rounded),
                  const SizedBox(height: 10),
                  _buildTextField(dark, 'Emergency Phone', _emergPhoneCtrl, Icons.phone_rounded),
                  const SizedBox(height: 10),
                  _buildTextField(dark, 'Relationship', _emergRelCtrl, Icons.people_rounded),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSection(
                dark: dark,
                icon: Icons.work_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Professional Details',
                onSave: () => _saveSection({
                  'bio': _bioCtrl.text,
                }),
                children: [
                  _buildTextField(dark, 'Bio / About', _bioCtrl, Icons.info_outline_rounded, maxLines: 3),
                ],
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildSection({
    required bool dark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onSave,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF1E2235), const Color(0xFF171B2D)]
              : [Colors.white, const Color(0xFFF8F9FB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: iconColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(bool dark, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.04) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.7) : const Color(0xFF4B5563))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(bool dark, String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: dark ? Colors.white : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: 'Not provided',
            hintStyle: TextStyle(color: dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(bool dark) {
    final formatted = _dateOfBirth != null
        ? '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
        : 'Not provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF)),
                const SizedBox(width: 12),
                Text(formatted, style: TextStyle(fontSize: 14, color: _dateOfBirth != null ? (dark ? Colors.white : const Color(0xFF1F2937)) : (dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gender,
              isExpanded: true,
              hint: Text('Select', style: TextStyle(color: dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB))),
              dropdownColor: dark ? const Color(0xFF1E2235) : Colors.white,
              style: TextStyle(fontSize: 14, color: dark ? Colors.white : const Color(0xFF1F2937)),
              items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _gender = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipInput(bool dark, String label, List<String> items, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 14, color: dark ? Colors.white : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            prefixIcon: items.isEmpty
                ? Icon(Icons.add_rounded, size: 18, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF))
                : Padding(
                    padding: const EdgeInsets.only(left: 10, right: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.map((item) => Chip(
                        label: Text(item, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dark ? Colors.white : const Color(0xFF374151))),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => items.remove(item)),
                        backgroundColor: dark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ),
            prefixIconConstraints: items.isEmpty ? null : const BoxConstraints(maxWidth: 300),
            filled: true,
            fillColor: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: items.isEmpty ? 'Type and press Enter to add...' : 'Add more...',
            hintStyle: TextStyle(color: dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB)),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              setState(() {
                items.add(val.trim());
                ctrl.clear();
              });
            }
          },
        ),
      ],
    );
  }
}
