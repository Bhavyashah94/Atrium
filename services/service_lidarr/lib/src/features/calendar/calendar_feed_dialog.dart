import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../lidarr_providers.dart';
import '../settings/providers/settings_providers.dart';

/// Displays a dialog to configure, export, and subscribe to the iCal / ICS calendar feed.
Future<void> showLidarrCalendarFeedDialog(
  BuildContext context, {
  required Instance instance,
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => _CalendarFeedDialog(instance: instance),
  );
}

class _CalendarFeedDialog extends ConsumerStatefulWidget {
  const _CalendarFeedDialog({required this.instance});

  final Instance instance;

  @override
  ConsumerState<_CalendarFeedDialog> createState() =>
      _CalendarFeedDialogState();
}

class _CalendarFeedDialogState extends ConsumerState<_CalendarFeedDialog> {
  final TextEditingController _pastDaysController =
      TextEditingController(text: '7');
  final TextEditingController _futureDaysController =
      TextEditingController(text: '28');
  bool _unmonitored = false;

  @override
  void dispose() {
    _pastDaysController.dispose();
    _futureDaysController.dispose();
    super.dispose();
  }

  String _buildFeedUrl(String apiKey) {
    final String base = widget.instance.localUrl.isNotEmpty
        ? widget.instance.localUrl
        : widget.instance.externalUrl;
    final String pastDays = _pastDaysController.text.trim();
    final String futureDays = _futureDaysController.text.trim();

    final List<String> params = [
      'apikey=$apiKey',
      if (pastDays.isNotEmpty) 'pastDays=$pastDays',
      if (futureDays.isNotEmpty) 'futureDays=$futureDays',
      if (_unmonitored) 'unmonitored=true',
    ];

    return '$base/feed/v1/calendar/lidarr.ics?${params.join('&')}';
  }

  Future<void> _subscribeInCalendar(String feedUrl) async {
    final String webcalUrl =
        feedUrl.replaceFirst(RegExp(r'^https?:\/\/'), 'webcal://');
    final Uri uri = Uri.parse(webcalUrl);
    try {
      final bool launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(
          Uri.parse(feedUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: feedUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open calendar app directly. Feed URL copied to clipboard!',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _openGoogleCalendar(String feedUrl) async {
    final String gcalUrl =
        'https://calendar.google.com/calendar/render?cid=${Uri.encodeComponent(feedUrl)}';
    final Uri uri = Uri.parse(gcalUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: feedUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open browser. Feed URL copied to clipboard!',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    // Resolve API key instantly from instance auth if present, or fallback to host config
    final String apiKey = switch (widget.instance.auth) {
      InstanceAuthApiKey(:final String apiKey) => apiKey,
      _ => ref.watch(lidarrHostConfigProvider(widget.instance)).value?.apiKey ??
          '',
    };

    final String feedUrl = _buildFeedUrl(apiKey);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calendar_month_outlined),
          SizedBox(width: Insets.xs),
          Text('iCal Calendar Feed'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscribe to your release calendar in Apple Calendar, Google Calendar, or Outlook to automatically sync upcoming music releases.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pastDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Past Days',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: TextField(
                      controller: _futureDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Future Days',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.xs),
              SwitchListTile(
                title: const Text('Include Unmonitored'),
                subtitle: const Text(
                  'Include releases for unmonitored albums',
                  style: TextStyle(fontSize: 11),
                ),
                value: _unmonitored,
                contentPadding: EdgeInsets.zero,
                onChanged: (bool val) => setState(() => _unmonitored = val),
              ),
              const SizedBox(height: Insets.sm),
              const Text(
                'Feed URL:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(Insets.sm),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        feedUrl,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy URL',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: feedUrl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Calendar feed URL copied!'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.md),
              // Direct Action Buttons
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                label: const Text('Subscribe in Calendar App'),
                onPressed: () => _subscribeInCalendar(feedUrl),
              ),
              const SizedBox(height: Insets.xs),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('Add to Google Calendar Web'),
                onPressed: () => _openGoogleCalendar(feedUrl),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
