import 'package:flutter/material.dart';

class MessagesLoadingState extends StatelessWidget {
  const MessagesLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }
}