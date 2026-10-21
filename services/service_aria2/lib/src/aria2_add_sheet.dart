import 'dart:convert';
import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aria2_api.dart';
import 'aria2_providers.dart';

/// One `.torrent` handed to the sheet, as bytes plus a name to show.
///
/// A record rather than a class so the app can pass these in without the
/// service packages needing a shared type to depend on.
typedef TorrentFileArg = ({Uint8List bytes, String? name});

/// Opens the add-download sheet for [instance].
///
/// The optional arguments prefill the sheet when another app shares torrents
/// with Atrium: [initialLink] for a magnet or a `.torrent` URL, or
/// [initialFiles] for one or more `.torrent` files handed over as bytes.
Future<void> showAria2AddSheet(
  BuildContext context,
  Instance instance, {
  String? initialLink,
  List<TorrentFileArg>? initialFiles,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // The sheet is a route too, so it needs the root navigator for the same
    // reason a pushed page does.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AddDownloadForm(
        instance: instance,
        initialLink: initialLink,
        initialFiles: initialFiles,
      ),
    ),
  );
}

class _AddDownloadForm extends ConsumerStatefulWidget {
  const _AddDownloadForm({
    required this.instance,
    this.initialLink,
    this.initialFiles,
  });

  final Instance instance;
  final String? initialLink;
  final List<TorrentFileArg>? initialFiles;

  @override
  ConsumerState<_AddDownloadForm> createState() => _AddDownloadFormState();
}

class _AddDownloadFormState extends ConsumerState<_AddDownloadForm> {
  final TextEditingController _uris = TextEditingController();
  final TextEditingController _dir = TextEditingController();
  final TextEditingController _out = TextEditingController();

  /// The `.torrent` files staged for adding, base64 encoded as aria2 wants
  /// them.
  final List<({String name, String base64})> _files =
      <({String name, String base64})>[];

  bool _pause = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final List<TorrentFileArg>? shared = widget.initialFiles;
    if (shared != null && shared.isNotEmpty) {
      _files.addAll(
        shared.map(
          (TorrentFileArg f) =>
              (name: f.name ?? 'torrent', base64: base64Encode(f.bytes)),
        ),
      );
    } else if (widget.initialLink != null) {
      _uris.text = widget.initialLink!;
    }
  }

  @override
  void dispose() {
    _uris.dispose();
    _dir.dispose();
    _out.dispose();
    super.dispose();
  }

  /// The URIs typed in, one per line, blanks dropped.
  List<String> get _lines => _uris.text
      .split(RegExp(r'[\r\n]+'))
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList();

  bool get _byFile => _files.isNotEmpty;

  String get _fileLabel => switch (_files.length) {
    0 => 'Or pick a .torrent file',
    1 => _files.first.name,
    final int n => '$n torrents',
  };

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['torrent'],
    );
    if (result == null) {
      return;
    }
    final List<({String name, String base64})> picked =
        <({String name, String base64})>[];
    for (final PlatformFile file in result.files) {
      final Uint8List bytes = await file.readAsBytes();
      picked.add((name: file.name, base64: base64Encode(bytes)));
    }
    if (picked.isEmpty) {
      return;
    }
    setState(() => _files.addAll(picked));
  }

  Future<void> _submit() async {
    final List<String> uris = _lines;
    final bool byFile = _byFile;
    if (!byFile && uris.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    try {
      final Aria2Api api = await ref.read(
        aria2ApiProvider(widget.instance).future,
      );
      final Map<String, String> options = <String, String>{
        if (_dir.text.trim().isNotEmpty) 'dir': _dir.text.trim(),
        // A file name only makes sense for a single download.
        if (uris.length == 1 && _out.text.trim().isNotEmpty)
          'out': _out.text.trim(),
        if (_pause) 'pause': 'true',
      };
      if (byFile) {
        for (final ({String name, String base64}) file in _files) {
          await api.addTorrent(file.base64, options: options);
        }
      } else if (uris.length == 1) {
        await api.addUri(uris, options: options);
      } else {
        // aria2's `addUri` treats every URI as a mirror of the same file, so
        // a list of links is added one download at a time - which is what
        // someone pasting four links into a download box means.
        for (final String uri in uris) {
          await api.addUri(<String>[uri], options: options);
        }
      }
      if (!mounted) {
        return;
      }
      ref.invalidate(aria2SnapshotProvider(widget.instance));
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Added')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool byFile = _byFile;
    return SafeArea(
      child: SingleChildScrollView(
        padding: Insets.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Add download', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Insets.md),
            TextField(
              controller: _uris,
              minLines: 2,
              maxLines: 4,
              enabled: !byFile,
              decoration: const InputDecoration(
                labelText: 'URI or magnet link',
                hintText: 'magnet:?xt=urn:btih:... or https://host/file',
                helperText:
                    'One per line. Each line is added as its own '
                    'download.',
              ),
              autocorrect: false,
            ),
            const SizedBox(height: Insets.sm),
            OutlinedButton.icon(
              onPressed: byFile ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_fileLabel),
            ),
            if (byFile)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(_files.clear),
                  icon: const Icon(Icons.close),
                  label: const Text('Use a link instead'),
                ),
              ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: _dir,
              decoration: const InputDecoration(
                labelText: 'Directory (optional)',
                hintText: '/downloads',
                helperText: 'Left empty, the daemon\'s own default is used.',
              ),
              autocorrect: false,
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _out,
              enabled: !byFile && _lines.length == 1,
              decoration: const InputDecoration(
                labelText: 'File name (optional)',
                helperText: 'Only for a single link.',
              ),
              autocorrect: false,
            ),
            const SizedBox(height: Insets.sm),
            SwitchListTile(
              value: _pause,
              onChanged: (bool value) => setState(() => _pause = value),
              title: const Text('Add paused'),
              subtitle: const Text('The download waits until you start it.'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: Insets.md),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
