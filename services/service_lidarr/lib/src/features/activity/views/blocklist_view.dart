import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Blocklisted releases view with individual and bulk remove actions.
class BlocklistView extends ConsumerStatefulWidget {
  const BlocklistView({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<BlocklistView> createState() => _BlocklistViewState();
}

class _BlocklistViewState extends ConsumerState<BlocklistView> {
  Future<void> _removeBlocklistItem(BlocklistResource item) async {
    final int? id = item.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove from Blocklist?'),
        content: Text(
          'Remove "${item.sourceTitle ?? 'Release'}" from blocklist so Lidarr may grab it again?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<void> resp =
          await api.blocklist.deleteBlocklistById(id: id);

      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? 'Failed to remove from blocklist',
        );
      }

      ref.invalidate(lidarrBlocklistProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed release from blocklist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearAllBlocklist(List<BlocklistResource> items) async {
    if (items.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear Blocklist?'),
        content: Text(
          'Remove all ${items.length} blocklisted releases? Lidarr will be able to grab these releases again.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Blocklist'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final List<int> ids = items
          .where((BlocklistResource i) => i.id != null)
          .map((BlocklistResource i) => i.id!)
          .toList();
      final ApiResponse<void> resp = await api.blocklist.deleteBlocklistBulk(
        body: BlocklistBulkResource(ids: ids),
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to clear blocklist');
      }

      ref.invalidate(lidarrBlocklistProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${ids.length} releases from blocklist'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showBlocklistDetails(BlocklistResource item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          final ThemeData theme = Theme.of(context);
          final ColorScheme cs = theme.colorScheme;

          return Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              title: const Text('Blocklisted Release'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Remove from Blocklist',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _removeBlocklistItem(item);
                  },
                ),
              ],
            ),
            body: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  item.sourceTitle ?? 'Blocklisted Release',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.artist?.artistName != null) ...[
                  Text(
                    'Artist: ${item.artist!.artistName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildDetailRow(
                          'Indexer',
                          item.indexer ?? '--',
                          context,
                        ),
                        const Divider(height: 12),
                        _buildDetailRow(
                          'Protocol',
                          item.protocol?.value.toUpperCase() ?? '--',
                          context,
                        ),
                        const Divider(height: 12),
                        _buildDetailRow(
                          'Date Blocklisted',
                          item.date != null
                              ? LidarrFormatters.formatRelativeDate(item.date)
                              : '--',
                          context,
                        ),
                        if (item.quality?.quality?.name != null) ...[
                          const Divider(height: 12),
                          _buildDetailRow(
                            'Quality',
                            item.quality!.quality!.name!,
                            context,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (item.message != null && item.message!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reason / Message',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        item.message!,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<List<BlocklistResource>> asyncBlocklist =
        ref.watch(lidarrBlocklistProvider(widget.instance));
    final String filterQuery =
        ref.watch(lidarrActivitySearchQueryProvider(widget.instance));
    final Set<int> selection =
        ref.watch(lidarrBlocklistSelectionProvider(widget.instance));

    return asyncBlocklist.when(
      data: (List<BlocklistResource> rawBlocklist) {
        List<BlocklistResource> blocklist = rawBlocklist;

        if (filterQuery.trim().isNotEmpty) {
          final String q = filterQuery.trim().toLowerCase();
          blocklist = blocklist.where((BlocklistResource item) {
            final String title = (item.sourceTitle ?? '').toLowerCase();
            final String artist = (item.artist?.artistName ?? '').toLowerCase();
            final String indexer = (item.indexer ?? '').toLowerCase();
            final String message = (item.message ?? '').toLowerCase();
            return title.contains(q) ||
                artist.contains(q) ||
                indexer.contains(q) ||
                message.contains(q);
          }).toList();
        }

        if (blocklist.isEmpty) {
          return EasyRefresh(
            onRefresh: () async {
              ref.invalidate(lidarrBlocklistProvider(widget.instance));
            },
            child: Center(
              child: EmptyView(
                icon: Icons.block,
                title: rawBlocklist.isEmpty
                    ? 'Blocklist is empty'
                    : 'No matches found',
                message: rawBlocklist.isEmpty
                    ? 'No blocklisted releases found.'
                    : 'No blocklisted items matching your search query.',
              ),
            ),
          );
        }

        return EasyRefresh(
          onRefresh: () async {
            ref.invalidate(lidarrBlocklistProvider(widget.instance));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: <Widget>[
              if (rawBlocklist.isNotEmpty && selection.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${blocklist.length} ${blocklist.length == 1 ? 'release' : 'releases'}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Tooltip(
                        message: 'Clear Blocklist',
                        child: TextButton.icon(
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                          ),
                          label: const Text('Clear Blocklist'),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.error,
                          ),
                          onPressed: () => _clearAllBlocklist(rawBlocklist),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final item in blocklist)
                _buildBlocklistCard(
                  item,
                  theme,
                  cs,
                  isSelected: item.id != null && selection.contains(item.id!),
                  isSelecting: selection.isNotEmpty,
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text('Failed to load blocklist: $error'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () =>
                  ref.invalidate(lidarrBlocklistProvider(widget.instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlocklistCard(
    BlocklistResource item,
    ThemeData theme,
    ColorScheme cs, {
    required bool isSelected,
    required bool isSelecting,
  }) {
    final String protocolStr = (item.protocol?.name ?? 'release').toUpperCase();
    final String dateStr = LidarrFormatters.formatRelativeDate(item.date);

    void toggleSelection() {
      if (item.id == null) return;
      final notifier =
          ref.read(lidarrBlocklistSelectionProvider(widget.instance).notifier);
      final Set<int> sel =
          ref.read(lidarrBlocklistSelectionProvider(widget.instance));
      if (isSelected) {
        notifier.state = sel.difference(<int>{item.id!});
      } else {
        notifier.state = <int>{...sel, item.id!};
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelecting) {
            toggleSelection();
          } else {
            _showBlocklistDetails(item);
          }
        },
        onLongPress: toggleSelection,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isSelecting) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => toggleSelection(),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.block, color: cs.error, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.sourceTitle ?? 'Blocklisted Release',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (item.artist?.artistName != null) ...[
                      Text(
                        item.artist!.artistName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            protocolStr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.onErrorContainer,
                            ),
                          ),
                        ),
                        if (item.indexer != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.indexer!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (item.message != null && item.message!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.message!,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.error,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isSelecting)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Remove from Blocklist',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeBlocklistItem(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
