import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../school/shared/repositories/schools_repository.dart';

class SchoolInfoSheet extends ConsumerWidget {
  const SchoolInfoSheet({
    super.key,
    required this.school,
  });

  final SchoolCoordinates school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(school.geocodeStatus).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  color: _getStatusColor(school.geocodeStatus),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.schoolName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(school.geocodeStatus),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),

          if (school.geocodeStatus == 'APPROXIMATE') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí ước lượng',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tọa độ được ước lượng từ vị trí trung tâm xã. Vị trí thực tế có thể khác.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          _buildInfoRow(context, Icons.location_on_outlined, 'Địa chỉ', school.fullAddress),
          if (school.address.isNotEmpty)
            _buildInfoRow(context, Icons.home_outlined, 'Địa chỉ chi tiết', school.address),
          _buildInfoRow(context, Icons.map_outlined, 'Tọa độ',
            school.hasCoordinates
              ? '${school.latitude!.toStringAsFixed(5)}, ${school.longitude!.toStringAsFixed(5)}'
              : 'Chưa có'
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/schools/${school.schoolUid}');
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Xem chi tiết'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/map?schools=${school.schoolUid}');
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Chỉ đường'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'FULL':
        return Colors.green;
      case 'APPROXIMATE':
        return Colors.orange;
      case 'PENDING':
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = status == 'FULL' ? 'Chính xác'
        : status == 'APPROXIMATE' ? 'Ước lượng'
        : 'Chưa xác định';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSchoolInfoSheet(BuildContext context, SchoolCoordinates school) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SchoolInfoSheet(school: school),
  );
}
