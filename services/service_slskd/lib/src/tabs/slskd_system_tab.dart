import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../slskd_providers.dart';
import '../system/slskd_daemon_card.dart';
import '../system/slskd_disk_files_sheet.dart';
import '../system/slskd_logs_view.dart';
import '../system/slskd_options_sheet.dart';
import '../system/slskd_server_card.dart';
import '../system/slskd_shares_view.dart';
import '../system/slskd_user_card.dart';
import '../system/slskd_vpn_card.dart';
import '../transfers/slskd_analytics_sheet.dart';

/// Tab 4: System & Health — Soulseek connection health, user stats, daemon controls, local shares, and live logs.
class SlskdSystemTab extends ConsumerStatefulWidget {
  const SlskdSystemTab({
    required this.instance,
    this.onOpenDrawer,
    super.key,
  });

  final Instance instance;
  final VoidCallback? onOpenDrawer;

  @override
  ConsumerState<SlskdSystemTab> createState() => _SlskdSystemTabState();
}

class _SlskdSystemTabState extends ConsumerState<SlskdSystemTab> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final stateAsync = ref.watch(slskdApplicationStateProvider(widget.instance));
    final activeSegment = ref.watch(slskdSystemSegmentProvider(widget.instance));

    ref.listen<int>(
      slskdScrollToTopProvider((widget.instance, 4)),
      (previous, next) {
        if (next > 0 && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text('System & Health'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh system info',
            onPressed: () {
              ref.invalidate(slskdApplicationStateProvider(widget.instance));
              ref.invalidate(slskdSharesProvider(widget.instance));
              ref.invalidate(slskdLogsProvider(widget.instance));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String val) {
              if (val == 'analytics') {
                SlskdAnalyticsSheet.show(context, instance: widget.instance);
              } else if (val == 'storage') {
                SlskdDiskFilesSheet.show(context, instance: widget.instance);
              } else if (val == 'options') {
                SlskdOptionsSheet.show(context, instance: widget.instance);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics_outlined),
                  title: Text('Transfer analytics & KPIs'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'storage',
                child: ListTile(
                  leading: Icon(Icons.folder_open_rounded),
                  title: Text('Host storage explorer'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'options',
                child: ListTile(
                  leading: Icon(Icons.settings_suggest_rounded),
                  title: Text('Configuration & diagnostics'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(slskdApplicationStateProvider(widget.instance));
          ref.invalidate(slskdSharesProvider(widget.instance));
          ref.invalidate(slskdLogsProvider(widget.instance));
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.sm,
                Insets.md,
                Insets.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Health'),
                      icon: Icon(Icons.health_and_safety_rounded, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Shares'),
                      icon: Icon(Icons.folder_shared_rounded, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 2,
                      label: Text('Logs'),
                      icon: Icon(Icons.article_rounded, size: 18),
                    ),
                  ],
                  selected: <int>{activeSegment},
                  onSelectionChanged: (Set<int> newSelection) {
                    ref
                        .read(
                          slskdSystemSegmentProvider(widget.instance).notifier,
                        )
                        .state = newSelection.first;
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                0,
                Insets.md,
                Insets.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: stateAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Insets.xl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: Insets.sm),
                          Text(
                            'Failed to load system state',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: Insets.xs),
                          Text(
                            '$error',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (state) {
                    if (activeSegment == 0) {
                      // Health & Status
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SlskdServerCard(
                            instance: widget.instance,
                            server: state.server,
                            watchdog: state.connectionWatchdog,
                          ),
                          const SizedBox(height: Insets.sm),
                          SlskdUserCard(user: state.user),
                          const SizedBox(height: Insets.sm),
                          SlskdDaemonCard(
                            instance: widget.instance,
                            version: state.version,
                          ),
                          if (state.vpn != null) ...<Widget>[
                            const SizedBox(height: Insets.sm),
                            SlskdVpnCard(vpn: state.vpn!),
                          ],
                        ],
                      );
                    } else if (activeSegment == 1) {
                      // Shares
                      return SlskdSharesView(
                        instance: widget.instance,
                        sharesState: state.shares,
                      );
                    } else {
                      // Logs
                      return SlskdLogsView(instance: widget.instance);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
