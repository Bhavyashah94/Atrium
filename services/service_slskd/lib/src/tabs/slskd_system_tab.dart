import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../slskd_api.dart';
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

  Future<void> _handleRestart() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Restart slskd daemon?'),
        content: const Text(
          'The background daemon will restart. Network transfers and connections will briefly reconnect.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final SlskdApi api =
          await ref.read(slskdApiProvider(widget.instance).future);
      await api.restartApplication();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Restart signal sent to slskd daemon'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      String msg = 'Failed to restart daemon: $e';
      if (e is DioException && e.response?.statusCode == 403) {
        msg = 'Restart requires an API key with Administrator role or active JWT session.';
      }
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        ref.invalidate(slskdApplicationStateProvider(widget.instance));
      }
    }
  }

  Future<void> _handleShutdown() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Shutdown slskd daemon?'),
        content: const Text(
          'This will gracefully shut down the slskd service process. You will need external access (e.g., Docker or systemd) to restart it.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Shutdown'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final SlskdApi api =
          await ref.read(slskdApiProvider(widget.instance).future);
      await api.shutdownApplication();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Shutdown signal sent to slskd daemon'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      String msg = 'Failed to shutdown daemon: $e';
      if (e is DioException && e.response?.statusCode == 403) {
        msg = 'Shutdown requires an API key with Administrator role or active JWT session.';
      }
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        ref.invalidate(slskdApplicationStateProvider(widget.instance));
      }
    }
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
              } else if (val == 'restart') {
                _handleRestart();
              } else if (val == 'shutdown') {
                _handleShutdown();
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
              const PopupMenuItem<String>(
                value: 'restart',
                child: ListTile(
                  leading: Icon(Icons.restart_alt_rounded),
                  title: Text('Restart daemon'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'shutdown',
                child: ListTile(
                  leading: Icon(Icons.power_settings_new_rounded),
                  title: Text('Shutdown daemon'),
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
