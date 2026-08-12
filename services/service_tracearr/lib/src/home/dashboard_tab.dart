import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart' show BetaBadge, Insets;
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_api.dart';
import '../tracearr_providers.dart';
import '../widgets/tracearr_session_detail_bottom_sheet.dart';
import '../widgets/tracearr_user_avatar.dart';

class TracearrDashboardTab extends ConsumerStatefulWidget {
  const TracearrDashboardTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<TracearrDashboardTab> createState() => _TracearrDashboardTabState();
}

class _TracearrDashboardTabState extends ConsumerState<TracearrDashboardTab> {
  Future<void> _refresh() async {
    ref.invalidate(tracearrActiveSessionsProvider(widget.instance));
    await ref.read(tracearrActiveSessionsProvider(widget.instance).future);
  }

  void _showSessionDetail(BuildContext context, TracearrV2ActiveStream stream) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(ctx).top + 40,
          ),
          child: TracearrSessionDetailBottomSheet.stream(
            instance: widget.instance,
            stream: stream,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TracearrV2StreamsResponse> asyncStreams =
        ref.watch(tracearrActiveSessionsProvider(widget.instance));

    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Dashboard'),
            if (widget.instance.kind.isBeta) ...<Widget>[
              const SizedBox(width: Insets.sm),
              const BetaBadge(),
            ],
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: EasyRefresh(
        header: const ClassicHeader(),
        onRefresh: _refresh,
        child: asyncStreams.when(
          data: (TracearrV2StreamsResponse data) {
            final TracearrV2StreamsSummary? summary = data.summary;
            final List<TracearrV2ActiveStream> streams = data.data;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                // KPI Cards
                if (summary != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _KpiCard(
                            title: 'Active Streams',
                            value: (summary.total ?? 0).toString(),
                            icon: Icons.play_circle_fill,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            title: 'Total Bandwidth',
                            value: summary.totalBitrate ?? '0 kbps',
                            icon: Icons.wifi,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  'Now Playing',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (streams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.tv_off,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Active Streams',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: streams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final TracearrV2ActiveStream stream = streams[index];
                      return _NowPlayingCard(
                        stream: stream,
                        instance: widget.instance,
                        onTap: () => _showSessionDetail(context, stream),
                      );
                    },
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading dashboard: $error'),
                TextButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends ConsumerWidget {
  const _NowPlayingCard({
    required this.stream,
    required this.instance,
    required this.onTap,
  });

  final TracearrV2ActiveStream stream;
  final Instance instance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String title = stream.mediaTitle ?? 'Unknown Media';
    final String? username = stream.username;
    
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final String? avatarUrl = api?.imageUrl(stream.userAvatarUrl);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: <Widget>[
              // Avatar
              TracearrUserAvatar(
                username: username ?? 'User',
                avatarUrl: avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username != null)
                      Text(
                        username,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (stream.videoDecision != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stream.videoDecision == 'direct play' ||
                            stream.videoDecision == 'direct stream'
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stream.videoDecision == 'direct play' ||
                            stream.videoDecision == 'direct stream'
                        ? 'Direct'
                        : 'Transcode',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: stream.videoDecision == 'direct play' ||
                              stream.videoDecision == 'direct stream'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
