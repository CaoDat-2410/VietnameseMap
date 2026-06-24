import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class UserRoleChip extends StatelessWidget {
  const UserRoleChip({super.key, required this.role});

  final String role;

  Color get _color {
    switch (role) {
      case 'ADMIN':
        return AppColors.error;
      case 'MANAGER':
        return AppColors.warning;
      case 'STAFF':
        return AppColors.info;
      case 'STUDENT':
        return AppColors.success;
      default:
        return AppColors.textTertiaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(role, style: const TextStyle(fontSize: 12)),
      backgroundColor: _color.withValues(alpha: 0.1),
      side: BorderSide(color: _color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class UserStatusChip extends StatelessWidget {
  const UserStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Chip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? AppColors.success : AppColors.warning,
        ),
      ),
      backgroundColor:
          isActive ? AppColors.successLight : AppColors.warningLight,
      side: BorderSide(color: isActive ? AppColors.success : AppColors.warning),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
