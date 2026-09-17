import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'qbittorrent_providers.dart';

/// The Logs tab for qBittorrent displaying execution logs from `/api/v2/log/main`.
class QbittorrentLogsTab extends ConsumerStatefulWidget {
  const QbittorrentLogsTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<QbittorrentLogsTab> createState() => _QbittorrentLogsTabState();
}

class _QbittorrentLogsTabState extends ConsumerState<QbittorrentLogsTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  QbitLogLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final String query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyAllLogs(List<QbitLogEntry> logs) {
    if (logs.isEmpty) return;
    final String text = logs
        .map(
          (QbitLogEntry e) =>
              '[${e.timeText}] [${e.level.label.toUpperCase()}] ${e.message}',
        )
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${logs.length} log ${logs.length == 1 ? "entry" : "entries"} to clipboard',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLogEntry(QbitLogEntry entry) {
    Clipboard.setData(
      ClipboardData(
        text:
            '[${entry.timeText}] [${entry.level.label.toUpperCase()}] ${entry.message}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log entry copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    // Listen to scroll to top signal from bottom nav tap (index 1 is Logs)
    ref.listen<int>(
      qbitHomeScrollToTopProvider((widget.instance, 1)),
      (_, __) => _scrollToTop(),
    );

    final AsyncValue<List<QbitLogEntry>> logsAsync =
        ref.watch(qbitLogsProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.titleMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            : Text('${widget.instance.name} Logs'),
        actions: <Widget>[
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close search',
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
          else ...<Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search logs',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Copy all logs',
              onPressed: () {
                final List<QbitLogEntry>? currentLogs = logsAsync.value;
                if (currentLogs != null) {
                  final List<QbitLogEntry> filtered = _filterLogs(currentLogs);
                  _copyAllLogs(filtered);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(qbitLogsProvider(widget.instance)),
            ),
          ],
          const SizedBox(width: Insets.xs),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildFilterChips(cs),
          const Divider(height: 1),
          Expanded(
            child: AsyncValueView<List<QbitLogEntry>>(
              value: logsAsync,
              onRetry: () => ref.invalidate(qbitLogsProvider(widget.instance)),
              data: (List<QbitLogEntry> allLogs) {
                final List<QbitLogEntry> filtered = _filterLogs(allLogs);

                if (filtered.isEmpty) {
                  return EmptyView(
                    icon: Icons.article_outlined,
                    title: allLogs.isEmpty
                        ? 'No logs available'
                        : 'No matching logs',
                    message: allLogs.isEmpty
                        ? 'qBittorrent has not reported any log entries yet.'
                        : 'Try changing your search query or level filter.',
                  );
                }

                // Show newest logs at top by reversing the list
                final List<QbitLogEntry> reversed = filtered.reversed.toList();

                return EasyRefresh(
                  header: const ClassicHeader(
                    dragText: 'Pull to refresh',
                    armedText: 'Release ready',
                    readyText: 'Refreshing...',
                    processingText: 'Refreshing...',
                    processedText: 'Succeeded',
                    failedText: 'Failed',
                    messageText: 'Last updated at %T',
                  ),
                  onRefresh: () async {
                    ref.invalidate(qbitLogsProvider(widget.instance));
                    await ref.read(qbitLogsProvider(widget.instance).future);
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.md,
                      vertical: Insets.sm,
                    ),
                    itemCount: reversed.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: cs.outlineVariant.withAlpha(50),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final QbitLogEntry entry = reversed[index];
                      return _LogEntryTile(
                        entry: entry,
                        onTap: () => _copyLogEntry(entry),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<QbitLogEntry> _filterLogs(List<QbitLogEntry> logs) {
    return logs.where((QbitLogEntry e) {
      if (_selectedLevel != null && e.level != _selectedLevel) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return e.message.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.xs,
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: Insets.xs),
            child: FilterChip(
              selected: _selectedLevel == null,
              label: const Text('All'),
              onSelected: (_) => setState(() => _selectedLevel = null),
            ),
          ),
          for (final QbitLogLevel level in QbitLogLevel.values)
            Padding(
              padding: const EdgeInsets.only(right: Insets.xs),
              child: FilterChip(
                selected: _selectedLevel == level,
                label: Text(level.label),
                onSelected: (bool selected) {
                  setState(() => _selectedLevel = selected ? level : null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry, required this.onTap});

  final QbitLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final Color badgeColor = switch (entry.level) {
      QbitLogLevel.critical => cs.error,
      QbitLogLevel.warning => cs.secondary,
      QbitLogLevel.info => cs.tertiary,
      QbitLogLevel.normal => cs.primary,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 58,
              child: Text(
                entry.timeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Insets.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.level.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                entry.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
