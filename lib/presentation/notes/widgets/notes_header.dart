import 'package:flutter/material.dart';

class NotesHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 24, 48, 24),
      child: Row(
        children: [
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
                  color: const Color(0xFFF59E0B).withOpacity(0.5),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  offset: const Offset(-2, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4, left: 4, right: 20,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 220,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
              cursorColor: const Color(0xFFD97706),
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
          ElevatedButton.icon(
            onPressed: onNewNote,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD97706),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 8,
              shadowColor: Colors.white.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}