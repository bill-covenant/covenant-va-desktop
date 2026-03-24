import 'package:flutter/material.dart';

Color getPriorityColor(String priority) {
  switch (priority) {
    case 'URGENT': return const Color(0xFFDC2626);
    case 'HIGH': return const Color(0xFFEA580C);
    case 'MEDIUM': return const Color(0xFFD97706);
    case 'LOW': return const Color(0xFF2563EB);
    default: return const Color(0xFF6B7280);
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'COMPLETED': return const Color(0xFF10B981);
    case 'IN_PROGRESS': return const Color(0xFF8B5CF6);
    case 'PENDING': return const Color(0xFFF59E0B);
    case 'ARCHIVED': return const Color(0xFF6366F1);
    default: return const Color(0xFF6B7280);
  }
}
