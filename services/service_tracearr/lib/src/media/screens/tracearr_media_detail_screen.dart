import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/tracearr_providers.dart';
import 'widgets/media_availability_card.dart';
import 'widgets/media_dedicated_history_feed.dart';
import 'widgets/media_tv_hierarchy_view.dart';
import 'widgets/media_watchers_leaderboard.dart';

/// Deep media intelligence detail screen for Tracearr in Atrium.
class TracearrMediaDetailScreen extends ConsumerWidget {
  const TracearrMediaDetailScreen({
    required this.instance,
    required this.mediaRef,
    this.initialTitle,
    this.initialPosterUrl,
    super.key,
  });

  final Instance instance;
  final String mediaRef;
  final String? initialTitle;
  final String? initialPosterUrl;

  static Future<void> navigate(
    BuildContext context, {
    required Instance instance,
    required String mediaRef,
    String? initialTitle,
    String? initialPosterUrl,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TracearrMediaDetailScreen(
          instance: instance,
          mediaRef: mediaRef,
          initialTitle: initialTitle,
          initialPosterUrl: initialPosterUrl,
        ),
      ),
    );
  }

  String _formatWatchTime(int ms) {
    if (ms <= 0) return '0h';
    final double hours = ms / (1000 * 60 * 60);
    return '${hours.toStringAsFixed(1)}h';
  }

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final detailAsync =
        ref.watch(tracearrMediaDetailProvider((instance, mediaRef)));

    return Scaffold(
      body: detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
            title: Text(initialTitle ?? 'Media Detail'),
          ),
          body: const Center(child: ExpressiveProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(
            title: Text(initialTitle ?? 'Media Detail'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 48, color: colorScheme.error),
                  const SizedBox(height: Insets.md),
                  Text(
                    'Failed to load media details',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    err.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Insets.md),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () => ref.invalidate(
                      tracearrMediaDetailProvider((instance, mediaRef)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (detail) {
          final poster = detail.posterUrl ?? initialPosterUrl;

          return CustomScrollView(
            slivers: [
              // Hero Header with Poster Backdrop
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    detail.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 8),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (poster != null && poster.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: poster,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.movie_outlined, size: 48),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.movie_outlined, size: 48),
                          ),
                        ),
                      // Gradient overlay for readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Detail Content Body
              SliverPadding(
                padding: const EdgeInsets.all(Insets.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Metadata and External ID Links
                    Wrap(
                      spacing: Insets.xs,
                      runSpacing: Insets.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (detail.year != null)
                          Chip(
                            label: Text('${detail.year}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        Chip(
                          label: Text(detail.mediaType.toUpperCase()),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        ...detail.genres.map(
                          (genre) => Chip(
                            label: Text(genre),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),

                    // External ID Link Chips
                    if (detail.imdbId != null ||
                        detail.tmdbId != null ||
                        detail.tvdbId != null) ...[
                      Row(
                        children: [
                          if (detail.imdbId != null)
                            Padding(
                              padding: const EdgeInsets.only(right: Insets.xs),
                              child: ActionChip(
                                avatar: const Icon(Icons.link, size: 14),
                                label: const Text('IMDb'),
                                onPressed: () => _openExternalLink(
                                  context,
                                  'https://www.imdb.com/title/${detail.imdbId}',
                                ),
                              ),
                            ),
                          if (detail.tmdbId != null)
                            Padding(
                              padding: const EdgeInsets.only(right: Insets.xs),
                              child: ActionChip(
                                avatar: const Icon(Icons.link, size: 14),
                                label: const Text('TMDb'),
                                onPressed: () => _openExternalLink(
                                  context,
                                  'https://www.themoviedb.org/${detail.mediaType == 'show' ? 'tv' : 'movie'}/${detail.tmdbId}',
                                ),
                              ),
                            ),
                          if (detail.tvdbId != null)
                            ActionChip(
                              avatar: const Icon(Icons.link, size: 14),
                              label: const Text('TheTVDB'),
                              onPressed: () => _openExternalLink(
                                context,
                                'https://thetvdb.com/?tab=series&id=${detail.tvdbId}',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                    ] else
                      const SizedBox(height: Insets.md),

                    // 2. Lifetime Telemetry Stats Grid
                    Container(
                      padding: const EdgeInsets.all(Insets.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          _StatTile(
                            label: 'TOTAL PLAYS',
                            value: '${detail.allTimePlays}',
                            color: colorScheme.primary,
                          ),
                          _StatTile(
                            label: 'WATCH TIME',
                            value: _formatWatchTime(detail.allTimeWatchTimeMs),
                            color: const Color(0xFF4CAF50),
                          ),
                          _StatTile(
                            label: '30D PLAYS',
                            value: '${detail.last30DaysPlays}',
                            color: const Color(0xFF2196F3),
                          ),
                          _StatTile(
                            label: '7D PLAYS',
                            value: '${detail.last7DaysPlays}',
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.lg),

                    // 3. Multi-Server Availability Matrix
                    if (detail.availability.isNotEmpty) ...[
                      MediaAvailabilityCard(
                        instance: instance,
                        availability: detail.availability,
                      ),
                      const SizedBox(height: Insets.lg),
                    ],

                    // 4. Top Watchers Leaderboard
                    if (detail.watchers.isNotEmpty) ...[
                      MediaWatchersLeaderboard(
                        watchers: detail.watchers,
                        instance: instance,
                      ),
                      const SizedBox(height: Insets.lg),
                    ],

                    // 5. TV Hierarchy Accordion (if show)
                    if (detail.children.isNotEmpty) ...[
                      MediaTvHierarchyView(
                        children: detail.children,
                      ),
                      const SizedBox(height: Insets.lg),
                    ],

                    // 6. Dedicated Playback History
                    MediaDedicatedHistoryFeed(
                      instance: instance,
                      mediaRef: mediaRef,
                    ),
                    const SizedBox(height: Insets.xl),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
