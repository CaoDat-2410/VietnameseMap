import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Home page shell — reusable wrapper for all role-specific home pages.
/// Wraps AppShellScaffold with a consistent topbar: title, badge, quick actions.
class HomePageShell extends StatelessWidget {
  const HomePageShell({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.actions,
    required this.child,
  });

  final String title;
  final String subtitle;
  final HomeBadge? badge;
  final List<HomeAction>? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topbar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerHighDark
                : AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle.isEmpty
                              ? DateFormat('dd/MM/yyyy').format(DateTime.now())
                              : subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    _BadgeChip(badge: badge!),
                  ],
                ],
              ),

              // Quick actions
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children:
                      actions!.map((a) => _ActionButton(action: a)).toList(),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final HomeBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: badge.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: AppSpacing.iconSm, color: badge.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            badge.label,
            style: TextStyle(
              color: badge.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final HomeAction action;

  @override
  Widget build(BuildContext context) {
    if (action.isPrimary) {
      return FilledButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: AppSpacing.iconSm),
        label: Text(action.label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: AppSpacing.iconSm),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

/// A shared metric layout for role dashboards. Every KPI gets the same height,
/// while columns reflow from one on compact phones to the role-appropriate
/// desktop grid.
class HomeKpiGrid extends StatelessWidget {
  const HomeKpiGrid({
    super.key,
    required this.children,
    this.desktopColumns = 4,
    this.tabletColumns = 2,
    this.cardHeight = 200,
  });

  final List<Widget> children;
  final int desktopColumns;
  final int tabletColumns;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= AppSpacing.breakpointTablet
            ? desktopColumns
            : constraints.maxWidth >= 560
                ? tabletColumns
                : 1;
        final cardWidth =
            (constraints.maxWidth - AppSpacing.bentoGap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: AppSpacing.bentoGap,
          runSpacing: AppSpacing.bentoGap,
          children: [
            for (final child in children)
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

/// Badge descriptor for HomePageShell topbar.
class HomeBadge {
  const HomeBadge({
    required this.label,
    required this.color,
    this.icon = Icons.info_outline,
  });
  final String label;
  final Color color;
  final IconData icon;
}

/// Quick action button descriptor for HomePageShell topbar.
class HomeAction {
  const HomeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
}
