import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';

class NotesEditorPanel extends StatelessWidget {
  final NoteModel? selectedNote;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onContentChanged;

  const NotesEditorPanel({
    super.key,
    required this.selectedNote,
    required this.titleController,
    required this.contentController,
    required this.onSave,
    required this.onDelete,
    required this.onTogglePin,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedNote == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.white.withOpacity(0.2), size: 64),
              const SizedBox(height: 12),
              Text('Select a note to edit', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                const Spacer(),
                _buildButton(
                  icon: selectedNote!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  tooltip: selectedNote!.isPinned ? 'Unpin' : 'Pin',
                  color: selectedNote!.isPinned ? Colors.amber.shade700 : null,
                  onTap: onTogglePin,
                ),
                const SizedBox(width: 8),
                _buildButton(icon: Icons.save_rounded, tooltip: 'Save', onTap: onSave),
                const SizedBox(width: 8),
                _buildButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', color: Colors.red.shade400, onTap: onDelete),
              ],
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: titleController,
              onChanged: (_) => onContentChanged(),
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 24, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: 'Note title...',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: TextField(
                controller: contentController,
                onChanged: (_) => onContentChanged(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.35)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required IconData icon, required String tooltip, Color? color, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Center(child: Icon(icon, color: color ?? Colors.grey.shade600, size: 18)),
          ),
        ),
      ),
    );
  }
}