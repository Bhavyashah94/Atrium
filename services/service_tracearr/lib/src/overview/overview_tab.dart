import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tracearr_providers.dart';
import 'widgets/overview_activity_chart.dart';
import 'widgets/overview_fleet_health_card.dart';
import 'widgets/overview_live_pulse_card.dart';
import 'widgets/overview_security_alert_banner.dart';
import 'widgets/overview_servers_list.dart';
import 'widgets/overview_today_stats_grid.dart';

/// Main Overview destination for Tracearr service in Atrium.
///
/// Displays fleet health, live operational stream telemetry, 24h summary metrics,
/// 7-day activity trend histogram, connected servers, and unacknowledged alerts.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(tracearrHealthProvider(instance));
    ref.invalidate(tracearrStreamsProvider(instance));
    ref.invalidate(tracearrTodayStatsProvider((instance, null, null)));
    ref.invalidate(tracearrViolationsProvider(instance));
    ref.invalidate(tracearrActivityProvider((instance, 'week', null, null)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final healthAsync = ref.watch(tracearrHealthProvider(instance));
    final streamsAsync = ref.watch(tracearrStreamsProvider(instance));
    final todayStatsAsync =
        ref.watch(tracearrTodayStatsProvider((instance, null, null)));
    final violationsAsync = ref.watch(tracearrViolationsProvider(instance));
    final activityAsync =
        ref.watch(tracearrActivityProvider((instance, 'week', null, null)));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              instance.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Overview',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: EasyRefresh(
        header: const ClassicHeader(
          dragText: 'Pull to refresh',
          armedText: 'Release ready',
          readyText: 'Refreshing telemetry...',
          processingText: 'Refreshing telemetry...',
          processedText: 'Updated',
          failedText: 'Failed',
          messageText: 'Last updated at %T',
        ),
        onRefresh: () => _refreshAll(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          children: [
            // 1. Fleet Health Card
            OverviewFleetHealthCard(
              healthAsync: healthAsync,
              onRetry: () => ref.invalidate(tracearrHealthProvider(instance)),
            ),
            const SizedBox(height: Insets.md),

            // 2. Security Alert Callout (Shown only when unacknowledged violations exist)
            OverviewSecurityAlertBanner(
              violationsAsync: violationsAsync,
              onTap: () {
                // Navigate to Security tab (Index 4)
                ref.read(tracearrActiveTabProvider(instance).notifier).state =
                    4;
              },
            ),

            // 3. Live Pulse (Active Streams & Transcode Breakdown)
            OverviewLivePulseCard(
              streamsAsync: streamsAsync,
              onTap: () {
                // Navigate to Activity tab (Index 1)
                ref.read(tracearrActiveTabProvider(instance).notifier).state =
                    1;
              },
              onRetry: () => ref.invalidate(tracearrStreamsProvider(instance)),
            ),
            const SizedBox(height: Insets.lg),

            // 4. 24-Hour Fleet Summary Grid
            OverviewTodayStatsGrid(
              todayStatsAsync: todayStatsAsync,
              onRetry: () => ref.invalidate(
                tracearrTodayStatsProvider((instance, null, null)),
              ),
            ),
            const SizedBox(height: Insets.lg),

            // 5. 7-Day Activity Trend Chart
            OverviewActivityChart(
              activityAsync: activityAsync,
              onRetry: () => ref.invalidate(
                tracearrActivityProvider((instance, 'week', null, null)),
              ),
            ),
            const SizedBox(height: Insets.lg),

            // 6. Connected Media Servers
            OverviewServersList(
              healthAsync: healthAsync,
              streamsAsync: streamsAsync,
              onTapServer: (serverId) {
                // Navigate to Activity tab (Index 1)
                ref.read(tracearrActiveTabProvider(instance).notifier).state =
                    1;
              },
            ),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}
