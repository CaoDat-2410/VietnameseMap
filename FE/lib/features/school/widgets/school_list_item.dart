import 'package:flutter/material.dart';

import '../shared/models/school_model.dart';

class SchoolListItem extends StatelessWidget {
  const SchoolListItem({super.key, required this.school, required this.onTap});

  final SchoolModel school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            school.areaType.isEmpty
                ? '?'
                : school.areaType.replaceFirst('KV', ''),
          ),
        ),
        title: Text(
          school.schoolName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${school.schoolUid} • ${school.provinceName} • ${school.communeName}\n'
          '${school.address.isEmpty ? 'No address' : school.address}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
