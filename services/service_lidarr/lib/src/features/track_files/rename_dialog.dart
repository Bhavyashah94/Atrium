import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/generated.dart';
import '../../lidarr_api.dart';
import '../../lidarr_providers.dart';

/// Opens the Lidarr Audio Files Rename Preview and Execution dialog.
Future<void> showLidarrRenameDialog(
  BuildContext context, {
  required Instance instance,
  required int artistId,
  int? albumId,
  Set<int>? albumIds,
  String? artistName,
  String? albumTitle,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) => LidarrRenameDialog(
      instance: instance,
      artistId: artistId,
      albumId: albumId,
      albumIds: albumIds,
      artistName: artistName,
      albumTitle: albumTitle,
    ),
  );
}

/// Dialog presenting a side-by-side / diff preview of audio files that will be
/// organized and renamed according to Lidarr's naming conventions.
class LidarrRenameDialog extends ConsumerStatefulWidget {
  const LidarrRenameDialog({
    required this.instance,
    required this.artistId,
    this.albumId,
    this.albumIds,
    this.artistName,
    this.albumTitle,
    super.key,
  });

  final Instance instance;
  final int artistId;
  final int? albumId;
  final Set<int>? albumIds;
  final String? artistName;
  final String? albumTitle;

  @override
  ConsumerState<LidarrRenameDialog> createState() => _LidarrRenameDialogState();
}

class _LidarrRenameDialogState extends ConsumerState<LidarrRenameDialog> {
  final Set<int> _selectedTrackFileIds = <int>{};
  bool _initializedSelection = false;
  bool _renaming = false;

  String _extractFileName(String? path) {
    if (path == null || path.isEmpty) return 'Unknown File';
    return path.split(RegExp(r'[\\/]')).last;
  }

  void _syncInitialSelection(List<RenameTrackResource> files) {
    if (!_initializedSelection) {
      _selectedTrackFileIds.clear();
      for (final RenameTrackResource f in files) {
        if (f.trackFileId != null) {
          _selectedTrackFileIds.add(f.trackFileId!);
        }
      }
      _initializedSelection = true;
    }
  }

  Future<void> _executeRename() async {
    if (_selectedTrackFileIds.isEmpty) return;
    setState(() => _renaming = true);

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp = await api.executeCommand(
        'RenameFiles',
        <String, dynamic>{
          'artistId': widget.artistId,
          'files': _selectedTrackFileIds.toList(),
        },
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to execute rename');
      }

      if (!mounted) return;

      // Invalidate relevant providers across the app
      ref.invalidate(
        lidarrArtistByIdProvider((widget.instance, widget.artistId)),
      );
      ref.invalidate(
        lidarrAlbumsForArtistProvider((widget.instance, widget.artistId)),
      );
      if (widget.albumId != null) {
        ref.invalidate(
          lidarrTracksForAlbumProvider(
            (widget.instance, widget.artistId, widget.albumId!),
          ),
        );
        ref.invalidate(
          lidarrTrackFilesForAlbumProvider(
            (widget.instance, widget.albumId!),
          ),
        );
      }
      ref.invalidate(lidarrArtistsProvider(widget.instance));
      ref.invalidate(lidarrHistoryProvider(widget.instance));
      ref.invalidate(lidarrQueueProvider(widget.instance));
      ref.invalidate(
        lidarrRenamePreviewProvider(
          (widget.instance, widget.artistId, widget.albumId),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Renaming ${_selectedTrackFileIds.length} audio ${_selectedTrackFileIds.length == 1 ? 'file' : 'files'}...',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rename failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _renaming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<RenameTrackResource>> previewAsync = ref.watch(
      lidarrRenamePreviewProvider(
        (widget.instance, widget.artistId, widget.albumId),
      ),
    );
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final String titleText = widget.albumTitle != null
        ? 'Rename ${widget.albumTitle}'
        : widget.artistName != null
            ? 'Rename ${widget.artistName}'
            : 'Rename Audio Files';

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Row(
        children: <Widget>[
          const Icon(Icons.drive_file_rename_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titleText,
              style: theme.textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: previewAsync.when(
          loading: () => const Center(
            child: ExpressiveProgressIndicator(),
          ),
          error: (Object err, StackTrace? _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.error_outline, color: cs.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Failed to load rename preview',
                  style: theme.textTheme.titleMedium?.copyWith(color: cs.error),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    ref.invalidate(
                      lidarrRenamePreviewProvider(
                        (widget.instance, widget.artistId, widget.albumId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (List<RenameTrackResource> rawFiles) {
            final List<RenameTrackResource> files = widget.albumIds != null
                ? rawFiles
                    .where(
                      (RenameTrackResource f) =>
                          f.albumId != null &&
                          widget.albumIds!.contains(f.albumId),
                    )
                    .toList()
                : rawFiles;
            _syncInitialSelection(files);

            if (files.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_outline,
                        color: cs.tertiary,
                        size: 52,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All files are correctly named',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No audio files need to be organized or renamed.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final bool allSelected =
                _selectedTrackFileIds.length == files.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header action bar with Select All toggle and counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: allSelected,
                        tristate:
                            _selectedTrackFileIds.isNotEmpty && !allSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              for (final RenameTrackResource f in files) {
                                if (f.trackFileId != null) {
                                  _selectedTrackFileIds.add(f.trackFileId!);
                                }
                              }
                            } else {
                              _selectedTrackFileIds.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_selectedTrackFileIds.length} of ${files.length} selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final RenameTrackResource item = files[index];
                      final int? fileId = item.trackFileId;
                      final bool isSelected = fileId != null &&
                          _selectedTrackFileIds.contains(fileId);

                      final String currentName =
                          _extractFileName(item.existingPath);
                      final String newName = _extractFileName(item.newPath);
                      final String trackNumbers = item.trackNumbers != null &&
                              item.trackNumbers!.isNotEmpty
                          ? 'Track ${item.trackNumbers!.join(', ')}'
                          : 'Track';

                      return CheckboxListTile(
                        value: isSelected,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        onChanged: fileId == null
                            ? null
                            : (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedTrackFileIds.add(fileId);
                                  } else {
                                    _selectedTrackFileIds.remove(fileId);
                                  }
                                });
                              },
                        title: Text(
                          trackNumbers,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 4),
                            // Current existing path (struck through)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.remove_circle_outline,
                                  size: 14,
                                  color: cs.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    currentName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.error,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Proposed new path
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 14,
                                  color: cs.tertiary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    newName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _renaming ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        previewAsync.maybeWhen(
          data: (List<RenameTrackResource> files) {
            if (files.isEmpty) return const SizedBox.shrink();
            return FilledButton.icon(
              onPressed: (_renaming || _selectedTrackFileIds.isEmpty)
                  ? null
                  : _executeRename,
              icon: _renaming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ExpressiveProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.drive_file_rename_outline, size: 18),
              label: Text(
                _selectedTrackFileIds.isEmpty
                    ? 'Rename'
                    : 'Rename (${_selectedTrackFileIds.length})',
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
