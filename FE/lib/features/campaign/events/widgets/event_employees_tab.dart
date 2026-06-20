import 'package:flutter/material.dart';

const devEmployees = [
  (id: 1, fullName: 'Dev Staff', role: 'STAFF'),
  (id: 2, fullName: 'Dev Manager', role: 'MANAGER'),
  (id: 3, fullName: 'Dev Staff 2', role: 'STAFF'),
];

class EventEmployeesTab extends StatelessWidget {
  const EventEmployeesTab({
    super.key,
    required this.assignedIds,
    required this.onAssign,
    required this.onRemove,
  });

  final Set<int> assignedIds;
  final Future<void> Function(int employeeId) onAssign;
  final Future<void> Function(int employeeId) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devEmployees.length,
      itemBuilder: (context, index) {
        final employee = devEmployees[index];
        final assigned = assignedIds.contains(employee.id);
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(employee.fullName),
            subtitle: Text('${employee.role} • ID ${employee.id}'),
            trailing: assigned
                ? OutlinedButton(
                    onPressed: () => onRemove(employee.id),
                    child: const Text('Remove'),
                  )
                : FilledButton(
                    onPressed: () => onAssign(employee.id),
                    child: const Text('Assign'),
                  ),
          ),
        );
      },
    );
  }
}
