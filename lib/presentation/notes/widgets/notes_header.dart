import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

class NotesHeader extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNewNote;

  const NotesHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onNewNote,
  });

  @override
  State<NotesHeader> createState() => _NotesHeaderState();
}

class _NotesHeaderState extends State<NotesHeader> {
  bool _isNewNoteHovered = false;
  bool _isNewNotePressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 24, 48, 24),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                  offset: const Offset(0, 6),
                  blurRadius: 20,
                ),
                // 3D bottom shadow
                BoxShadow(
                  color: const Color(0xFFB45309).withOpacity(0.8),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Stack(
              children: [
                // Glass reflection
                Positioned(
                  top: 4, left: 4, right: 20,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.35), Colors.white.withOpacity(0.0)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Center(child: Icon(Icons.sticky_note_2_rounded, color: Colors.white, size: 28)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE0E7FF)],
            ).createShader(bounds),
            child: const Text(
              'My Notes',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
          const Spacer(),
          // Search
          Container(
            width: 220,
            height: 44,
            decoration: BoxDecoration(
              color: ThemeProvider().isDarkMode ? const Color(0xFF1A1D2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeProvider().isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(ThemeProvider().isDarkMode ? 0.2 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withOpacity(ThemeProvider().isDarkMode ? 0.1 : 0.04), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              style: TextStyle(color: ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF374151), fontSize: 14),
              cursorColor: const Color(0xFF8B5CF6),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // New Note 3D Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isNewNoteHovered = true),
            onExit: (_) => setState(() { _isNewNoteHovered = false; _isNewNotePressed = false; }),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isNewNotePressed = true),
              onTapUp: (_) => setState(() => _isNewNotePressed = false),
              onTapCancel: () => setState(() => _isNewNotePressed = false),
              onTap: widget.onNewNote,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                transform: Matrix4.translationValues(
                  0, _isNewNotePressed ? 2 : (_isNewNoteHovered ? -1 : 0), 0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isNewNoteHovered
                        ? [const Color(0xFF9333EA), const Color(0xFF7C3AED)]
                        : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(_isNewNoteHovered ? 0.3 : 0.15)),
                  boxShadow: _isNewNotePressed
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF4C1D95).withOpacity(0.7),
                            blurRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(_isNewNoteHovered ? 0.5 : 0.25),
                            blurRadius: _isNewNoteHovered ? 16 : 8,
                            offset: const Offset(0, 4),
                            spreadRadius: _isNewNoteHovered ? 1 : 0,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'New Note',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}