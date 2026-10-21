import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import 'aria2_api.dart';
import 'aria2_format.dart';
import 'aria2_providers.dart';
import 'models/aria2_download.dart';
import 'models/aria2_file.dart';

/// One download, in full: its progress, its files, its sources and the
/// commands that act on it.
class Aria2DownloadDetailScreen extends ConsumerWidget {
  const Aria2DownloadDetailScreen({
    required this.instance,
    required this.gid,
    this.initialName = '',
    super.key,
  });

  final Instance instance;
  final String gid;

  /// The name to show before the daemon has answered.
  final String initialName;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(Aria2Api api) action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final Aria2Api api = await ref.read(aria2ApiProvider(instance).future);
      await action(api);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Action failed: $e')));
    } finally {
      if (context.mounted) {
        ref.invalidate(aria2DownloadProvider((instance, gid)));
        ref.invalidate(aria2SnapshotProvider(instance));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Aria2Download?> download = ref.watch(
      aria2DownloadProvider((instance, gid)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          download.value?.displayName ??
              (initialName.isEmpty ? 'Download' : initialName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: AsyncValueView<Aria2Download?>(
        value: download,
        onRetry: () => ref.invalidate(aria2DownloadProvider((instance, gid))),
        data: (Aria2Download? data) {
          if (data == null) {
            return const EmptyView(
              icon: Icons.help_outline,
              title: 'Download is gone',
              message:
                  'The daemon no longer knows this download. It was '
                  'removed and its result purged.',
            );
          }
          return _DetailBody(
            download: data,
            onAction: (Future<void> Function(Aria2Api api) action) =>
                _run(context, ref, action),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.download, required this.onAction});

  final Aria2Download download;
  final Future<void> Function(Future<void> Function(Aria2Api api) action)
  onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int? eta = download.etaSeconds;
    return ListView(
      padding: Insets.page,
      children: <Widget>[
        Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        download.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(download.progress * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicatorM3E(
                    size: LinearProgressM3ESize.s,
                    shape: ProgressM3EShape.flat,
                    value: download.progress,
                    activeColor: download.isPaused ? cs.outline : cs.primary,
                    trackColor: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: Insets.md),
                _Row(label: 'Status', value: aria2StatusLabel(download.status)),
                _Row(
                  label: 'Size',
                  value:
                      '${aria2FmtBytes(download.completedLength)} of '
                      '${aria2FmtBytes(download.totalLength)}',
                ),
                if (download.downloadSpeed > 0)
                  _Row(
                    label: 'Download',
                    value: aria2FmtRate(download.downloadSpeed),
                  ),
                if (download.uploadSpeed > 0)
                  _Row(
                    label: 'Upload',
                    value: aria2FmtRate(download.uploadSpeed),
                  ),
                if (eta != null)
                  _Row(label: 'Remaining', value: aria2FormatEta(eta)),
                if (download.connections > 0)
                  _Row(label: 'Connections', value: '${download.connections}'),
                if (download.torrentName.isNotEmpty)
                  _Row(label: 'Torrent', value: download.torrentName),
                if (download.numSeeders > 0)
                  _Row(label: 'Seeders', value: '${download.numSeeders}'),
                if (download.dir.isNotEmpty)
                  _Row(label: 'Folder', value: download.dir),
                _Row(
                  label: 'GID',
                  value: download.gid,
                  trailing: IconButton(
                    tooltip: 'Copy GID',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: download.gid),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GID copied')),
                        );
                      }
                    },
                  ),
                ),
                if (download.isError && download.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: Insets.sm),
                  Text(
                    download.errorMessage,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.md),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: <Widget>[
            if (download.canPause)
              FilledButton.tonalIcon(
                onPressed: () =>
                    onAction((Aria2Api api) => api.pause(download.gid)),
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
            if (download.canResume)
              FilledButton.tonalIcon(
                onPressed: () =>
                    onAction((Aria2Api api) => api.unpause(download.gid)),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
              ),
            if (download.isLive)
              OutlinedButton.icon(
                onPressed: () =>
                    onAction((Aria2Api api) => api.remove(download.gid)),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            if (download.isStopped)
              OutlinedButton.icon(
                onPressed: () => onAction(
                  (Aria2Api api) => api.removeDownloadResult(download.gid),
                ),
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Clear result'),
              ),
            if (download.isWaiting)
              OutlinedButton.icon(
                onPressed: () => onAction(
                  (Aria2Api api) =>
                      api.changePosition(download.gid, 0, 'POS_SET'),
                ),
                icon: const Icon(Icons.keyboard_arrow_up),
                label: const Text('To top'),
              ),
          ],
        ),
        if (download.files.isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Text('Files', style: theme.textTheme.titleSmall),
          const SizedBox(height: Insets.sm),
          for (final Aria2File file in download.files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                file.selected
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
              ),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${aria2FmtBytes(file.completedLength)} of '
                '${aria2FmtBytes(file.length)}',
              ),
            ),
        ],
        if (download.files
            .expand((Aria2File f) => f.uris)
            .isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Text('Sources', style: theme.textTheme.titleSmall),
          const SizedBox(height: Insets.sm),
          for (final Aria2Uri uri in download.files.expand(
            (Aria2File f) => f.uris,
          )) ...<Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link, size: 20),
              title: Text(
                uri.uri,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: uri.status.isEmpty ? null : Text(uri.status),
            ),
          ],
        ],
      ],
    );
  }
}

/// A label / value line.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
          ?trailing,
        ],
      ),
    );
  }
}
