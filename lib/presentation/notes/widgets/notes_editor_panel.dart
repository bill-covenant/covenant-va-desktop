import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/note_model.dart';

class NotesEditorPanel extends StatefulWidget {
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
  State<NotesEditorPanel> createState() => _NotesEditorPanelState();
}

class _NotesEditorPanelState extends State<NotesEditorPanel> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedNote == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.04)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(Icons.edit_note_rounded, color: Colors.white.withOpacity(0.2), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a note to edit',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final dark = ThemeProvider().isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1D2E) : const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(dark ? 0.3 : 0.12), blurRadius: 30, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(dark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [const Color(0xFF232738), const Color(0xFF1E2130)]
                    : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: dark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12))),
            ),
            child: Row(
              children: [
                // Note info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(widget.selectedNote!.updatedAt),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _ToolbarButton(
                  icon: widget.selectedNote!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  tooltip: widget.selectedNote!.isPinned ? 'Unpin' : 'Pin',
                  color: widget.selectedNote!.isPinned ? Colors.amber.shade700 : null,
                  isActive: widget.selectedNote!.isPinned,
                  activeColor: Colors.amber.shade100,
                  onTap: widget.onTogglePin,
                ),
                const SizedBox(width: 8),
                _ToolbarButton(
                  icon: Icons.save_rounded,
                  tooltip: 'Save',
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  iconColor: Colors.white,
                  onTap: widget.onSave,
                ),
                const SizedBox(width: 8),
                _ToolbarButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  color: Colors.red.shade400,
                  onTap: widget.onDelete,
                ),
              ],
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: TextField(
              controller: widget.titleController,
              onChanged: (_) => widget.onContentChanged(),
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Note title...',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.35), fontWeight: FontWeight.w600),
                border: InputBorder.none,
              ),
            ),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.grey.withOpacity(0.1), height: 16),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: TextField(
                controller: widget.contentController,
                onChanged: (_) => widget.onContentChanged(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: dark ? Colors.white70 : const Color(0xFF4B5563),
                  fontSize: 15,
                  height: 1.7,
                  letterSpacing: 0.1,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $h:$min $ampm';
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final Color? iconColor;
  final bool isActive;
  final Color? activeColor;
  final List<Color>? gradient;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.color,
    this.iconColor,
    this.isActive = false,
    this.activeColor,
    this.gradient,
    required this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasGradient = widget.gradient != null;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() { _isHovered = false; _isPressed = false; }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 38,
            height: 38,
            transform: Matrix4.translationValues(
              0, _isPressed ? 1 : (_isHovered ? -1 : 0), 0,
            ),
            decoration: BoxDecoration(
              gradient: hasGradient
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isHovered
                          ? [widget.gradient![0].withOpacity(0.9), widget.gradient![1]]
                          : widget.gradient!,
                    )
                  : null,
              color: hasGradient
                  ? null
                  : widget.isActive
                      ? widget.activeColor
                      : _isHovered
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasGradient
                    ? Colors.white.withOpacity(0.2)
                    : _isHovered
                        ? const Color(0xFF8B5CF6).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.12),
              ),
              boxShadow: _isPressed
                  ? []
                  : [
                      if (hasGradient) ...[
                        BoxShadow(
                          color: widget.gradient![1].withOpacity(_isHovered ? 0.4 : 0.2),
                          blurRadius: _isHovered ? 10 : 4,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4C1D95).withOpacity(0.5),
                          blurRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ] else ...[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: _isHovered ? 6 : 2,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ],
            ),
            child: Center(
              child: Icon(
                widget.icon,
                color: widget.iconColor ?? widget.color ?? Colors.grey.shade600,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}