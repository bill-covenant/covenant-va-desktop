import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class SkillsExperienceCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUpdated;

  const SkillsExperienceCard({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<SkillsExperienceCard> createState() => _SkillsExperienceCardState();
}

class _SkillsExperienceCardState extends State<SkillsExperienceCard> {
  final _repo = GetIt.I<UserRepository>();
  bool _saving = false;

  late List<String> _skills;
  late List<String> _languages;
  final _skillCtrl = TextEditingController();
  final _langCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _skills = List<String>.from(widget.user.profile?.skills ?? []);
    _languages = List<String>.from(widget.user.profile?.languages ?? []);
  }

  @override
  void didUpdateWidget(covariant SkillsExperienceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user && !_saving) {
      setState(() {
        _skills = List<String>.from(widget.user.profile?.skills ?? []);
        _languages = List<String>.from(widget.user.profile?.languages ?? []);
      });
    }
  }

  @override
  void dispose() {
    _skillCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Add any pending text from input fields before saving
    if (_skillCtrl.text.trim().isNotEmpty) {
      _skills.add(_skillCtrl.text.trim());
      _skillCtrl.clear();
    }
    if (_langCtrl.text.trim().isNotEmpty) {
      _languages.add(_langCtrl.text.trim());
      _langCtrl.clear();
    }
    setState(() => _saving = true);
    try {
      await _repo.updateProfile(skills: _skills, languages: _languages);
      // Update local state immediately so UI stays in sync
      setState(() {});
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved successfully'),
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
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeProvider().isDarkMode;
    final joinedDate = widget.user.createdAt != null
        ? _formatDate(widget.user.createdAt!)
        : 'Not available';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skills & Expertise
          Expanded(child: _buildCard(
            dark: dark,
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Skills & Expertise',
            child: _buildChipSection(dark, _skills, _skillCtrl, 'Add a skill...'),
          )),
          const SizedBox(width: 16),
          // Experience + Languages stacked
          Expanded(child: Column(
            children: [
              _buildCard(
                dark: dark,
                icon: Icons.work_history_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Experience',
                child: Column(
                  children: [
                    _buildInfoRow(dark, 'Joined', joinedDate, Icons.calendar_today_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildCard(
                dark: dark,
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Languages',
                child: _buildChipSection(dark, _languages, _langCtrl, 'Add a language...'),
              )),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool dark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [iconColor, iconColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: iconColor.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: dark ? Colors.white : const Color(0xFF1F2937))),
                const Spacer(),
                _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton.icon(
                        onPressed: _save,
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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildChipSection(bool dark, List<String> items, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty)
          Wrap(
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
        if (items.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 13, color: dark ? Colors.white : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.add_rounded, size: 18, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB)),
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

  Widget _buildInfoRow(bool dark, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dark ? Colors.white : const Color(0xFF1F2937))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
