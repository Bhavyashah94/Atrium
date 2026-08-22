import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/tracearr_models.dart';
import '../../../providers/tracearr_providers.dart';
import '../tracearr_media_detail_screen.dart';

/// Accordion view displaying TV seasons and episode breakdown.
class MediaTvHierarchyView extends StatelessWidget {
  const MediaTvHierarchyView({
    required this.children,
    this.instance,
    this.initialSeasonNumber,
    this.initialEpisodeNumber,
    super.key,
  });

  final List<TracearrMediaChild> children;
  final Instance? instance;
  final int? initialSeasonNumber;
  final int? initialEpisodeNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isSeasonsList =
        children.any((c) => c.mediaType.toLowerCase() == 'season');

    if (isSeasonsList) {
      final sortedSeasons = [...children]..sort(
          (a, b) => (a.seasonNumber ?? 0).compareTo(b.seasonNumber ?? 0),
        );

      final int totalEpisodes =
          sortedSeasons.fold(0, (sum, s) => sum + (s.episodeCount ?? 0));

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
                    totalEpisodes > 0
                        ? 'SEASONS (${sortedSeasons.length}) · $totalEpisodes EPISODES'
                        : 'SEASONS (${sortedSeasons.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.sm),
              ...sortedSeasons.map((season) {
                final int seasonNum = season.seasonNumber ?? 1;
                final int epCount = season.episodeCount ?? 0;
                final String titleText = season.title.isNotEmpty &&
                        season.title != 'Season $seasonNum'
                    ? season.title
                    : 'Season $seasonNum';
                final bool isTargetSeason = initialSeasonNumber != null &&
                    seasonNum == initialSeasonNumber;

                if (instance != null && season.id.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Insets.xs),
                    child: Material(
                      color: isTargetSeason
                          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(Radii.sm),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: isTargetSeason,
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: Insets.sm),
                          leading: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTargetSeason
                                  ? colorScheme.primary
                                  : colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              'S$seasonNum',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isTargetSeason
                                    ? colorScheme.onPrimary
                                    : colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            titleText,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '$epCount ${epCount == 1 ? 'Episode' : 'Episodes'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          children: [
                            Consumer(
                              builder: (context, ref, _) {
                                final episodesAsync = ref.watch(
                                  tracearrMediaChildrenProvider(
                                    (instance!, season.id),
                                  ),
                                );

                                return episodesAsync.when(
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(Insets.md),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: ExpressiveProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                  error: (err, _) => Padding(
                                    padding: const EdgeInsets.all(Insets.sm),
                                    child: Text(
                                      'Failed to load episodes for $titleText',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  data: (episodes) {
                                    if (episodes.isEmpty) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.all(Insets.sm),
                                        child: Text(
                                          'No episodes listed',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: episodes.map((ep) {
                                        final bool isTargetEpisode =
                                            isTargetSeason &&
                                                initialEpisodeNumber != null &&
                                                ep.episodeNumber ==
                                                    initialEpisodeNumber;

                                        return Material(
                                          color: isTargetEpisode
                                              ? colorScheme.primaryContainer
                                                  .withValues(alpha: 0.35)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(Radii.sm),
                                          child: Container(
                                            margin: isTargetEpisode
                                                ? const EdgeInsets.symmetric(
                                                    horizontal: Insets.xs,
                                                    vertical: 2,
                                                  )
                                                : null,
                                            decoration: isTargetEpisode
                                                ? BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      Radii.sm,
                                                    ),
                                                    border: Border.all(
                                                      color: colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.5),
                                                    ),
                                                  )
                                                : null,
                                            child: ListTile(
                                              dense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: Insets.md,
                                              ),
                                              leading: Container(
                                                width: 28,
                                                height: 28,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: isTargetEpisode
                                                      ? colorScheme.primary
                                                      : colorScheme
                                                          .surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    Radii.sm,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${ep.episodeNumber ?? 0}',
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isTargetEpisode
                                                        ? colorScheme.onPrimary
                                                        : colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                ep.title,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontWeight: isTargetEpisode
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isTargetEpisode
                                                      ? colorScheme.primary
                                                      : null,
                                                ),
                                              ),
                                              trailing: isTargetEpisode
                                                  ? Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            colorScheme.primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          Radii.sm,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'CURRENT',
                                                        style: theme.textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                          color: colorScheme
                                                              .onPrimary,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.chevron_right,
                                                      size: 16,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              onTap: () {
                                                if (instance != null &&
                                                    ep.id.isNotEmpty) {
                                                  TracearrMediaDetailScreen
                                                      .navigate(
                                                    context,
                                                    instance: instance!,
                                                    mediaRef: ep.id,
                                                    initialTitle: ep.title,
                                                    initialSeasonNumber:
                                                        ep.seasonNumber ??
                                                            seasonNum,
                                                    initialEpisodeNumber:
                                                        ep.episodeNumber,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.xs),
                  child: Material(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: Insets.md),
                      leading: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          'S$seasonNum',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        titleText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        '$epCount ${epCount == 1 ? 'Episode' : 'Episodes'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Group episode children by seasonNumber
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
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        if (instance != null && ep.id.isNotEmpty) {
                          TracearrMediaDetailScreen.navigate(
                            context,
                            instance: instance!,
                            mediaRef: ep.id,
                            initialTitle: ep.title,
                          );
                        }
                      },
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
