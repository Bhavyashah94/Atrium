import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import 'aria2_add_sheet.dart';
import 'aria2_api.dart';
import 'aria2_download_detail_screen.dart';
import 'aria2_format.dart';
import 'aria2_providers.dart';
import 'aria2_speed_dialog.dart';
import 'models/aria2_download.dart';
import 'models/aria2_snapshot.dart';

/// Which list of the daemon's downloads the screen is showing.
enum _Aria2Filter {
  active('Active'),
  waiting('Queued'),
  stopped('Stopped');

  const _Aria2Filter(this.label);

  final String label;
}

/// aria2's per-instance UI: the download lists, the daemon's totals and the
/// controls that act on all of them at once.
class Aria2Home extends ConsumerStatefulWidget {
  const Aria2Home({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<Aria2Home> createState() => _Aria2HomeState();
}

class _Aria2HomeState extends ConsumerState<Aria2Home> {
  _Aria2Filter _filter = _Aria2Filter.active;

  void _refresh(WidgetRef ref) {
    ref.invalidate(aria2SnapshotProvider(widget.instance));
  }

  /// Runs a daemon command and reports what happened.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(Aria2Api api) action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final Aria2Api api = await ref.read(
        aria2ApiProvider(widget.instance).future,
      );
      await action(api);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Action failed: $e')));
    } finally {
      if (context.mounted) {
        _refresh(ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Aria2Snapshot> snapshot = ref.watch(
      aria2SnapshotProvider(widget.instance),
    );
    return AsyncValueView<Aria2Snapshot>(
      value: snapshot,
      onRetry: () => _refresh(ref),
      data: (Aria2Snapshot data) {
        final List<Aria2Download> downloads = switch (_filter) {
          _Aria2Filter.active => data.active,
          _Aria2Filter.waiting => data.waiting,
          _Aria2Filter.stopped => data.stopped,
        };
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.md,
                Insets.lg,
                Insets.sm,
              ),
              child: _SummaryCard(
                snapshot: data,
                onPauseAll: () =>
                    _run(context, ref, (Aria2Api api) => api.pauseAll()),
                onResumeAll: () =>
                    _run(context, ref, (Aria2Api api) => api.unpauseAll()),
                onSpeedLimit: () => _showSpeedLimit(context, ref),
                onAdd: () => showAria2AddSheet(context, widget.instance),
              ),
            ),
            _FilterBar(
              filter: _filter,
              counts: <_Aria2Filter, int>{
                _Aria2Filter.active: data.active.length,
                _Aria2Filter.waiting: data.waiting.length,
                _Aria2Filter.stopped: data.stopped.length,
              },
              onChanged: (_Aria2Filter value) =>
                  setState(() => _filter = value),
            ),
            Expanded(
              child: EasyRefresh(
                header: const ClassicHeader(),
                onRefresh: () async => _refresh(ref),
                child: downloads.isEmpty
                    ? ListView(
                        padding: Insets.page,
                        children: <Widget>[
                          const SizedBox(height: Insets.xl),
                          EmptyView(
                            icon: switch (_filter) {
                              _Aria2Filter.active =>
                                Icons.download_done_outlined,
                              _Aria2Filter.waiting => Icons.schedule,
                              _Aria2Filter.stopped => Icons.history,
                            },
                            title: switch (_filter) {
                              _Aria2Filter.active => 'Nothing downloading',
                              _Aria2Filter.waiting => 'Queue is empty',
                              _Aria2Filter.stopped => 'Nothing stopped yet',
                            },
                            message: switch (_filter) {
                              _Aria2Filter.active =>
                                'Add a download to get aria2 working.',
                              _Aria2Filter.waiting =>
                                'Downloads waiting to start show up here.',
                              _Aria2Filter.stopped =>
                                'Finished, failed and removed downloads land here.',
                            },
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: Insets.page,
                        itemCount: downloads.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Aria2Download download = downloads[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: Insets.sm),
                            child: _DownloadCard(
                              download: download,
                              onTap: () => pushScreen<void>(
                                context,
                                Aria2DownloadDetailScreen(
                                  instance: widget.instance,
                                  gid: download.gid,
                                  initialName: download.displayName,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSpeedLimit(BuildContext context, WidgetRef ref) async {
    final Map<String, String>? options = ref
        .read(aria2GlobalOptionsProvider(widget.instance))
        .value;
    final int current =
        int.tryParse(options?['max-overall-download-limit'] ?? '') ?? 0;
    final int? kb = await showAria2SpeedDialog(
      context,
      currentKb: current ~/ 1024,
    );
    if (kb == null || !context.mounted) {
      return;
    }
    await _run(
      context,
      ref,
      (Aria2Api api) => api.setGlobalDownloadLimit(kb * 1024),
    );
    ref.invalidate(aria2GlobalOptionsProvider(widget.instance));
  }
}

/// The daemon's own totals, with the controls that act on everything.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.snapshot,
    required this.onPauseAll,
    required this.onResumeAll,
    required this.onSpeedLimit,
    required this.onAdd,
  });

  final Aria2Snapshot snapshot;
  final VoidCallback onPauseAll;
  final VoidCallback onResumeAll;
  final VoidCallback onSpeedLimit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Material(
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
                  child: _Metric(
                    icon: Icons.arrow_downward_rounded,
                    value: aria2FmtRate(snapshot.stat.downloadSpeed),
                    label: 'Download',
                    color: cs.primary,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    icon: Icons.arrow_upward_rounded,
                    value: aria2FmtRate(snapshot.stat.uploadSpeed),
                    label: 'Upload',
                    color: cs.tertiary,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    icon: Icons.info_outline,
                    value: snapshot.version.version.isEmpty
                        ? '-'
                        : snapshot.version.version,
                    label: 'aria2',
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
                if (snapshot.active.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: onPauseAll,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause all'),
                  )
                else if (snapshot.hasPaused)
                  OutlinedButton.icon(
                    onPressed: onResumeAll,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume all'),
                  ),
                OutlinedButton.icon(
                  onPressed: onSpeedLimit,
                  icon: const Icon(Icons.speed),
                  label: const Text('Speed limit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One headline number with its label.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The three list filters, with the size of each list beside its name.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.counts,
    required this.onChanged,
  });

  final _Aria2Filter filter;
  final Map<_Aria2Filter, int> counts;
  final ValueChanged<_Aria2Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        children: <Widget>[
          for (final _Aria2Filter option in _Aria2Filter.values)
            Padding(
              padding: const EdgeInsets.only(right: Insets.sm),
              child: ChoiceChip(
                label: Text('${option.label} (${counts[option] ?? 0})'),
                selected: option == filter,
                onSelected: (_) => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

/// One download: its name, what it is doing, and how far along it is.
class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.download, required this.onTap});

  final Aria2Download download;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int? eta = download.etaSeconds;
    final String sizes =
        '${aria2FmtBytes(download.completedLength)} / ${aria2FmtBytes(download.totalLength)}';
    final String details = <String>[
      aria2StatusLabel(download.status),
      sizes,
      if (download.downloadSpeed > 0) aria2FmtRate(download.downloadSpeed),
      if (download.uploadSpeed > 0) aria2FmtRate(download.uploadSpeed),
      if (eta != null) '${aria2FormatEta(eta)} left',
    ].join(' - ');
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (download.isError)
                    Icon(Icons.error_outline, color: cs.error, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
