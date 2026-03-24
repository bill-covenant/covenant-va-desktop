// lib/presentation/timecard/widgets/time_entry_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/time_entry.dart';

class TimeEntryCard extends StatefulWidget {
  final TimeEntry entry;
  final Function(String) onDelete;

  const TimeEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  State<TimeEntryCard> createState() => _TimeEntryCardState();
}

class _TimeEntryCardState extends State<TimeEntryCard> {
  bool _isEditHovered = false;
  bool _isEditPressed = false;
  bool _isDeleteHovered = false;
  bool _isDeletePressed = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = ThemeProvider().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? null : const Color(0xFFF9FAFB),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                ],
              )
            : null,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Compact Date Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(entry.date).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  DateFormat('d').format(entry.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Status + Hours badges
          _buildStatusBadge(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
              border: isDark ? null : Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 12, color: isDark ? Colors.white70 : const Color(0xFF6366F1)),
                const SizedBox(width: 4),
                Text(
                  '${entry.hoursWorked} hrs',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF4338CA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Description
          Expanded(
            child: Text(
              entry.description ?? '',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rejection reason inline
          if (entry.status == 'REJECTED' && entry.rejectionReason != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: entry.rejectionReason!,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 12, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Rejected',
                      style: TextStyle(
                        color: Colors.redAccent.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 3D Edit & Delete Buttons
          if (entry.status != 'APPROVED') ...[
            const SizedBox(width: 10),

            // Edit Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isEditHovered = true),
              onExit: (_) => setState(() {
                _isEditHovered = false;
                _isEditPressed = false;
              }),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isEditPressed = true),
                onTapUp: (_) => setState(() => _isEditPressed = false),
                onTapCancel: () => setState(() => _isEditPressed = false),
                onTap: () => _showEditNotesDialog(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 36,
                  transform: Matrix4.translationValues(
                    0,
                    _isEditPressed ? 2 : (_isEditHovered ? -1 : 0),
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isEditHovered
                          ? [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
                          : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                    ),
                    boxShadow: _isEditPressed
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFF4C1D95).withOpacity(0.6),
                              blurRadius: 0,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(
                                _isEditHovered ? 0.4 : 0.15,
                              ),
                              blurRadius: _isEditHovered ? 12 : 6,
                              offset: const Offset(0, 2),
                              spreadRadius: _isEditHovered ? 1 : 0,
                            ),
                          ],
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        _isEditHovered ? 0.25 : 0.1,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(
                        _isEditHovered ? 1.0 : 0.9,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Delete Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isDeleteHovered = true),
              onExit: (_) => setState(() {
                _isDeleteHovered = false;
                _isDeletePressed = false;
              }),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isDeletePressed = true),
                onTapUp: (_) => setState(() => _isDeletePressed = false),
                onTapCancel: () => setState(() => _isDeletePressed = false),
                onTap: () => _showDeleteConfirmation(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 36,
                  transform: Matrix4.translationValues(
                    0,
                    _isDeletePressed ? 2 : (_isDeleteHovered ? -1 : 0),
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isDeleteHovered
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
                    ),
                    boxShadow: _isDeletePressed
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [
                            // Bottom shadow for 3D depth
                            BoxShadow(
                              color: const Color(0xFF991B1B).withOpacity(0.6),
                              blurRadius: 0,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                            // Glow on hover
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(
                                _isDeleteHovered ? 0.4 : 0.15,
                              ),
                              blurRadius: _isDeleteHovered ? 12 : 6,
                              offset: const Offset(0, 2),
                              spreadRadius: _isDeleteHovered ? 1 : 0,
                            ),
                          ],
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        _isDeleteHovered ? 0.25 : 0.1,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.delete_rounded,
                      size: 17,
                      color: Colors.white.withOpacity(
                        _isDeleteHovered ? 1.0 : 0.9,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.entry.status) {
      case 'APPROVED':
        return const Color(0xFF10B981);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      case 'SUBMITTED':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon() {
    switch (widget.entry.status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'SUBMITTED':
      default:
        return Icons.pending;
    }
  }

  String _getStatusText() {
    switch (widget.entry.status) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'SUBMITTED':
      default:
        return 'Pending';
    }
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    final icon = _getStatusIcon();
    final text = _getStatusText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context) {
    // Extract just the notes portion from description
    final description = widget.entry.description ?? '';
    String existingNotes = '';
    for (final line in description.split('\n')) {
      if (line.startsWith('Notes: ')) {
        existingNotes = line.replaceFirst('Notes: ', '');
        break;
      }
    }
    final controller = TextEditingController(text: existingNotes);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.edit_rounded, size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Notes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Add notes about your work...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).then((newNotes) {
      if (newNotes == null) return;
      // Rebuild description with updated notes
      final lines = description.split('\n');
      final updatedLines = <String>[];
      bool notesFound = false;
      for (final line in lines) {
        if (line.startsWith('Notes: ')) {
          notesFound = true;
          if ((newNotes as String).isNotEmpty) {
            updatedLines.add('Notes: $newNotes');
          }
        } else {
          updatedLines.add(line);
        }
      }
      if (!notesFound && (newNotes as String).isNotEmpty) {
        updatedLines.add('Notes: $newNotes');
      }
      final updatedDescription = updatedLines.join('\n').trim();

      // TODO: Call your repository to update the entry on the backend
      // e.g. _timecardRepo.updateTimeEntry(widget.entry.id, description: updatedDescription);
      print('📝 Updated notes for entry ${widget.entry.id}: $updatedDescription');
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Time Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this time entry?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDelete(widget.entry.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}