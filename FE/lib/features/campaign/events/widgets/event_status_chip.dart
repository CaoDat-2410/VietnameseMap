import 'package:flutter/material.dart';

class EventStatusChip extends StatelessWidget {
  const EventStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'DONE' => Colors.green,
      'IN_PROGRESS' => Colors.blue,
      'CANCELLED' => Colors.red,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(status),
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .1),
    );
  }
}
