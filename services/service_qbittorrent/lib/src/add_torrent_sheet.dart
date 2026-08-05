import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import 'qbittorrent_client.dart';
import 'qbittorrent_providers.dart';

/// Bottom sheet to add a torrent to a qBittorrent instance.
///
/// Two input modes:
/// * **Link** - one or more magnet links / `.torrent` URLs (one per line).
/// * **File** - a picked `.torrent` file, uploaded as multipart bytes.
///
/// Plus optional category (dropdown of the server's categories), an optional
/// save path override, and "start paused" / "sequential" toggles.
///
/// Returns `true` via `Navigator.pop` when something was successfully added,
/// so the caller can refresh the torrent list.
enum AddTorrentMode { link, file }

class AddTorrentSheet extends ConsumerStatefulWidget {
  const AddTorrentSheet({
    required this.instance,
    this.initialMode = AddTorrentMode.link,
    this.initialLink,
    this.initialFileBytes,
    this.initialFileName,
    super.key,
  });

  final Instance instance;
  final AddTorrentMode initialMode;

  /// A magnet link or `.torrent` URL to open the sheet with, filled into the
  /// link field. Set when another app shares a torrent with Atrium.
  final String? initialLink;

  /// The bytes of a `.torrent` handed over by another app. When set the sheet
  /// opens in file mode with these bytes already in hand, so there is nothing
  /// to pick.
  final Uint8List? initialFileBytes;

  /// Display name for [initialFileBytes], shown so the user can see what they
  /// are adding.
  final String? initialFileName;

  /// Opens the sheet and returns whether a torrent was added.
  static Future<bool> show(
    BuildContext context,
    Instance instance, {
    AddTorrentMode initialMode = AddTorrentMode.link,
    String? initialLink,
    Uint8List? initialFileBytes,
    String? initialFileName,
  }) async {
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (_) => AddTorrentSheet(
        instance: instance,
        initialMode: initialMode,
        initialLink: initialLink,
        initialFileBytes: initialFileBytes,
        initialFileName: initialFileName,
      ),
    );
    return added ?? false;
  }

  @override
  ConsumerState<AddTorrentSheet> createState() => _AddTorrentSheetState();
}

class _AddTorrentSheetState extends ConsumerState<AddTorrentSheet> {
  final TextEditingController _links = TextEditingController();
  final TextEditingController _savePath = TextEditingController();

  // Shared bytes force file mode: there is nothing left to pick.
  late final AddTorrentMode _mode = widget.initialFileBytes != null
      ? AddTorrentMode.file
      : widget.initialMode;
  PlatformFile? _file;
  String? _category;
  bool _paused = false;
  bool _sequential = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialLink != null) {
      _links.text = widget.initialLink!;
    }
  }

  @override
  void dispose() {
    _links.dispose();
    _savePath.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_busy) {
      return false;
    }
    return _mode == AddTorrentMode.link
        ? _links.text.trim().isNotEmpty
        : _file != null || widget.initialFileBytes != null;
  }

  Future<void> _pickFile() async {
    final FilePickerResult? res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['torrent'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _file = res.files.single);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final QbittorrentClient client =
          await ref.read(qbittorrentClientProvider(widget.instance).future);
      final String? savePath =
          _savePath.text.trim().isEmpty ? null : _savePath.text.trim();

      if (_mode == AddTorrentMode.link) {
        final List<String> urls = _links.text
            .split('\n')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toList();
        await client.addUrls(
          urls,
          category: _category,
          savePath: savePath,
          paused: _paused,
          sequential: _sequential,
        );
      } else {
        // A picked file wins over shared bytes: if the user went and chose one
        // anyway, that is the more recent intent.
        final PlatformFile? f = _file;
        final Uint8List bytes =
            f != null ? await f.readAsBytes() : widget.initialFileBytes!;
        await client.addTorrentFile(
          bytes,
          filename: f?.name ?? widget.initialFileName ?? 'shared.torrent',
          category: _category,
          savePath: savePath,
          paused: _paused,
          sequential: _sequential,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not add: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<String>> categories =
        ref.watch(qbitCategoriesProvider(widget.instance));

    return AlertDialog(
      title: const Text('Add torrent'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_mode == AddTorrentMode.link)
              TextField(
                controller: _links,
                minLines: 2,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Magnet links or .torrent URLs',
                  hintText: 'magnet:?xt=… (one per line)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  _file?.name ??
                      widget.initialFileName ??
                      (widget.initialFileBytes != null
                          ? 'Shared torrent'
                          : 'Choose a .torrent file'),
                ),
              ),
            const SizedBox(height: Insets.md),
            categories.when(
              data: (List<String> cats) => DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    child: Text('None'),
                  ),
                  ...cats.map(
                    (String c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ),
                  ),
                ],
                onChanged: (String? v) => setState(() => _category = v),
              ),
              loading: () => const LinearProgressIndicatorM3E(
                shape: ProgressM3EShape.flat,
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _savePath,
              decoration: const InputDecoration(
                labelText: 'Save path (optional)',
                hintText: 'Leave blank for the default',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Insets.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start paused'),
              value: _paused,
              onChanged: (bool v) => setState(() => _paused = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Download in sequential order'),
              value: _sequential,
              onChanged: (bool v) => setState(() => _sequential = v),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: Insets.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ExpressiveProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
