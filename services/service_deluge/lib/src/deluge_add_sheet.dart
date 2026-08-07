import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deluge_client.dart';
import 'deluge_providers.dart';

/// One `.torrent` handed to the sheet, as bytes plus a name to show.
///
/// A record rather than a class so the app can pass these in without the
/// service packages needing a shared type to depend on.
typedef TorrentFileArg = ({Uint8List bytes, String? name});

/// Opens the add-torrent sheet for [instance].
///
/// The optional arguments prefill the sheet when another app shares torrents
/// with Atrium: [initialLink] for a magnet or `.torrent` URL, or
/// [initialFiles] for one or more `.torrent` files handed over as bytes. A
/// batch shares one save path and one paused choice, since answering those per
/// torrent is unusable past a handful.
Future<void> showDelugeAddSheet(
  BuildContext context,
  Instance instance, {
  String? initialLink,
  List<TorrentFileArg>? initialFiles,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // The sheet is a route too, so it needs the root navigator for the
    // same reason a pushed page does.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (BuildContext context) => _DelugeAddSheet(
      instance: instance,
      initialLink: initialLink,
      initialFiles: initialFiles,
    ),
  );
}

/// Which way the torrent is being supplied.
enum _AddMode { link, file }

/// A [ConsumerStatefulWidget] rather than a plain sheet taking the caller's
/// `ref`: the list behind this sheet polls every few seconds, and a ref
/// borrowed from that widget gets pruned on its next rebuild, leaving the
/// sheet's controls dead.
class _DelugeAddSheet extends ConsumerStatefulWidget {
  const _DelugeAddSheet({
    required this.instance,
    this.initialLink,
    this.initialFiles,
  });

  final Instance instance;
  final String? initialLink;
  final List<TorrentFileArg>? initialFiles;

  @override
  ConsumerState<_DelugeAddSheet> createState() => _DelugeAddSheetState();
}

class _DelugeAddSheetState extends ConsumerState<_DelugeAddSheet> {
  final TextEditingController _link = TextEditingController();
  final TextEditingController _savePath = TextEditingController();

  _AddMode _mode = _AddMode.link;
  bool _startPaused = false;
  bool _busy = false;

  final List<TorrentFileArg> _files = <TorrentFileArg>[];

  /// How far through a batch the submit has got, for the button label.
  int _done = 0;

  @override
  void initState() {
    super.initState();
    final List<TorrentFileArg>? shared = widget.initialFiles;
    if (shared != null && shared.isNotEmpty) {
      _mode = _AddMode.file;
      _files.addAll(shared);
    } else if (widget.initialLink != null) {
      _link.text = widget.initialLink!;
    }
  }

  String get _fileLabel => switch (_files.length) {
        0 => 'Choose .torrent files',
        1 => _files.first.name ?? 'One torrent',
        final int n => '$n torrents',
      };

  /// A batch can take a while, so the button counts rather than just spinning.
  String get _addLabel {
    if (!_busy) {
      return _mode == _AddMode.file && _files.length > 1
          ? 'Add ${_files.length}'
          : 'Add';
    }
    if (_mode == _AddMode.file && _files.length > 1) {
      return 'Adding $_done of ${_files.length}...';
    }
    return 'Adding...';
  }

  @override
  void dispose() {
    _link.dispose();
    _savePath.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // pickFiles is already multi-select; the old code then threw the result
    // away with singleOrNull, so choosing more than one silently did nothing.
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['torrent'],
    );
    final List<PlatformFile> picked = result?.files ?? <PlatformFile>[];
    if (picked.isEmpty) return;
    // Read the bytes now: on Android the pick is a content:// URI, not a path
    // the client could reopen later.
    final List<TorrentFileArg> read = <TorrentFileArg>[];
    for (final PlatformFile file in picked) {
      read.add((bytes: await file.readAsBytes(), name: file.name));
    }
    if (!mounted) return;
    setState(() {
      _files
        ..clear()
        ..addAll(read);
    });
  }

  bool get _canSubmit {
    if (_busy) return false;
    return switch (_mode) {
      _AddMode.link => _link.text.trim().isNotEmpty,
      _AddMode.file => _files.isNotEmpty,
    };
  }

  Future<void> _submit() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final DelugeClient client =
          await ref.read(delugeClientProvider(widget.instance).future);
      final String? savePath =
          _savePath.text.trim().isEmpty ? null : _savePath.text.trim();
      switch (_mode) {
        case _AddMode.link:
          final String link = _link.text.trim();
          // Deluge has separate calls for a magnet and an http(s) .torrent.
          if (link.startsWith('magnet:')) {
            await client.addMagnet(
              link,
              savePath: savePath,
              paused: _startPaused,
            );
          } else {
            await client.addUrl(
              link,
              savePath: savePath,
              paused: _startPaused,
            );
          }
        case _AddMode.file:
          // One failure does not abandon the rest of the batch; the count of
          // what failed is reported at the end instead.
          int failed = 0;
          for (final TorrentFileArg file in _files) {
            try {
              await client.addFile(
                file.bytes,
                filename: file.name ?? 'torrent.torrent',
                savePath: savePath,
                paused: _startPaused,
              );
            } catch (_) {
              failed++;
            }
            if (mounted) setState(() => _done++);
          }
          ref.invalidate(delugeRawTorrentsProvider(widget.instance));
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(content: Text(_batchResult(_files.length, failed))),
          );
          return;
      }
      ref.invalidate(delugeRawTorrentsProvider(widget.instance));
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Torrent added')));
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  static String _batchResult(int total, int failed) {
    if (failed == 0) {
      return total == 1 ? 'Torrent added' : '$total torrents added';
    }
    if (failed == total) {
      return total == 1 ? 'Add failed' : 'All $total failed';
    }
    return 'Added ${total - failed} of $total, $failed failed';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Insets.md,
        right: Insets.md,
        top: Insets.md,
        // Keep the fields above the keyboard.
        bottom: MediaQuery.viewInsetsOf(context).bottom + Insets.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Add torrent',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Insets.md),
            SegmentedButton<_AddMode>(
              segments: const <ButtonSegment<_AddMode>>[
                ButtonSegment<_AddMode>(
                  value: _AddMode.link,
                  label: Text('Magnet or URL'),
                  icon: Icon(Icons.link),
                ),
                ButtonSegment<_AddMode>(
                  value: _AddMode.file,
                  label: Text('File'),
                  icon: Icon(Icons.attach_file),
                ),
              ],
              selected: <_AddMode>{_mode},
              onSelectionChanged: _busy
                  ? null
                  : (Set<_AddMode> s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: Insets.md),
            if (_mode == _AddMode.link)
              TextField(
                controller: _link,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'magnet: link or .torrent URL',
                ),
                onChanged: (_) => setState(() {}),
              )
            else
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_fileLabel),
              ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: _savePath,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Download folder (optional)',
                helperText: "Leave empty to use Deluge's default",
              ),
            ),
            const SizedBox(height: Insets.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _startPaused,
              onChanged:
                  _busy ? null : (bool v) => setState(() => _startPaused = v),
              title: const Text('Add paused'),
            ),
            const SizedBox(height: Insets.sm),
            FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_addLabel),
            ),
          ],
        ),
      ),
    );
  }
}
