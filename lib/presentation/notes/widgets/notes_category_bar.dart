import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';

class NotesCategoryBar extends StatelessWidget {
  final List<NoteCategory> categories;
  final String? activeCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<NoteCategory> onCategoryLongPress;
  final VoidCallback onAddCategory;

  const NotesCategoryBar({
    super.key,
    required this.categories,
    required this.activeCategoryId,
    required this.onCategorySelected,
    required this.onCategoryLongPress,
    required this.onAddCategory,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildChip('All', null, activeCategoryId == null),
          ...categories.map((cat) => _buildChip(
            cat.name,
            cat.id,
            activeCategoryId == cat.id,
            color: _parseColor(cat.color),
            onLongPress: () => onCategoryLongPress(cat),
          )),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String? categoryId, bool isActive,
      {Color? color, VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: () => onCategorySelected(categoryId),
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (color ?? Colors.white).withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? (color ?? Colors.white).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(isActive ? 1.0 : 0.6),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddCategory,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Center(
          child: Icon(Icons.add, color: Colors.white.withOpacity(0.4), size: 18),
        ),
      ),
    );
  }
}