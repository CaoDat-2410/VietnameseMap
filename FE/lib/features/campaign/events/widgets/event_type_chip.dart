import 'package:flutter/material.dart';

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({super.key, required this.eventType});

  final String eventType;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.event_note, size: 18),
      label: Text(eventType),
    );
  }
}
