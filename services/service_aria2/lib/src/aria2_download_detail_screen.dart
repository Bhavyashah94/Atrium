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
import 'models/aria2_peer.dart';

/// One download, in full: its progress, its files, its sources, connected peers,
/// per-download speed limits, and interactive management.
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

  Future<void> _editSpeedLimit(
    BuildContext context,
    WidgetRef ref,
    Aria2Download download,
  ) async {
    Map<String, String> options = const <String, String>{};
    try {
      final Aria2Api api = await ref.read(aria2ApiProvider(instance).future);
      options = await api.getOption(gid);
    } catch (_) {
      options =
          ref.read(aria2DownloadOptionProvider((instance, gid))).value ??
          const <String, String>{};
    }
    final int currentDl =
        int.tryParse(options['max-download-limit'] ?? '') ?? 0;
    final int currentUl = int.tryParse(options['max-upload-limit'] ?? '') ?? 0;

    if (!context.mounted) return;

    final ({int dlKb, int ulKb})? result =
        await showDialog<({int dlKb, int ulKb})>(
          context: context,
          builder: (BuildContext ctx) => _TaskSpeedDialog(
            initialDlKb: currentDl ~/ 1024,
            initialUlKb: currentUl ~/ 1024,
          ),
        );

    if (result != null && context.mounted) {
      await _run(
        context,
        ref,
        (Aria2Api api) => api.changeOption(gid, <String, String>{
          'max-download-limit': '${result.dlKb * 1024}',
          'max-upload-limit': '${result.ulKb * 1024}',
        }),
      );
    }
  }

  Future<void> _addMirrorUri(
    BuildContext context,
    WidgetRef ref,
    int fileIndex,
  ) async {
    final TextEditingController urlController = TextEditingController();
    final String? newUrl = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Add Mirror URI'),
        content: TextField(
          controller: urlController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://mirror.host/file.zip',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(urlController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newUrl != null && newUrl.isNotEmpty && context.mounted) {
      await _run(
        context,
        ref,
        (Aria2Api api) =>
            api.changeUri(gid, fileIndex, addUris: <String>[newUrl]),
      );
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
            instance: instance,
            download: data,
            onAction: (Future<void> Function(Aria2Api api) action) =>
                _run(context, ref, action),
            onSpeedLimit: () => _editSpeedLimit(context, ref, data),
            onAddMirror: (int fileIndex) =>
                _addMirrorUri(context, ref, fileIndex),
          );
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.instance,
    required this.download,
    required this.onAction,
    required this.onSpeedLimit,
    required this.onAddMirror,
  });

  final Instance instance;
  final Aria2Download download;
  final Future<void> Function(Future<void> Function(Aria2Api api) action)
  onAction;
  final VoidCallback onSpeedLimit;
  final void Function(int fileIndex) onAddMirror;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int? eta = download.etaSeconds;

    final double seedRatio = download.completedLength > 0
        ? download.uploadLength / download.completedLength
        : 0.0;

    final AsyncValue<List<Aria2Peer>> peersAsync =
        download.torrentName.isNotEmpty || download.infoHash.isNotEmpty
        ? ref.watch(aria2PeersProvider((instance, download.gid)))
        : const AsyncValue<List<Aria2Peer>>.data(<Aria2Peer>[]);

    return ListView(
      padding: Insets.page,
      children: <Widget>[
        // Main Overview Card
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
                      download.isComplete
                          ? '100%'
                          : '${(download.progress * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: download.isComplete ? cs.tertiary : cs.primary,
                        fontWeight: FontWeight.bold,
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
                    activeColor: download.isComplete
                        ? cs.tertiary
                        : download.isPaused
                        ? cs.outline
                        : cs.primary,
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
                if (download.uploadLength > 0)
                  _Row(
                    label: 'Uploaded',
                    value: aria2FmtBytes(download.uploadLength),
                  ),
                if (download.torrentName.isNotEmpty ||
                    download.infoHash.isNotEmpty)
                  _Row(
                    label: 'Seed Ratio',
                    value: '${seedRatio.toStringAsFixed(2)}x',
                  ),
                if (eta != null && !download.isStopped)
                  _Row(label: 'Remaining', value: aria2FormatEta(eta)),
                if (download.connections > 0)
                  _Row(label: 'Connections', value: '${download.connections}'),
                if (download.numSeeders > 0)
                  _Row(label: 'Seeders', value: '${download.numSeeders}'),
                if (download.dir.isNotEmpty)
                  _Row(label: 'Folder', value: download.dir),
                if (download.infoHash.isNotEmpty)
                  _Row(label: 'InfoHash', value: download.infoHash),
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

        // Action Buttons Row
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
                onPressed: onSpeedLimit,
                icon: const Icon(Icons.speed),
                label: const Text('Speed limit'),
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

        // Files Section with Interactive Selection Checkboxes
        if (download.files.isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Row(
            children: <Widget>[
              Text(
                'Files (${download.files.length})',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              if (download.isLive && download.files.length > 1)
                Text(
                  'Tap checkbox to include/exclude',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: download.files.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1),
              itemBuilder: (BuildContext ctx, int index) {
                final Aria2File file = download.files[index];
                return ListTile(
                  leading: download.isLive && download.files.length > 1
                      ? Checkbox(
                          value: file.selected,
                          onChanged: (bool? checked) {
                            if (checked == null) return;
                            // aria2 select-file is 1-based indices comma-separated
                            final List<int> selectedIndices = <int>[];
                            for (int i = 0; i < download.files.length; i++) {
                              final Aria2File f = download.files[i];
                              final bool isSelected = i == index
                                  ? checked
                                  : f.selected;
                              if (isSelected) {
                                selectedIndices.add(
                                  f.index > 0 ? f.index : i + 1,
                                );
                              }
                            }
                            final String selectString = selectedIndices.join(
                              ',',
                            );
                            onAction(
                              (Aria2Api api) => api.changeOption(
                                download.gid,
                                <String, String>{'select-file': selectString},
                              ),
                            );
                          },
                        )
                      : Icon(
                          file.selected
                              ? Icons.check_circle_outline
                              : Icons.remove_circle_outline,
                          size: 20,
                          color: file.selected ? cs.primary : cs.outline,
                        ),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${aria2FmtBytes(file.completedLength)} of ${aria2FmtBytes(file.length)}',
                  ),
                  trailing: Text(
                    '${(file.progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Connected BitTorrent Peers
        peersAsync.when(
          data: (List<Aria2Peer> peers) {
            if (peers.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: Insets.lg),
                Text(
                  'Connected Peers (${peers.length})',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Insets.sm),
                Material(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: peers.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(height: 1),
                    itemBuilder: (BuildContext ctx, int index) {
                      final Aria2Peer peer = peers[index];
                      return ListTile(
                        leading: Icon(
                          peer.seeder ? Icons.verified : Icons.devices,
                          color: peer.seeder ? cs.tertiary : cs.primary,
                        ),
                        title: Text(
                          peer.clientName.isEmpty ? peer.ip : peer.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${peer.ip}:${peer.port}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            if (peer.downloadSpeed > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 12,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    aria2FmtRate(peer.downloadSpeed),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            if (peer.uploadSpeed > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 12,
                                    color: cs.tertiary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    aria2FmtRate(peer.uploadSpeed),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            if (peer.downloadSpeed == 0 &&
                                peer.uploadSpeed == 0)
                              Text(
                                peer.seeder ? 'Seeder' : 'Peer',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stackTrace) =>
              const SizedBox.shrink(),
        ),

        // Sources & Mirrors Section
        if (download.files
            .expand((Aria2File f) => f.uris)
            .isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.lg),
          Row(
            children: <Widget>[
              Text('Sources & Mirrors', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (download.isLive)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Mirror'),
                  onPressed: () => onAddMirror(1),
                ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: <Widget>[
                for (final Aria2Uri uri in download.files.expand(
                  (Aria2File f) => f.uris,
                ))
                  ListTile(
                    leading: const Icon(Icons.link, size: 20),
                    title: Text(
                      uri.uri,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: uri.status.isEmpty
                        ? null
                        : Text('Status: ${uri.status}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskSpeedDialog extends StatefulWidget {
  const _TaskSpeedDialog({
    required this.initialDlKb,
    required this.initialUlKb,
  });

  final int initialDlKb;
  final int initialUlKb;

  @override
  State<_TaskSpeedDialog> createState() => _TaskSpeedDialogState();
}

class _TaskSpeedDialogState extends State<_TaskSpeedDialog> {
  late final TextEditingController _dlController = TextEditingController(
    text: widget.initialDlKb > 0 ? '${widget.initialDlKb}' : '',
  );
  late final TextEditingController _ulController = TextEditingController(
    text: widget.initialUlKb > 0 ? '${widget.initialUlKb}' : '',
  );

  @override
  void dispose() {
    _dlController.dispose();
    _ulController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Task speed limits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _dlController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Download limit (KB/s)',
              helperText: '0 or empty for unlimited',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _ulController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Upload limit (KB/s)',
              helperText: '0 or empty for unlimited',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final int dl = int.tryParse(_dlController.text.trim()) ?? 0;
            final int ul = int.tryParse(_ulController.text.trim()) ?? 0;
            Navigator.of(context).pop((dlKb: dl, ulKb: ul));
          },
          child: const Text('Save'),
        ),
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
