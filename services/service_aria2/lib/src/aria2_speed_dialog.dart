import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Preset download limits in bytes/s; 0 means unlimited.
const List<int> _presetBytes = <int>[
  0,
  512 * 1024,
  1024 * 1024,
  2048 * 1024,
  5120 * 1024,
  10240 * 1024,
  25600 * 1024,
];

/// A speed limit in bytes as a human string.
String aria2SpeedLimitLabel(int bytesPerSec) {
  if (bytesPerSec <= 0) {
    return 'Unlimited';
  }
  if (bytesPerSec % 1024 != 0) {
    return '$bytesPerSec B/s';
  }
  final int kb = bytesPerSec ~/ 1024;
  if (kb >= 1024) {
    final double mb = kb / 1024;
    return '${mb == mb.roundToDouble() ? mb.toInt() : mb.toStringAsFixed(1)} MB/s';
  }
  return '$kb KB/s';
}

/// Parses an entered speed string into bytes per second.
///
/// Accepts:
/// - Plain number: treated as KB/s unless suffixed with 'b'/'B'.
/// - Suffixes: 'B' / 'B/s' (bytes), 'K' / 'KB' (kilobytes), 'M' / 'MB' (megabytes).
int? _parseSpeedBytes(String input) {
  final String trimmed = input.trim();
  if (trimmed.isEmpty || trimmed == '0') return 0;

  final RegExpMatch? match =
      RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z/]*)$').firstMatch(trimmed);
  if (match == null) return null;

  final double? val = double.tryParse(match.group(1)!);
  if (val == null || val < 0) return null;

  final String unit = (match.group(2) ?? '').toLowerCase();
  if (unit.startsWith('b') && !unit.startsWith('bit')) {
    return val.round();
  } else if (unit.startsWith('m')) {
    return (val * 1024 * 1024).round();
  } else {
    // Default unit is KB/s
    return (val * 1024).round();
  }
}

/// Formats bytes into a concise editable text representation.
String _bytesToEditable(int bytes) {
  if (bytes <= 0) return '';
  if (bytes % 1024 != 0) return '$bytes B';
  if (bytes % (1024 * 1024) == 0) return '${bytes ~/ (1024 * 1024)} MB';
  return '${bytes ~/ 1024}';
}

/// Picks a global download speed limit in bytes per second.
///
/// Returns the bytes/s value (0 = unlimited), or null when dismissed.
Future<int?> showAria2SpeedDialog(BuildContext context, {int currentBytes = 0}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext ctx) =>
        _GlobalSpeedDialogContent(currentBytes: currentBytes),
  );
}

class _GlobalSpeedDialogContent extends StatefulWidget {
  const _GlobalSpeedDialogContent({required this.currentBytes});

  final int currentBytes;

  @override
  State<_GlobalSpeedDialogContent> createState() =>
      _GlobalSpeedDialogContentState();
}

class _GlobalSpeedDialogContentState extends State<_GlobalSpeedDialogContent> {
  late final TextEditingController _custom = TextEditingController(
    text: _bytesToEditable(widget.currentBytes),
  );

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download limit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final int bytes in _presetBytes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(aria2SpeedLimitLabel(bytes)),
                trailing: bytes == widget.currentBytes
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => Navigator.of(context).pop(bytes),
              ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _custom,
              decoration: const InputDecoration(
                labelText: 'Custom limit',
                hintText: 'e.g. 512, 10M, 1500 B',
                helperText: 'Numbers default to KB/s; 0 for unlimited',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (String value) {
                final int? bytes = _parseSpeedBytes(value);
                if (bytes != null) Navigator.of(context).pop(bytes);
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final int? bytes = _parseSpeedBytes(_custom.text);
            if (bytes != null) Navigator.of(context).pop(bytes);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}

/// Dialog for download and upload speed limits on a specific transfer task.
Future<({int dlBytes, int ulBytes})?> showAria2TaskSpeedDialog(
  BuildContext context, {
  required int currentDlBytes,
  required int currentUlBytes,
}) {
  return showDialog<({int dlBytes, int ulBytes})>(
    context: context,
    builder: (BuildContext ctx) => _TaskSpeedDialogContent(
      currentDlBytes: currentDlBytes,
      currentUlBytes: currentUlBytes,
    ),
  );
}

class _TaskSpeedDialogContent extends StatefulWidget {
  const _TaskSpeedDialogContent({
    required this.currentDlBytes,
    required this.currentUlBytes,
  });

  final int currentDlBytes;
  final int currentUlBytes;

  @override
  State<_TaskSpeedDialogContent> createState() =>
      _TaskSpeedDialogContentState();
}

class _TaskSpeedDialogContentState extends State<_TaskSpeedDialogContent> {
  late final TextEditingController _dlController = TextEditingController(
    text: _bytesToEditable(widget.currentDlBytes),
  );
  late final TextEditingController _ulController = TextEditingController(
    text: _bytesToEditable(widget.currentUlBytes),
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
            decoration: const InputDecoration(
              labelText: 'Download limit',
              hintText: 'e.g. 512, 5M, 1500 B',
              helperText: '0 or empty for unlimited (default KB/s)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _ulController,
            decoration: const InputDecoration(
              labelText: 'Upload limit',
              hintText: 'e.g. 256, 2M, 1500 B',
              helperText: '0 or empty for unlimited (default KB/s)',
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
            final int dl = _parseSpeedBytes(_dlController.text) ?? 0;
            final int ul = _parseSpeedBytes(_ulController.text) ?? 0;
            Navigator.of(context).pop((dlBytes: dl, ulBytes: ul));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
