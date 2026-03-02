import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';

class NotesDialogs {
  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  static Future<bool?> showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, String>?> showCreateCategory(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedColor = '#8B5CF6';
    final colors = ['#8B5CF6', '#EC4899', '#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#6366F1', '#14B8A6'];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Category name',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Color', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _parseColor(c),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedColor == c ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, {
                    'name': nameCtrl.text.trim(),
                    'color': selectedColor,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showCategoryOptions(BuildContext context, NoteCategory category) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(category.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('${category.noteCount} notes', style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Category', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}