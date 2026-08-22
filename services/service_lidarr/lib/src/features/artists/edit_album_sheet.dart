import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lidarr_formatters.dart';
import '../../generated/generated.dart';
import '../../lidarr_api.dart';
import '../../lidarr_providers.dart';

/// Shows the modal bottom sheet for editing album settings.
Future<bool?> showLidarrEditAlbumSheet(
  BuildContext context, {
  required Instance instance,
  required int artistId,
  required AlbumResource album,
  String? artistName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => LidarrEditAlbumSheet(
      instance: instance,
      artistId: artistId,
      album: album,
      artistName: artistName,
    ),
  );
}

/// Confirmation dialog for deleting an album from Lidarr.
Future<bool?> showLidarrDeleteAlbumDialog(
  BuildContext context, {
  required Instance instance,
  required int artistId,
  required AlbumResource album,
  required WidgetRef ref,
}) async {
  bool deleteFiles = false;
  bool addImportListExclusion = true;

  final int fileCount = album.statistics?.trackFileCount ?? 0;
  final int sizeOnDisk = album.statistics?.sizeOnDisk ?? 0;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final ThemeData theme = Theme.of(context);
          final ColorScheme cs = theme.colorScheme;

          return AlertDialog(
            title: Text('Delete ${album.title ?? 'Album'}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Are you sure you want to delete this album from your Lidarr library?',
                  style: theme.textTheme.bodyMedium,
                ),
                if (fileCount > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    '$fileCount track files totaling ${LidarrFormatters.formatBytes(sizeOnDisk)} on disk.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Delete files from disk'),
                  subtitle: const Text('Permanently remove audio files'),
                  value: deleteFiles,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (bool? val) =>
                      setState(() => deleteFiles = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Add import list exclusion'),
                  subtitle: const Text('Prevent re-adding by automated lists'),
                  value: addImportListExclusion,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (bool? val) =>
                      setState(() => addImportListExclusion = val ?? false),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true || !context.mounted) return false;

  try {
    final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
    final ApiResponse<void> resp = await api.album.deleteAlbumById(
      id: album.id!,
      deleteFiles: deleteFiles,
      addImportListExclusion: addImportListExclusion,
    );

    if (!resp.isSuccess) {
      throw Exception(resp.error?.message ?? 'Failed to delete album');
    }

    ref.invalidate(lidarrAlbumsForArtistProvider((instance, artistId)));
    ref.invalidate(lidarrArtistByIdProvider((instance, artistId)));
    ref.invalidate(lidarrArtistsProvider(instance));
    ref.invalidate(lidarrWantedMissingProvider);
    ref.invalidate(lidarrWantedCutoffProvider);
    ref.invalidate(lidarrCalendarProvider);
    ref.invalidate(lidarrHistoryProvider(instance));
    ref.invalidate(lidarrQueueProvider(instance));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${album.title ?? 'Album'}"'),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return false;
  }
}

/// Bottom sheet for configuring individual album monitoring, release preferences,
/// and release monitoring.
class LidarrEditAlbumSheet extends ConsumerStatefulWidget {
  const LidarrEditAlbumSheet({
    required this.instance,
    required this.artistId,
    required this.album,
    this.artistName,
    super.key,
  });

  final Instance instance;
  final int artistId;
  final AlbumResource album;
  final String? artistName;

  @override
  ConsumerState<LidarrEditAlbumSheet> createState() =>
      _LidarrEditAlbumSheetState();
}

class _LidarrEditAlbumSheetState extends ConsumerState<LidarrEditAlbumSheet> {
  late bool _monitored;
  late bool _anyReleaseOk;
  late List<AlbumReleaseResource> _releases;
  int? _selectedReleaseId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _monitored = widget.album.monitored ?? true;
    _anyReleaseOk = widget.album.anyReleaseOk ?? true;
    _releases = List<AlbumReleaseResource>.from(
      widget.album.releases ?? <AlbumReleaseResource>[],
    );

    final AlbumReleaseResource monitoredRel = _releases.firstWhere(
      (AlbumReleaseResource r) => r.monitored == true,
      orElse: () =>
          _releases.isNotEmpty ? _releases.first : const AlbumReleaseResource(),
    );
    _selectedReleaseId = monitoredRel.id;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);

      // Update release monitoring if specific release selected
      final List<AlbumReleaseResource> updatedReleases = _releases.map(
        (AlbumReleaseResource r) {
          if (!_anyReleaseOk && _selectedReleaseId != null) {
            return r.copyWith(monitored: r.id == _selectedReleaseId);
          }
          return r;
        },
      ).toList();

      final AlbumResource updatedAlbum = widget.album.copyWith(
        monitored: _monitored,
        anyReleaseOk: _anyReleaseOk,
        releases: updatedReleases.isNotEmpty ? updatedReleases : null,
      );

      final ApiResponse<AlbumResource> resp = await api.album.putAlbumById(
        id: widget.album.id!.toString(),
        body: updatedAlbum,
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to update album');
      }

      if (!mounted) return;

      ref.invalidate(
        lidarrAlbumsForArtistProvider((widget.instance, widget.artistId)),
      );
      if (widget.album.id != null) {
        ref.invalidate(
          lidarrTracksForAlbumProvider(
            (widget.instance, widget.artistId, widget.album.id!),
          ),
        );
      }
      ref.invalidate(lidarrWantedMissingProvider);
      ref.invalidate(lidarrWantedCutoffProvider);
      ref.invalidate(lidarrCalendarProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${widget.album.title ?? 'Album'}" settings'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final String albumTitle = widget.album.title ?? 'Album';
    final String typeTag =
        widget.album.albumType != null ? ' [${widget.album.albumType}]' : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              'Edit - $albumTitle$typeTag',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Delete Album',
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: () async {
                  final bool? deleted = await showLidarrDeleteAlbumDialog(
                    context,
                    instance: widget.instance,
                    artistId: widget.artistId,
                    album: widget.album,
                    ref: ref,
                  );
                  if (deleted == true && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Insets.md),
                  children: <Widget>[
                    // Monitored Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Monitored'),
                      subtitle: const Text(
                        'Search for and monitor tracks for this album',
                      ),
                      value: _monitored,
                      onChanged: (bool val) => setState(() => _monitored = val),
                    ),
                    const Divider(),

                    // Automatically Switch Release
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatically Switch Release'),
                      subtitle: const Text(
                        'Allow Lidarr to match audio files against any available release of this album',
                      ),
                      value: _anyReleaseOk,
                      onChanged: (bool val) =>
                          setState(() => _anyReleaseOk = val),
                    ),
                    const Divider(),

                    // Releases selection if multiple releases exist
                    if (_releases.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Preferred Release',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_anyReleaseOk)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Any release is currently allowed. Disable "Automatically Switch Release" to enforce a specific release format/edition.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      RadioGroup<int?>(
                        groupValue: _selectedReleaseId,
                        onChanged: (int? val) {
                          setState(() => _selectedReleaseId = val);
                        },
                        child: Column(
                          children: [
                            for (final AlbumReleaseResource release
                                in _releases)
                              RadioListTile<int?>(
                                title: Text(
                                  release.title ??
                                      release.disambiguation ??
                                      'Standard Release',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  <String>[
                                    if (release.format != null &&
                                        release.format!.isNotEmpty)
                                      release.format!,
                                    if (release.country != null &&
                                        release.country!.isNotEmpty)
                                      release.country!.join(', '),
                                    if (release.label != null &&
                                        release.label!.isNotEmpty)
                                      release.label!.join(', '),
                                    if (release.trackCount != null)
                                      '${release.trackCount} tracks',
                                  ].join(' • '),
                                ),
                                value: release.id,
                                contentPadding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Save Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  ExpressiveProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
