// lib/presentation/timecard/widgets/time_card_widgets/clock_dialog/day_summary_dialog.dart

import 'package:flutter/material.dart';

class DaySummaryDialog extends StatefulWidget {
  final String clockInTime;
  final String clockOutTime;
  final double totalHours;

  const DaySummaryDialog({
    Key? key,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHours,
  }) : super(key: key);

  @override
  State<DaySummaryDialog> createState() => _DaySummaryDialogState();
}

class _DaySummaryDialogState extends State<DaySummaryDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedMood;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final List<_MoodOption> _moods = const [
    _MoodOption(emoji: '😊', label: 'Great!', value: 'great', color: Color(0xFF10B981)),
    _MoodOption(emoji: '🙂', label: 'Good', value: 'good', color: Color(0xFF3B82F6)),
    _MoodOption(emoji: '😐', label: 'Okay', value: 'okay', color: Color(0xFFF59E0B)),
    _MoodOption(emoji: '😓', label: 'Tough', value: 'tough', color: Color(0xFFF97316)),
    _MoodOption(emoji: '😫', label: 'Hard', value: 'hard', color: Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: 580,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF2D2A6E), Color(0xFF312E81)],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 80,
                  offset: const Offset(0, 40),
                ),
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.25),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Background orbs
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [const Color(0xFF8B5CF6).withOpacity(0.15), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60, left: -30,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [const Color(0xFF10B981).withOpacity(0.08), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildMoodSection(),
                      _buildNotesSection(),
                      _buildFooter(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.03)],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.nightlight_round, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Before you clock out...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take a moment to reflect on your day',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Session summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.login_rounded, size: 14, color: const Color(0xFF8B5CF6).withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(widget.clockInTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white.withOpacity(0.25)),
                ),
                Icon(Icons.logout_rounded, size: 14, color: const Color(0xFFEF4444).withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(widget.clockOutTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: const Color(0xFF10B981).withOpacity(0.9)),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.totalHours.toStringAsFixed(2)} hrs',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did you feel about your day?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          Row(
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [mood.color.withOpacity(0.25), mood.color.withOpacity(0.1)])
                          : LinearGradient(colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? mood.color.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: mood.color.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))]
                          : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: isSelected ? 12 : 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? mood.color : Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How did you make a difference in your Client's business today?",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.04)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 5,
              minLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Share what you accomplished or how you helped today...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.all(20),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                final moodLabel = _selectedMood != null
                    ? _moods.firstWhere((m) => m.value == _selectedMood).label
                    : null;
                Navigator.pop(context, {
                  'notes': _notesController.text.trim(),
                  'mood': _selectedMood,
                  'moodLabel': moodLabel,
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Complete Clock Out',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context, null),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                ),
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodOption {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
}