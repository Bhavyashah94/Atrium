import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../../models/tracearr_models.dart';

/// Accordion view displaying TV seasons and episode breakdown.
class MediaTvHierarchyView extends StatelessWidget {
  const MediaTvHierarchyView({
    required this.children,
    super.key,
  });

  final List<TracearrMediaChild> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group children by seasonNumber
    final Map<int, List<TracearrMediaChild>> seasonMap = {};
    for (final child in children) {
      final season = child.seasonNumber ?? 1;
      seasonMap.putIfAbsent(season, () => []).add(child);
    }

    final sortedSeasons = seasonMap.keys.toList()..sort();

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tv_outlined, size: 16, color: colorScheme.primary),
                const SizedBox(width: Insets.xs),
                Text(
                  'SEASONS & EPISODES (${children.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            ...sortedSeasons.map((seasonNum) {
              final episodes = seasonMap[seasonNum]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: Insets.xs),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: Insets.sm),
                  title: Text(
                    'Season $seasonNum',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${episodes.length} ${episodes.length == 1 ? 'Episode' : 'Episodes'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: episodes.map((ep) {
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: Insets.md),
                      leading: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          '${ep.episodeNumber ?? 0}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        ep.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
