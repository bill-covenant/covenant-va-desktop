import 'package:flutter/material.dart';

class TaskFilterBar extends StatelessWidget {
  final String statusFilter;
  final String priorityFilter;
  final String searchQuery;
  final Function(String) onStatusChanged;
  final Function(String) onPriorityChanged;
  final Function(String) onSearchChanged;

  const TaskFilterBar({
    super.key,
    required this.statusFilter,
    required this.priorityFilter,
    required this.searchQuery,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25), // ✅ Increased opacity
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(-2, -2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _build3DFilter(
                  label: 'Status',
                  value: statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                    DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                  ],
                  onChanged: onStatusChanged,
                  icon: Icons.filter_list,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _build3DFilter(
                  label: 'Priority',
                  value: priorityFilter,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  ],
                  onChanged: onPriorityChanged,
                  icon: Icons.priority_high,
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _build3DSearchBar(),
        ],
      ),
    );
  }

  Widget _build3DFilter({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Improved label with better contrast
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white, // ✅ White icon
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white, // ✅ Keep white text
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ✅ Improved dropdown with better contrast
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // ✅ More opaque background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(-1, -1),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: color, // ✅ Colored icon for contrast
              size: 24,
            ),
            style: TextStyle(
              color: const Color(0xFF1F2937), // ✅ Dark text for contrast
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            items: items,
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _build3DSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Solid white background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: const TextStyle(
          color: Color(0xFF111827), // ✅ Dark text
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF), // ✅ Gray hint text
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6366F1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}