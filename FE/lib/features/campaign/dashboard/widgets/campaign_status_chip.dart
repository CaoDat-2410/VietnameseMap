import 'package:flutter/material.dart';

class CampaignStatusChip extends StatelessWidget {
  const CampaignStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => Colors.green,
      'DONE' => Colors.blue,
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
