import 'package:flutter/material.dart';

class PillBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const PillBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w700)),
    );
  }
}
