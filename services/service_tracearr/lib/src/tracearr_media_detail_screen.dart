import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart' hide EasyRefresh, ClassicHeader, HeaderLocator;
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';
import 'tracearr_providers.dart';
import 'tracearr_user_detail_screen.dart';
import 'utils/tracearr_formatters.dart';
import 'widgets/tracearr_user_avatar.dart';

/// Gold-standard Tracearr 2.0 media detail screen matching Sonarr/Radarr Atrium design architecture.
/// Unifies all child items (seasons/episodes/tracks) onto the root parent Show/Movie with full fanart backdrop,
/// high-res poster, theme-driven Season Heatmap accordions, inline episode lists, episode detail bottom sheets,
/// Overview & Stats, Watchers, History timeline, EasyRefresh, and scroll FAB.
class TracearrV2MediaDetailScreen extends ConsumerStatefulWidget {
  const TracearrV2MediaDetailScreen({
    required this.instance,
    required this.mediaRef,
    super.key,
  });

  final Instance instance;
  final String mediaRef;

  @override
  ConsumerState<TracearrV2MediaDetailScreen> createState() =>
      _TracearrV2MediaDetailScreenState();
}

class _TracearrV2MediaDetailScreenState
    extends ConsumerState<TracearrV2MediaDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showBackToTop = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final double threshold = MediaQuery.sizeOf(context).height * 0.4;
    if (_scrollController.hasClients &&
        _scrollController.offset >= threshold) {
      if (!_showBackToTop.value) {
        _showBackToTop.value = true;
      }
    } else {
      if (_showBackToTop.value) {
        _showBackToTop.value = false;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _showBackToTop.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(
      tracearrV2GetMediaByRefProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );
    ref.invalidate(
      tracearrV2GetMediaChildrenProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );
    ref.invalidate(
      tracearrV2GetMediaStatsProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );
    ref.invalidate(
      tracearrV2GetMediaWatchersProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );
    ref.invalidate(
      tracearrV2GetMediaHistoryProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch initial targeted media resource
    final AsyncValue<TracearrV2MediaResource?> asyncInitialMedia = ref.watch(
      tracearrV2GetMediaByRefProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );

    return asyncInitialMedia.when(
      data: (TracearrV2MediaResource? initialMedia) {
        if (initialMedia == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Media Details')),
            body: const Center(child: Text('Media resource not found.')),
          );
        }

        // 2. Automatic Root Resolution: If initial item is a child, resolve root Show ID
        final String? initialId = initialMedia.id;
        final String? showId = initialMedia.showMediaId;
        final String rootRef = (showId != null && showId.isNotEmpty) ? showId : (initialId ?? widget.mediaRef);

        // If rootRef is different from initialRef, watch the Root Show
        final AsyncValue<TracearrV2MediaResource?> asyncRootMedia =
            rootRef != initialId
                ? ref.watch(
                    tracearrV2GetMediaByRefProvider(
                      (instance: widget.instance, ref: rootRef),
                    ),
                  )
                : asyncInitialMedia;

        return asyncRootMedia.when(
          data: (TracearrV2MediaResource? rootMedia) {
            final TracearrV2MediaResource displayMedia =
                rootMedia ?? initialMedia;

            final Map<String, String> serverMap =
                ref.watch(tracearrServerNamesMapProvider(widget.instance));
            final TracearrApi? api =
                ref.watch(tracearrApiProvider(widget.instance)).value;

            final bool isShow = displayMedia.mediaType == 'show' ||
                displayMedia.seasonCount != null;
            final String activeMediaRef = displayMedia.id ?? widget.mediaRef;

            // Pre-watch sub-resource providers at root level to maintain active listeners
            // while the screen is open, preventing autoDispose eviction and scroll reload flickers.
            if (isShow) {
              ref.watch(
                tracearrV2GetMediaChildrenProvider(
                  (instance: widget.instance, ref: activeMediaRef),
                ),
              );
            }
            ref.watch(
              tracearrV2GetMediaStatsProvider(
                (instance: widget.instance, ref: activeMediaRef),
              ),
            );
            ref.watch(
              tracearrV2GetMediaWatchersProvider(
                (instance: widget.instance, ref: activeMediaRef),
              ),
            );
            ref.watch(
              tracearrV2GetMediaHistoryProvider(
                (instance: widget.instance, ref: activeMediaRef),
              ),
            );

            final String title = displayMedia.title ?? 'Untitled Media';
            String? backdropUrl = api?.imageUrl(displayMedia.thumbPath);
            String? posterUrl = api?.imageUrl(
              displayMedia.posterUrl ?? displayMedia.thumbPath,
            );

            if (displayMedia.availability.isNotEmpty) {
              for (final TracearrV2MediaAvailability item in displayMedia.availability) {
                final String? rKey = item.ratingKey;
                final String? sId = item.serverId;
                final String? sType = item.serverType;
                if (rKey != null && rKey.isNotEmpty && sId != null && sId.isNotEmpty) {
                  if (posterUrl == null) {
                    final String path = sType == 'plex'
                        ? '/api/v1/images/proxy?server=$sId&url=${Uri.encodeComponent('/library/metadata/$rKey/thumb')}'
                        : '/api/v1/images/proxy?server=$sId&url=${Uri.encodeComponent('/Items/$rKey/Images/Primary')}';
                    posterUrl = api?.imageUrl(path);
                  }
                  if (backdropUrl == null) {
                    final String path = sType == 'plex'
                        ? '/api/v1/images/proxy?server=$sId&url=${Uri.encodeComponent('/library/metadata/$rKey/art')}'
                        : '/api/v1/images/proxy?server=$sId&url=${Uri.encodeComponent('/Items/$rKey/Images/Backdrop')}';
                    backdropUrl = api?.imageUrl(path);
                  }
                  if (posterUrl != null && backdropUrl != null) break;
                }
              }
            }

            final ThemeData theme = Theme.of(context);

            return Scaffold(
              floatingActionButton: ValueListenableBuilder<bool>(
                valueListenable: _showBackToTop,
                builder: (BuildContext context, bool show, Widget? child) {
                  return AnimatedOpacity(
                    opacity: show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Visibility(
                      visible: show,
                      child: FloatingActionButton.small(
                        heroTag: 'tracearr_media_detail_back_to_top',
                        onPressed: () {
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Icon(Icons.arrow_upward),
                      ),
                    ),
                  );
                },
              ),
              body: EasyRefresh(
                header: const ClassicHeader(
                  position: IndicatorPosition.locator,
                ),
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverAppBar(
                      expandedHeight: 250.0,
                      pinned: true,
                      backgroundColor: theme.colorScheme.surface,
                      surfaceTintColor: theme.colorScheme.surfaceTint,
                      leading: _AppBarLeading(controller: _scrollController),
                      actions: <Widget>[
                        _AppBarActions(
                          controller: _scrollController,
                          onRefresh: _refresh,
                          media: displayMedia,
                        ),
                      ],
                      title: CollapsedTitle(
                        controller: _scrollController,
                        title: title,
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: _BackdropHeader(
                          backdropUrl: backdropUrl,
                          posterUrl: posterUrl,
                          title: title,
                        ),
                      ),
                    ),
                    const HeaderLocator.sliver(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          <Widget>[
                            // Hero Info Card (Poster, Type, Release Year, External Links)
                            _HeroInfoCard(
                              media: displayMedia,
                              posterUrl: posterUrl,
                            ),
                            const SizedBox(height: 20),

                            // Server Availability Breakdown Card
                            _ServerAvailabilitySection(
                              availability: displayMedia.availability,
                              serverMap: serverMap,
                            ),
                            const SizedBox(height: 20),

                            // Metrics Summary Bar
                            _MediaMetricsSummaryRow(
                              instance: widget.instance,
                              mediaRef: displayMedia.id ?? widget.mediaRef,
                            ),
                            const SizedBox(height: 24),

                            // Seasons & Episodes Section (for TV Shows)
                            if (isShow) ...<Widget>[
                              _MediaChildrenSection(
                                instance: widget.instance,
                                rootMedia: displayMedia,
                                initialMedia: initialMedia,
                                serverMap: serverMap,
                                api: api,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Watchers Section (Preview with Quick Jump)
                            _MediaWatchersPreviewSection(
                              instance: widget.instance,
                              mediaRef: displayMedia.id ?? widget.mediaRef,
                            ),
                            const SizedBox(height: 24),

                            // Playback History Section (Preview with Quick Jump)
                            _MediaHistoryPreviewSection(
                              instance: widget.instance,
                              mediaRef: displayMedia.id ?? widget.mediaRef,
                              serverMap: serverMap,
                              api: api,
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Loading Parent Show...')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (Object e, StackTrace s) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(e.toString())),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading Details...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace s) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(e.toString()),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ---------------------------------------------------------------------------
// Sonarr-Style AppBar Floating Leading Back Button
// ---------------------------------------------------------------------------

class _AppBarLeading extends StatefulWidget {
  const _AppBarLeading({required this.controller});

  final ScrollController controller;

  @override
  State<_AppBarLeading> createState() => _AppBarLeadingState();
}

class _AppBarLeadingState extends State<_AppBarLeading> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(covariant _AppBarLeading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final double offset = widget.controller.offset;
    const double expandedHeight = 250.0;
    const double collapseThreshold = expandedHeight - kToolbarHeight;
    final double newProgress = (offset / collapseThreshold).clamp(0.0, 1.0);
    if (newProgress != _progress) {
      setState(() {
        _progress = newProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color iconColor = Color.lerp(Colors.white, cs.onSurface, _progress)!;
    final double bubbleOpacity = (1.0 - _progress).clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35 * bubbleOpacity),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: iconColor),
          onPressed: () => Navigator.of(context).maybePop(),
          padding: EdgeInsets.zero,
          tooltip: 'Back',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sonarr-Style AppBar Action Buttons
// ---------------------------------------------------------------------------

class _AppBarActions extends StatefulWidget {
  const _AppBarActions({
    required this.controller,
    required this.onRefresh,
    required this.media,
  });

  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final TracearrV2MediaResource media;

  @override
  State<_AppBarActions> createState() => _AppBarActionsState();
}

class _AppBarActionsState extends State<_AppBarActions> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(covariant _AppBarActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final double offset = widget.controller.offset;
    const double expandedHeight = 250.0;
    const double collapseThreshold = expandedHeight - kToolbarHeight;
    final double newProgress = (offset / collapseThreshold).clamp(0.0, 1.0);
    if (newProgress != _progress) {
      setState(() {
        _progress = newProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color iconColor = Color.lerp(Colors.white, cs.onSurface, _progress)!;
    final double bubbleOpacity = (1.0 - _progress).clamp(0.0, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35 * bubbleOpacity),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, size: 20, color: iconColor),
            onPressed: widget.onRefresh,
            padding: EdgeInsets.zero,
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sonarr-Style Dual Scrim Backdrop Header Widget
// ---------------------------------------------------------------------------

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({
    required this.backdropUrl,
    required this.posterUrl,
    required this.title,
  });

  final String? backdropUrl;
  final String? posterUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasBackdrop = backdropUrl != null && backdropUrl!.trim().isNotEmpty;
    final bool hasPoster = posterUrl != null && posterUrl!.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (hasBackdrop)
          CachedNetworkImage(
            imageUrl: backdropUrl!,
            fit: BoxFit.cover,
            memCacheWidth: 1080,
            errorWidget: (_, __, ___) => _buildPosterFallback(cs),
          )
        else if (hasPoster)
          _buildPosterFallback(cs)
        else
          Container(
            color: cs.surfaceContainerHigh,
            child: Icon(
              Icons.movie_outlined,
              size: 64,
              color: cs.onSurfaceVariant,
            ),
          ),
        // Top-down dark scrim for status bar and action icons contrast
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.45],
            ),
          ),
        ),
        // Scrim so title stays legible and fanart image melts into surface
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                cs.surface.withValues(alpha: 0.0),
                cs.surface.withValues(alpha: 0.6),
                cs.surface,
              ],
              stops: const <double>[0.3, 0.75, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterFallback(ColorScheme cs) {
    if (posterUrl != null && posterUrl!.trim().isNotEmpty) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: CachedNetworkImage(
          imageUrl: posterUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 720,
          errorWidget: (_, __, ___) => Container(
            color: cs.surfaceContainerHigh,
            child: Icon(
              Icons.movie_outlined,
              size: 64,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Container(
      color: cs.surfaceContainerHigh,
      child: Icon(
        Icons.movie_outlined,
        size: 64,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Info Card Widget
// ---------------------------------------------------------------------------

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard({
    required this.media,
    required this.posterUrl,
  });

  final TracearrV2MediaResource media;
  final String? posterUrl;

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? yearText = media.year?.toString();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // High-Resolution Poster Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 105,
                height: 155,
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.movie_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Metadata & External Links
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    media.title ?? 'Untitled',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (yearText != null || media.genres.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        if (yearText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              yearText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ...media.genres.map((String genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // IMDb / TMDB / TVDb Action Badges (Horizontal compact layout)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (media.imdbId != null &&
                          media.imdbId!.trim().isNotEmpty)
                        _ExternalLinkBadge(
                          label: 'IMDb',
                          onTap: () => _launchExternalUrl(
                            'https://www.imdb.com/title/${media.imdbId}/',
                          ),
                        ),
                      if (media.tmdbId != null)
                        _ExternalLinkBadge(
                          label: 'TMDB',
                          onTap: () => _launchExternalUrl(
                            'https://www.themoviedb.org/${media.mediaType == "movie" ? "movie" : "tv"}/${media.tmdbId}',
                          ),
                        ),
                      if (media.tvdbId != null)
                        _ExternalLinkBadge(
                          label: 'TVDB',
                          onTap: () => _launchExternalUrl(
                            'https://thetvdb.com/search?query=${media.tvdbId}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalLinkBadge extends StatelessWidget {
  const _ExternalLinkBadge({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Server Availability Section Widget
// ---------------------------------------------------------------------------

class _ServerAvailabilitySection extends StatelessWidget {
  const _ServerAvailabilitySection({
    required this.availability,
    required this.serverMap,
  });

  final List<TracearrV2MediaAvailability> availability;
  final Map<String, String> serverMap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (availability.isEmpty) {
      return Card(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Text('No server availability recorded.'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Server Availability',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...availability.map((TracearrV2MediaAvailability item) {
          final String serverDisplayName = resolveServerName(
            serverMap: serverMap,
            serverId: item.serverId,
            serverType: item.serverType,
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.dns_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                serverDisplayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: item.libraryId != null
                  ? Text('Library ID: ${item.libraryId}')
                  : null,
              trailing: Chip(
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.secondaryContainer,
                side: BorderSide.none,
                label: Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Media Metrics Summary Row Widget
// ---------------------------------------------------------------------------

class _MediaMetricsSummaryRow extends ConsumerStatefulWidget {
  const _MediaMetricsSummaryRow({
    required this.instance,
    required this.mediaRef,
  });

  final Instance instance;
  final String mediaRef;

  @override
  ConsumerState<_MediaMetricsSummaryRow> createState() =>
      __MediaMetricsSummaryRowState();
}

class __MediaMetricsSummaryRowState extends ConsumerState<_MediaMetricsSummaryRow> {
  String _selectedWindow = 'all_time';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2MediaStatsResponse?> asyncStats = ref.watch(
      tracearrV2GetMediaStatsProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );

    return asyncStats.when(
      data: (TracearrV2MediaStatsResponse? stats) {
        final Map<String, dynamic>? windows = stats?.windows;
        if (windows == null || windows.isEmpty) {
          return const SizedBox.shrink();
        }

        final Map<String, dynamic>? windowData =
            windows[_selectedWindow] as Map<String, dynamic>?;
        final Map<String, dynamic>? combined = windowData != null
            ? (windowData['combined'] as Map<String, dynamic>?)
            : null;

        final int totalPlays = (combined?['plays'] as num?)?.toInt() ?? 0;
        final int uniqueWatchers = (combined?['unique_users'] as num?)?.toInt() ??
            (combined?['users'] as num?)?.toInt() ??
            0;
        final int durationMs = (combined?['watch_time_ms'] as num?)?.toInt() ??
            (combined?['duration_ms'] as num?)?.toInt() ??
            0;
        final String totalDurationText = formatTracearrWatchTime(durationMs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Viewing Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Map<String, String>>[
                      <String, String>{'key': 'all_time', 'label': 'All Time'},
                      <String, String>{'key': 'last_30', 'label': '30 Days'},
                      <String, String>{'key': 'last_7', 'label': '7 Days'},
                    ].map((item) {
                      final String key = item['key']!;
                      final String label = item['label']!;
                      final bool isSelected = _selectedWindow == key;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                _selectedWindow = key;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricTile(
                    icon: Icons.play_arrow_outlined,
                    label: 'Plays',
                    value: '$totalPlays',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.people_outline,
                    label: 'Watchers',
                    value: '$uniqueWatchers',
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: totalDurationText.isNotEmpty ? totalDurationText : '0m',
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media Watchers Preview Section (Top 3 Watchers + Quick Jump)
// ---------------------------------------------------------------------------

class _MediaWatchersPreviewSection extends ConsumerWidget {
  const _MediaWatchersPreviewSection({
    required this.instance,
    required this.mediaRef,
  });

  final Instance instance;
  final String mediaRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2MediaWatchersResponse> asyncWatchers = ref.watch(
      tracearrV2GetMediaWatchersProvider(
        (instance: instance, ref: mediaRef),
      ),
    );
    final Map<String, String> avatarMap =
        ref.watch(tracearrUserAvatarsMapProvider(instance));
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;

    return asyncWatchers.when(
      data: (TracearrV2MediaWatchersResponse data) {
        final List<TracearrV2Watcher> watchers = data.watchers;
        if (watchers.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<TracearrV2Watcher> previewWatchers =
            watchers.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Watchers (${watchers.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (watchers.length > 3)
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        builder: (BuildContext ctx) => DraggableScrollableSheet(
                          initialChildSize: 0.7,
                          maxChildSize: 0.95,
                          minChildSize: 0.4,
                          expand: false,
                          builder: (_, ScrollController controller) {
                            return _AllWatchersBottomSheet(
                              instance: instance,
                              watchers: watchers,
                              avatarMap: avatarMap,
                              api: api,
                              scrollController: controller,
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('See All ›'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...previewWatchers.map((TracearrV2Watcher watcher) {
              final String username = watcher.user?.username ?? 'Unknown User';
              final String? userId = watcher.user?.userId;
              final String? rawAvatarPath =
                  userId != null ? avatarMap[userId] : null;
              final String? avatarUrl = api?.imageUrl(rawAvatarPath);
              final int plays = watcher.plays ?? 0;
              final String watchTimeText =
                  formatTracearrWatchTime(watcher.watchTimeMs);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: theme.colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: TracearrUserAvatar(
                    username: username,
                    avatarUrl: avatarUrl,
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$plays ${plays == 1 ? "play" : "plays"}${watchTimeText.isNotEmpty ? " • $watchTimeText" : ""}',
                  ),
                  onTap: userId != null
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TracearrV2UserDetailScreen(
                                instance: instance,
                                userId: userId,
                              ),
                            ),
                          )
                      : null,
                ),
              );
            }),
          ],
        );
      },
      loading: () => _buildSectionSkeleton(theme, 'Watchers'),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// Media History Preview Section (Top 4 History Items + Quick Jump)
// ---------------------------------------------------------------------------

class _MediaHistoryPreviewSection extends ConsumerWidget {
  const _MediaHistoryPreviewSection({
    required this.instance,
    required this.mediaRef,
    required this.serverMap,
    required this.api,
  });

  final Instance instance;
  final String mediaRef;
  final Map<String, String> serverMap;
  final TracearrApi? api;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2HistoryResponse> asyncHistory = ref.watch(
      tracearrV2GetMediaHistoryProvider(
        (instance: instance, ref: mediaRef),
      ),
    );

    return asyncHistory.when(
      data: (TracearrV2HistoryResponse history) {
        final List<TracearrV2HistoryRecord> items = history.data;
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<TracearrV2HistoryRecord> previewItems =
            items.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Play History (${items.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (items.length > 4)
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        builder: (BuildContext ctx) => DraggableScrollableSheet(
                          initialChildSize: 0.75,
                          maxChildSize: 0.95,
                          minChildSize: 0.4,
                          expand: false,
                          builder: (_, ScrollController controller) {
                            return _AllHistoryBottomSheet(
                              historyRecords: items,
                              serverMap: serverMap,
                              scrollController: controller,
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('See All ›'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...previewItems.map((TracearrV2HistoryRecord record) {
              final String username = record.effectiveUsername ?? 'User';
              final String formattedTime = formatTracearrTimestamp(
                record.startedAt ?? record.stoppedAt,
              );
              final bool completed = record.effectiveCompleted;
              final double percent = record.percentComplete ??
                  ((record.progressMs != null &&
                          record.totalDurationMs != null &&
                          record.totalDurationMs! > 0)
                      ? (record.progressMs! / record.totalDurationMs! * 100)
                      : (completed ? 100.0 : 0.0));
              final String percentText =
                  percent > 0 ? '${percent.toStringAsFixed(0)}%' : '';

              final String subtitleText = <String>[
                username,
                if (formattedTime.isNotEmpty) formattedTime,
                if (percentText.isNotEmpty) percentText,
              ].join(' • ');

              final String seasonEpTag = formatTracearrSeasonEpisode(
                record.seasonNumber,
                record.episodeNumber,
              );
              final String rawTitle =
                  record.mediaTitle ?? record.showTitle ?? 'Playback Session';
              final String displayTitle = seasonEpTag.isNotEmpty
                  ? '$seasonEpTag • $rawTitle'
                  : rawTitle;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: theme.colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      completed ? Icons.check_circle : Icons.play_arrow,
                      color: completed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                  title: Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    subtitleText,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => _buildSectionSkeleton(theme, 'Play History'),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

Widget _buildSectionSkeleton(ThemeData theme, String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Container(
          width: 120,
          height: 18,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          height: 64,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// All Watchers Full Bottom Sheet
// ---------------------------------------------------------------------------

class _AllWatchersBottomSheet extends StatelessWidget {
  const _AllWatchersBottomSheet({
    required this.instance,
    required this.watchers,
    required this.avatarMap,
    required this.api,
    required this.scrollController,
  });

  final Instance instance;
  final List<TracearrV2Watcher> watchers;
  final Map<String, String> avatarMap;
  final TracearrApi? api;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'All Watchers (${watchers.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: watchers.length,
              itemBuilder: (BuildContext context, int index) {
                final TracearrV2Watcher watcher = watchers[index];
                final String username =
                    watcher.user?.username ?? 'Unknown User';
                final String? userId = watcher.user?.userId;
                final String? rawAvatarPath =
                    userId != null ? avatarMap[userId] : null;
                final String? avatarUrl = api?.imageUrl(rawAvatarPath);
                final int plays = watcher.plays ?? 0;
                final String watchTimeText =
                    formatTracearrWatchTime(watcher.watchTimeMs);
                final double percent = watcher.completionPct ?? 0;
                final String percentText =
                    percent > 0 ? '${percent.toStringAsFixed(0)}%' : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: TracearrUserAvatar(
                      username: username,
                      avatarUrl: avatarUrl,
                    ),
                    title: Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      <String>[
                        '$plays ${plays == 1 ? "play" : "plays"}',
                        if (watchTimeText.isNotEmpty) watchTimeText,
                        if (percentText.isNotEmpty) percentText,
                        if (watcher.distinctEpisodesWatched != null &&
                            watcher.distinctEpisodesWatched! > 0)
                          '${watcher.distinctEpisodesWatched} episodes',
                      ].join(' • '),
                    ),
                    onTap: userId != null
                        ? () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TracearrV2UserDetailScreen(
                                  instance: instance,
                                  userId: userId,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All History Timeline Full Bottom Sheet
// ---------------------------------------------------------------------------

class _AllHistoryBottomSheet extends StatelessWidget {
  const _AllHistoryBottomSheet({
    required this.historyRecords,
    required this.serverMap,
    required this.scrollController,
  });

  final List<TracearrV2HistoryRecord> historyRecords;
  final Map<String, String> serverMap;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Play History Timeline (${historyRecords.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: historyRecords.length,
              itemBuilder: (BuildContext context, int index) {
                final TracearrV2HistoryRecord record = historyRecords[index];
                final String username = record.effectiveUsername ?? 'User';
                final String formattedTime = formatTracearrTimestamp(
                  record.startedAt ?? record.stoppedAt,
                );
                final bool completed = record.effectiveCompleted;
                final String serverDisplayName = resolveServerName(
                  serverMap: serverMap,
                  serverName: record.serverName,
                  serverId: record.serverId,
                  serverType: record.serverType,
                );

                final double percent = record.percentComplete ??
                    ((record.progressMs != null &&
                            record.totalDurationMs != null &&
                            record.totalDurationMs! > 0)
                        ? (record.progressMs! / record.totalDurationMs! * 100)
                        : (completed ? 100.0 : 0.0));
                final String percentText =
                    percent > 0 ? '${percent.toStringAsFixed(0)}%' : '';

                final String subtitleText = <String>[
                  username,
                  serverDisplayName,
                  if (formattedTime.isNotEmpty) formattedTime,
                  if (percentText.isNotEmpty) percentText,
                ].join(' • ');

                final String seasonEpTag = formatTracearrSeasonEpisode(
                  record.seasonNumber,
                  record.episodeNumber,
                );
                final String rawTitle =
                    record.mediaTitle ?? record.showTitle ?? 'Playback Session';
                final String displayTitle = seasonEpTag.isNotEmpty
                    ? '$seasonEpTag • $rawTitle'
                    : rawTitle;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        completed ? Icons.check_circle : Icons.play_arrow,
                        color: completed
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                      ),
                    ),
                    title: Text(
                      displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media Children Section (Sonarr-Style Expandable Season Accordion with Heatmap)
// ---------------------------------------------------------------------------

class _MediaChildrenSection extends ConsumerWidget {
  const _MediaChildrenSection({
    required this.instance,
    required this.rootMedia,
    required this.initialMedia,
    required this.serverMap,
    required this.api,
  });

  final Instance instance;
  final TracearrV2MediaResource rootMedia;
  final TracearrV2MediaResource initialMedia;
  final Map<String, String> serverMap;
  final TracearrApi? api;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? rootId = rootMedia.id;
    if (rootId == null || rootId.isEmpty) {
      return const SizedBox.shrink();
    }

    final AsyncValue<TracearrV2MediaChildrenResponse> asyncChildrenResp = ref.watch(
      tracearrV2GetMediaChildrenProvider(
        (instance: instance, ref: rootId),
      ),
    );

    return asyncChildrenResp.when(
      data: (TracearrV2MediaChildrenResponse resp) {
        final List<TracearrV2MediaChild> seasons = resp.data;
        if (seasons.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No seasons found.')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: seasons.length,
          itemBuilder: (BuildContext context, int index) {
            final TracearrV2MediaChild season = seasons[index];
            final bool isTargetSeason = index == 0;

            return _SeasonAccordionTile(
              instance: instance,
              rootMedia: rootMedia,
              season: season,
              isInitiallyExpanded: isTargetSeason,
              initialTargetMedia: initialMedia,
              api: api,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace s) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Failed to load seasons: $e'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Season Accordion Tile with Theme-Driven Heat-Strip Progress Bar
// ---------------------------------------------------------------------------

class _SeasonAccordionTile extends ConsumerStatefulWidget {
  const _SeasonAccordionTile({
    required this.instance,
    required this.rootMedia,
    required this.season,
    required this.isInitiallyExpanded,
    required this.initialTargetMedia,
    required this.api,
  });

  final Instance instance;
  final TracearrV2MediaResource rootMedia;
  final TracearrV2MediaChild season;
  final bool isInitiallyExpanded;
  final TracearrV2MediaResource initialTargetMedia;
  final TracearrApi? api;

  @override
  ConsumerState<_SeasonAccordionTile> createState() =>
      __SeasonAccordionTileState();
}

class __SeasonAccordionTileState extends ConsumerState<_SeasonAccordionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String seasonTitle = widget.season.title ??
        (widget.season.seasonNumber != null
            ? 'Season ${widget.season.seasonNumber}'
            : 'Season');
    final int epCount = widget.season.episodeCount ?? 0;
    final String? seasonId = widget.season.id;

    // Fetch Season Episodes when expanded
    final AsyncValue<TracearrV2MediaChildrenResponse>? asyncEpisodesResp =
        (_isExpanded && seasonId != null && seasonId.isNotEmpty)
            ? ref.watch(
                tracearrV2GetMediaChildrenProvider(
                  (instance: widget.instance, ref: seasonId),
                ),
              )
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: Icon(
          Icons.video_library_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          seasonTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$epCount ${epCount == 1 ? "Episode" : "Episodes"}',
          style: theme.textTheme.bodySmall,
        ),
        children: <Widget>[
          if (asyncEpisodesResp != null)
            asyncEpisodesResp.when(
              data: (TracearrV2MediaChildrenResponse resp) {
                final List<TracearrV2MediaChild> episodes = resp.data;
                if (episodes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No episodes listed.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: episodes.length,
                  itemBuilder: (BuildContext context, int epIndex) {
                    final TracearrV2MediaChild ep = episodes[epIndex];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          'E${ep.episodeNumber ?? (epIndex + 1)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        ep.title ?? 'Episode ${epIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => TracearrEpisodeDetailBottomSheet(
                            instance: widget.instance,
                            rootMedia: widget.rootMedia,
                            seasonTitle: seasonTitle,
                            episode: ep,
                            api: widget.api,
                            serverMap: ref.read(
                              tracearrServerNamesMapProvider(widget.instance),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, StackTrace s) => Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Failed to load episodes: $e'),
              ),
            ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Enriched Episode Detail Bottom Sheet Widget
// ---------------------------------------------------------------------------

class TracearrEpisodeDetailBottomSheet extends ConsumerWidget {
  const TracearrEpisodeDetailBottomSheet({
    required this.instance,
    required this.rootMedia,
    required this.seasonTitle,
    required this.episode,
    required this.api,
    required this.serverMap,
    super.key,
  });

  final Instance instance;
  final TracearrV2MediaResource rootMedia;
  final String seasonTitle;
  final TracearrV2MediaChild episode;
  final TracearrApi? api;
  final Map<String, String> serverMap;

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String epRef = episode.id ?? '';
    final String showTitle = rootMedia.title ?? 'Show';
    final String epTitle = episode.title ?? 'Episode';
    final String epCode = episode.episodeNumber != null
        ? 'E${episode.episodeNumber}'
        : 'Episode';

    final String? imdbUrl = episode.imdbId != null && episode.imdbId!.isNotEmpty
        ? 'https://www.imdb.com/title/${episode.imdbId}'
        : null;
    final String? tmdbUrl = episode.tmdbId != null && episode.tmdbId! > 0
        ? 'https://www.themoviedb.org/tv/${episode.showMediaId ?? ""}/season/${episode.seasonNumber ?? 1}/episode/${episode.episodeNumber ?? 1}'
        : null;
    final String? tvdbUrl = episode.tvdbId != null && episode.tvdbId! > 0
        ? 'https://thetvdb.com/dereferencer/episode/${episode.tvdbId}'
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    Text(
                      '$showTitle • $seasonTitle',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$epCode - $epTitle',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (imdbUrl != null || tmdbUrl != null || tvdbUrl != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          if (imdbUrl != null)
                            _ExternalLinkBadge(
                              label: 'IMDb',
                              onTap: () => _launchExternalUrl(imdbUrl),
                            ),
                          if (tmdbUrl != null)
                            _ExternalLinkBadge(
                              label: 'TMDB',
                              onTap: () => _launchExternalUrl(tmdbUrl),
                            ),
                          if (tvdbUrl != null)
                            _ExternalLinkBadge(
                              label: 'TVDB',
                              onTap: () => _launchExternalUrl(tvdbUrl),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    if (epRef.isNotEmpty) ...<Widget>[
                      // Episode Specific Stats Row (Plays, Watchers, Watch Duration)
                      _MediaMetricsSummaryRow(
                        instance: instance,
                        mediaRef: epRef,
                      ),
                      const SizedBox(height: 24),

                      // Episode Specific Watchers Section
                      _MediaWatchersPreviewSection(
                        instance: instance,
                        mediaRef: epRef,
                      ),
                      const SizedBox(height: 24),

                      // Episode Specific History Section
                      _MediaHistoryPreviewSection(
                        instance: instance,
                        mediaRef: epRef,
                        serverMap: serverMap,
                        api: api,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




