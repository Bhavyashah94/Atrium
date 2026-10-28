import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slskd_system_models.dart';
import '../slskd_api.dart';
import '../slskd_providers.dart';

/// Card displaying slskd daemon version, build status, and daemon control actions (restart/shutdown).
class SlskdDaemonCard extends ConsumerStatefulWidget {
  const SlskdDaemonCard({
    required this.instance,
    required this.version,
    super.key,
  });

  final Instance instance;
  final SlskdVersionState version;

  @override
  ConsumerState<SlskdDaemonCard> createState() => _SlskdDaemonCardState();
}

class _SlskdDaemonCardState extends ConsumerState<SlskdDaemonCard> {
  bool _isActionInProgress = false;

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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionInProgress = true);
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
      final msg = (e is DioException && e.response?.statusCode == 403)
          ? 'Restarting the daemon requires an API key with Administrator role or active JWT session'
          : 'Failed to restart daemon: $e';
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
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

    setState(() => _isActionInProgress = true);
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
      final msg = (e is DioException && e.response?.statusCode == 403)
          ? 'Shutting down the daemon requires an API key with Administrator role or active JWT session'
          : 'Failed to shutdown daemon: $e';
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ref.invalidate(slskdApplicationStateProvider(widget.instance));
      }
    }
  }

  Future<void> _handleCheckUpdate() async {
    setState(() => _isActionInProgress = true);
    try {
      final api = await ref.read(slskdApiProvider(widget.instance).future);
      final version = await api.checkVersion(forceCheck: true);
      if (!mounted) return;
      ref.invalidate(slskdApplicationStateProvider(widget.instance));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            version.isUpdateAvailable == true
                ? 'Update available: ${version.latest}'
                : 'slskd is up to date (${version.current})',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final msg = (e is DioException && e.response?.statusCode == 403)
            ? 'Forcing an update check requires an API key with Administrator or ReadWrite role in slskd.yml'
            : 'Failed to check for updates: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(Insets.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'slskd Daemon',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Version ${widget.version.current}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _isActionInProgress ? null : _handleCheckUpdate,
                  borderRadius: BorderRadius.circular(12),
                  child: Tooltip(
                    message: 'Tap to check for updates',
                    child: widget.version.isUpdateAvailable == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Insets.sm,
                              vertical: Insets.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Update Available',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Insets.sm,
                              vertical: Insets.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Up to date',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: _isActionInProgress ? null : _handleRestart,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Restart Daemon'),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: _isActionInProgress ? null : _handleShutdown,
                    icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                    label: const Text('Shutdown'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
