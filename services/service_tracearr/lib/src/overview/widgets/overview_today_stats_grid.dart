import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';

/// 2x2 Grid displaying today's fleet statistics (24h pulse).
class OverviewTodayStatsGrid extends StatelessWidget {
  const OverviewTodayStatsGrid({
    required this.todayStatsAsync,
    this.onRetry,
    super.key,
  });

  final AsyncValue<TracearrTodayStats> todayStatsAsync;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S ACTIVITY (24H)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Insets.sm),
        todayStatsAsync.when(
          loading: () => Container(
            height: 140,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: const Center(child: ExpressiveProgressIndicator()),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart, color: colorScheme.error),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Text(
                    'Failed to load 24h summary metrics',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (onRetry != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRetry,
                  ),
              ],
            ),
          ),
          data: (stats) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _StatTile(
                        icon: Icons.play_arrow_outlined,
                        title: '${stats.todayPlays}',
                        subtitle: 'Plays Today',
                        description: '≥ 2 min sessions',
                      ),
                      const SizedBox(height: Insets.sm),
                      _StatTile(
                        icon: Icons.people_outline,
                        title: '${stats.activeUsersToday}',
                        subtitle: 'Active Users',
                        description: 'Unique today',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Column(
                    children: [
                      _StatTile(
                        icon: Icons.schedule_outlined,
                        title: '${stats.watchTimeHours.toStringAsFixed(1)}h',
                        subtitle: 'Watch Time',
                        description: 'Total consumed',
                      ),
                      const SizedBox(height: Insets.sm),
                      _StatTile(
                        icon: Icons.notification_important_outlined,
                        title: '${stats.alertsLast24h}',
                        subtitle: '24h Alerts',
                        description: 'Policy triggers',
                        highlight: stats.alertsLast24h > 0,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.errorContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: highlight
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: highlight ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? colorScheme.error : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
