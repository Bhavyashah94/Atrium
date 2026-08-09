import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_api.dart';
import '../tracearr_providers.dart';
import '../utils/tracearr_formatters.dart';
import '../widgets/tracearr_session_detail_bottom_sheet.dart';
import '../widgets/tracearr_user_avatar.dart';

/// Activity tab displaying active streams, playback metrics, and player details.
class TracearrActivityTab extends ConsumerStatefulWidget {
  const TracearrActivityTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<TracearrActivityTab> createState() => _TracearrActivityTabState();
}

class _TracearrActivityTabState extends ConsumerState<TracearrActivityTab> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TracearrV2StreamsResponse> asyncStreams =
        ref.watch(tracearrV2GetStreamsProvider(widget.instance));

    return EasyRefresh(
      header: const ClassicHeader(
        position: IndicatorPosition.locator,
      ),
      onRefresh: () =>
          ref.refresh(tracearrV2GetStreamsProvider(widget.instance).future),
      child: asyncStreams.when(
        data: (TracearrV2StreamsResponse response) {
          final TracearrV2StreamsSummary? summary = response.summary;
          final List<TracearrV2ActiveStream> allStreams = response.data;

          final List<TracearrV2ActiveStream> filteredStreams = allStreams.where((TracearrV2ActiveStream s) {
            if (_searchQuery.isEmpty) return true;
            final String query = _searchQuery.toLowerCase();
            final String title = (s.mediaTitle ?? s.effectiveShowTitle ?? '').toLowerCase();
            final String user = (s.effectiveUsername ?? '').toLowerCase();
            final String player = (s.effectivePlayer ?? '').toLowerCase();
            return title.contains(query) || user.contains(query) || player.contains(query);
          }).toList();

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: true,
                leading: Builder(
                  builder: (BuildContext ctx) {
                    final ScaffoldState? scaffold =
                        Scaffold.maybeOf(ctx);
                    if (scaffold?.hasDrawer ?? false) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => scaffold?.openDrawer(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (String val) =>
                            setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search active streams...',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _isSearching = false;
                              });
                            },
                          ),
                        ),
                      )
                    : const Text('Activity'),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    tooltip: _isSearching ? 'Close Search' : 'Search',
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _searchController.clear();
                          _searchQuery = '';
                          _isSearching = false;
                        } else {
                          _isSearching = true;
                        }
                      });
                    },
                  ),
                ],
              ),
              const HeaderLocator.sliver(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      _StreamsSummaryBanner(summary: summary),
                    ],
                  ),
                ),
              ),
              if (filteredStreams.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.play_disabled_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allStreams.isEmpty ? 'No Active Streams' : 'No Matching Streams',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allStreams.isEmpty
                              ? 'Nothing is currently playing on this server.'
                              : 'Try adjusting your search query.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _ActiveStreamCard(
                          instance: widget.instance,
                          stream: filteredStreams[index],
                        );
                      },
                      childCount: filteredStreams.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load streams: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(tracearrV2GetStreamsProvider(widget.instance)),
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

class _StreamsSummaryBanner extends StatelessWidget {
  const _StreamsSummaryBanner({required this.summary});

  final TracearrV2StreamsSummary? summary;

  @override
  Widget build(BuildContext context) {
    final int total = summary?.total ?? 0;
    final int direct = summary?.directPlays ?? 0;
    final int transcodes = summary?.transcodes ?? 0;
    final String rawBitrate = summary?.totalBitrate ?? '';
    final String formattedBitrate;
    if (rawBitrate.isNotEmpty && rawBitrate != '—') {
      formattedBitrate = rawBitrate;
    } else {
      final int bitrate = int.tryParse(rawBitrate) ?? 0;
      formattedBitrate = bitrate > 1000
          ? '${(bitrate / 1000).toStringAsFixed(1)} Mbps'
          : (bitrate > 0 ? '$bitrate Kbps' : '—');
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _StatTile(
            icon: Icons.play_circle_filled,
            label: 'Total Streams',
            value: '$total',
            color: Theme.of(context).colorScheme.primary,
          ),
          _StatTile(
            icon: Icons.play_arrow,
            label: 'Direct Play',
            value: '$direct',
            color: Theme.of(context).colorScheme.tertiary,
          ),
          _StatTile(
            icon: Icons.transform,
            label: 'Transcode',
            value: '$transcodes',
            color: Theme.of(context).colorScheme.secondary,
          ),
          _StatTile(
            icon: Icons.speed,
            label: 'Bitrate',
            value: formattedBitrate,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ActiveStreamCard extends ConsumerWidget {
  const _ActiveStreamCard({
    required this.instance,
    required this.stream,
  });

  final Instance instance;
  final TracearrV2ActiveStream stream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));
    final String? posterUrl = api?.imageUrl(stream.posterUrl);
    final String username = stream.effectiveUsername ?? 'Unknown User';
    final String? userAvatarUrl = api?.imageUrl(stream.userAvatarUrl);
    final String serverDisplayName = resolveServerName(
      serverMap: serverMap,
      serverName: stream.serverName,
      serverId: stream.serverId,
      serverType: stream.serverType,
    );
    final String title = stream.mediaTitle ?? stream.effectiveShowTitle ?? 'Playing';
    final int progress = stream.progressMs ?? 0;
    final int duration = stream.durationMs ?? 1;
    final double percent = (progress / duration).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          TracearrSessionDetailBottomSheet.showStream(
            context,
            instance: instance,
            stream: stream,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (posterUrl != null)
                  SizedBox(
                    width: 90,
                    height: 135,
                    child: CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.movie, size: 36),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            TracearrUserAvatar(
                              username: username,
                              avatarUrl: userAvatarUrl,
                              radius: 12,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                username,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Chip(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              label: Text(
                                (stream.state ?? 'playing').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (stream.showTitle != null && stream.seasonNumber != null)
                          Text(
                            '${stream.showTitle} • S${stream.seasonNumber}E${stream.episodeNumber}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: <Widget>[
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(Icons.dns, size: 12),
                              label: Text(
                                serverDisplayName,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            if (stream.effectivePlayer != null)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(Icons.devices, size: 12),
                                label: Text(
                                  stream.effectivePlayer!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            if (stream.resolution != null)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  stream.resolution!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            if (stream.isTranscode != null)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: stream.isTranscode!
                                    ? Theme.of(context).colorScheme.secondaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                                label: Text(
                                  stream.isTranscode! ? 'Transcode' : 'Direct Play',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}
