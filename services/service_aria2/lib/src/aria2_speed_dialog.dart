import 'package:flutter/material.dart';

/// Preset download limits in KB/s; 0 means unlimited.
const List<int> _presetsKb = <int>[0, 512, 1024, 2048, 5120, 10240, 25600];

/// A speed limit as a human string.
String aria2SpeedLimitLabel(int kbPerSec) {
  if (kbPerSec <= 0) {
    return 'Unlimited';
  }
  if (kbPerSec >= 1024) {
    final double mb = kbPerSec / 1024;
    return '${mb == mb.roundToDouble() ? mb.toInt() : mb.toStringAsFixed(1)} MB/s';
  }
  return '$kbPerSec KB/s';
}

/// Picks a global download limit.
///
/// Returns the KB/s value (0 = unlimited), or null when dismissed.
Future<int?> showAria2SpeedDialog(BuildContext context, {int currentKb = 0}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext context) =>
        _SpeedDialogContent(currentKb: currentKb),
  );
}

class _SpeedDialogContent extends StatefulWidget {
  const _SpeedDialogContent({required this.currentKb});

  final int currentKb;

  @override
  State<_SpeedDialogContent> createState() => _SpeedDialogContentState();
}

class _SpeedDialogContentState extends State<_SpeedDialogContent> {
  final TextEditingController _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final int kb in _presetsKb)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(aria2SpeedLimitLabel(kb)),
              trailing: kb == widget.currentKb
                  ? const Icon(Icons.check, size: 18)
                  : null,
              onTap: () => Navigator.of(context).pop(kb),
            ),
          TextField(
            controller: _custom,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Custom (KB/s)'),
            onSubmitted: (String value) {
              final int? kb = int.tryParse(value.trim());
              if (kb != null && kb >= 0) {
                Navigator.of(context).pop(kb);
              }
            },
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
            final int? kb = int.tryParse(_custom.text.trim());
            if (kb != null && kb >= 0) {
              Navigator.of(context).pop(kb);
            }
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}
