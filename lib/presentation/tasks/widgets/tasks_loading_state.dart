import 'package:flutter/material.dart';

class TasksLoadingState extends StatelessWidget {
  const TasksLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }
}