import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

/// Bento Card - Grid-based card with multiple size variants
/// Soft Minimalism + Bento Cards design style
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.size = BentoSize.medium,
    this.padding,
    this.accentColor,
    this.showAccent = false,
    this.elevation = 0,
    this.onTap,
  });

  /// Size variants for bento grid layout
  final BentoSize size;

  /// Child widget
  final Widget child;

  /// Custom padding (overrides default)
  final EdgeInsetsGeometry? padding;

  /// Accent color for visual emphasis
  final Color? accentColor;

  /// Show accent bar or indicator
  final bool showAccent;

  /// Elevation level (0-4)
  final double elevation;

  /// Tap callback
  final VoidCallback? onTap;

  /// Get default padding based on size
  EdgeInsetsGeometry get _defaultPadding {
    switch (size) {
      case BentoSize.small:
        return const EdgeInsets.all(AppSpacing.md);
      case BentoSize.medium:
        return const EdgeInsets.all(AppSpacing.base);
      case BentoSize.large:
        return const EdgeInsets.all(AppSpacing.lg);
      case BentoSize.wide:
        return const EdgeInsets.all(AppSpacing.base);
      case BentoSize.xl:
        return const EdgeInsets.all(AppSpacing.xl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = ConstrainedBox(
      constraints: const BoxConstraints.tightForFinite(),
      child: Container(
        padding: padding ?? _defaultPadding,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerHighDark
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: elevation > 0
              ? AppShadows.forTheme(Theme.of(context).brightness, elevation)
              : null,
        ),
        child: child,
      ),
    );

    // Add accent bar if enabled
    if (showAccent && accentColor != null) {
      cardContent = ConstrainedBox(
        constraints: const BoxConstraints.tightForFinite(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerHighDark
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: padding ?? _defaultPadding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Bento grid sizes
enum BentoSize {
  /// 1x1 grid cell
  small,

  /// 1x2 or 2x1 grid cell
  medium,

  /// 2x2 grid cell
  large,

  /// 2x1 grid cell (wide)
  wide,

  /// 2x2+ grid cell (extra large)
  xl,
}

/// Bento Grid - Responsive grid layout for bento cards
class BentoGrid extends StatelessWidget {
  const BentoGrid({
    super.key,
    required this.children,
    this.gap = AppSpacing.bentoGap,
    this.padding,
  });

  /// List of children (can mix BentoCard with different sizes)
  final List<Widget> children;

  /// Gap between cards
  final double gap;

  /// Grid padding
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine columns based on width
        final width = constraints.maxWidth;
        final columns = width >= AppSpacing.breakpointDesktop
            ? 4
            : width >= AppSpacing.breakpointTablet
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          padding: padding ?? EdgeInsets.all(AppSpacing.base),
          childAspectRatio: _getAspectRatio(width, columns),
          children: children.map((child) => child).toList(),
        );
      },
    );
  }

  double _getAspectRatio(double width, int columns) {
    if (width >= AppSpacing.breakpointDesktop) {
      return columns == 4 ? 1.0 : 1.2;
    } else if (width >= AppSpacing.breakpointTablet) {
      return columns == 3 ? 1.0 : 1.1;
    } else {
      return columns == 2 ? 1.0 : 1.1;
    }
  }
}

/// KPI Card - Specialized bento card for dashboard metrics
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.trend,
    this.trendUp = true,
    this.accentColor,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final String? trend;
  final bool trendUp;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? AppColors.primary;

    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accent bar
          Container(
            height: 3,
            width: 32,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: effectiveAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.iconMd,
                  color: effectiveAccent,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color:
                        trendUp ? AppColors.successLight : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: AppSpacing.iconXs,
                        color: trendUp ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trendUp ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Status Chip - Color-coded status badge
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.status,
    this.onTap,
  });

  final String label;
  final StatusType status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(status, isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusColors _getColors(StatusType status, bool isDark) {
    switch (status) {
      case StatusType.active:
        return _StatusColors(
          background: AppColors.successLight,
          dot: AppColors.success,
          text: AppColors.successDark,
        );
      case StatusType.pending:
        return _StatusColors(
          background: AppColors.warningLight,
          dot: AppColors.warning,
          text: AppColors.warningDark,
        );
      case StatusType.draft:
        return _StatusColors(
          background: isDark
              ? AppColors.surfaceContainerHighestDark
              : AppColors.surfaceContainerHighestLight,
          dot:
              isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          text: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        );
      case StatusType.done:
        return _StatusColors(
          background: AppColors.infoLight,
          dot: AppColors.info,
          text: AppColors.infoDark,
        );
      case StatusType.error:
        return _StatusColors(
          background: AppColors.errorLight,
          dot: AppColors.error,
          text: AppColors.errorDark,
        );
    }
  }
}

class _StatusColors {
  final Color background;
  final Color dot;
  final Color text;

  _StatusColors({
    required this.background,
    required this.dot,
    required this.text,
  });
}

/// Status types for StatusChip
enum StatusType {
  active,
  pending,
  draft,
  done,
  error,
}
