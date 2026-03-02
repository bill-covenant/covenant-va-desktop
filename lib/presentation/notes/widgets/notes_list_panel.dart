import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';

class NotesListPanel extends StatelessWidget {
  final List<NoteModel> notes;
  final String searchQuery;
  final NoteModel? selectedNote;
  final ValueChanged<NoteModel> onNoteSelected;

  const NotesListPanel({
    super.key,
    required this.notes,
    required this.searchQuery,
    required this.selectedNote,
    required this.onNoteSelected,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    var filtered = notes;
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((n) =>
          n.title.toLowerCase().contains(searchQuery) ||
          n.content.toLowerCase().contains(searchQuery)).toList();
    }

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildNoteItem(filtered[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_add_rounded, color: Colors.white.withOpacity(0.3), size: 48),
          const SizedBox(height: 12),
          Text(
            searchQuery.isNotEmpty ? 'No matching notes' : 'No notes yet',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (searchQuery.isEmpty)
            Text(
              'Click "+ New Note" to get started',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(NoteModel note) {
    final isSelected = selectedNote?.id == note.id;

    return GestureDetector(
      onTap: () => onNoteSelected(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.isPinned) ...[
                  Icon(Icons.push_pin, color: Colors.amber.withOpacity(0.8), size: 14),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.content,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (note.category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _parseColor(note.category!.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      note.category!.name,
                      style: TextStyle(
                        color: _parseColor(note.category!.color),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}