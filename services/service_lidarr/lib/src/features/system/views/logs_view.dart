import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_providers.dart';

/// Realtime and historical system logs view with level filtering and pagination.
class LogsView extends ConsumerStatefulWidget {
  const LogsView({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<LogsView> {
  List<LogResource> _logs = [];
  int _currentPage = 1;
  static const int _pageSize = 50;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  String? _levelFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _logs = [];
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final LogResourcePagingResource data = await ref.read(
        lidarrLogsProvider(
          (
            widget.instance,
            page: 1,
            pageSize: _pageSize,
            level: _levelFilter,
          ),
        ).future,
      );

      final List<LogResource> records = data.records ?? [];
      final int totalRecords = data.totalRecords ?? 0;

      if (mounted) {
        setState(() {
          _logs = records;
          _hasMore = _logs.length < totalRecords;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = err;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    try {
      final int nextPage = _currentPage + 1;
      final LogResourcePagingResource data = await ref.read(
        lidarrLogsProvider(
          (
            widget.instance,
            page: nextPage,
            pageSize: _pageSize,
            level: _levelFilter,
          ),
        ).future,
      );

      final List<LogResource> records = data.records ?? [];
      final int totalRecords = data.totalRecords ?? 0;

      if (mounted) {
        setState(() {
          _logs.addAll(records);
          _currentPage = nextPage;
          _hasMore = _logs.length < totalRecords;
        });
      }
    } catch (e) {
      // Soft fail on pagination
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        final ThemeData theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Text(
                  'Filter Logs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('All'),
                trailing: _levelFilter == null ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _levelFilter = null);
                  _loadInitial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Info'),
                trailing:
                    _levelFilter == 'info' ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _levelFilter = 'info');
                  _loadInitial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.warning_amber_outlined),
                title: const Text('Warning'),
                trailing:
                    _levelFilter == 'warn' ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _levelFilter = 'warn');
                  _loadInitial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Error'),
                trailing:
                    _levelFilter == 'error' ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _levelFilter = 'error');
                  _loadInitial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Trace / Debug'),
                trailing:
                    _levelFilter == 'trace' ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _levelFilter = 'trace');
                  _loadInitial();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogDetailDialog(LogResource log) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final theme = Theme.of(ctx);
        final String fullDetails = [
          'Time: ${log.time ?? '--'}',
          'Level: ${log.level?.toUpperCase() ?? '--'}',
          'Logger: ${log.logger ?? '--'}',
          if (log.method != null) 'Method: ${log.method}',
          'Message: ${log.message ?? '--'}',
          if (log.exception != null && log.exception!.isNotEmpty)
            '\nException:\n${log.exception}',
        ].join('\n');

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                log.level?.toLowerCase() == 'error'
                    ? Icons.error_outline
                    : Icons.info_outline,
                color: log.level?.toLowerCase() == 'error'
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  log.logger ?? 'Log Entry',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                fullDetails,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullDetails));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log copied to clipboard')),
                );
              },
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading && _logs.isEmpty) {
      content = const Center(child: ExpressiveProgressIndicator());
    } else if (_error != null && _logs.isEmpty) {
      content = Center(child: Text('Error: $_error'));
    } else if (_logs.isEmpty) {
      content = const Center(
        child: EmptyView(
          icon: Icons.article_outlined,
          title: 'No Log Entries',
          message: 'No logs match the current criteria.',
        ),
      );
    } else {
      content = EasyRefresh(
        onRefresh: _loadInitial,
        onLoad: _loadMore,
        child: ListView.separated(
          padding: const EdgeInsets.all(Insets.md),
          itemCount: _logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (BuildContext context, int index) {
            final LogResource log = _logs[index];
            return _LogEntryTile(
              log: log,
              onTap: () => _showLogDetailDialog(log),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterBottomSheet,
        tooltip: 'Filter Logs',
        child: const Icon(Icons.filter_list),
      ),
      body: content,
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({
    required this.log,
    required this.onTap,
  });

  final LogResource log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String level = log.level ?? 'info';
    final String logger = log.logger ?? '';
    final String message = log.message ?? '';
    final String? exception = log.exception;
    final String timeStr = log.time ?? '';

    Color levelColor;
    switch (level.toLowerCase()) {
      case 'error':
      case 'fatal':
        levelColor = theme.colorScheme.error;
      case 'warn':
      case 'warning':
        levelColor = theme.colorScheme.tertiary;
      case 'debug':
      case 'trace':
        levelColor = theme.colorScheme.onSurfaceVariant;
      default:
        levelColor = theme.colorScheme.primary;
    }

    String timeText = '';
    if (timeStr.isNotEmpty) {
      final DateTime? dt = DateTime.tryParse(timeStr);
      if (dt != null) {
        final DateTime local = dt.toLocal();
        timeText =
            '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: () {
          final String copyText =
              '[$timeText] [$level] $logger: $message${exception != null && exception.isNotEmpty ? '\n$exception' : ''}';
          Clipboard.setData(ClipboardData(text: copyText));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log line copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  timeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logger,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exception != null && exception.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          exception,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
