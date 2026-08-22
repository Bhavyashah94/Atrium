import 'package:collection/collection.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_providers.dart';

/// Disc-separated track listing & detailed track inspector modal.
class TrackList extends ConsumerWidget {
  const TrackList({
    required this.instance,
    required this.artistId,
    required this.albumId,
    super.key,
  });

  final Instance instance;
  final int artistId;
  final int albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TrackResource>> asyncTracks =
        ref.watch(lidarrTracksForAlbumProvider((instance, artistId, albumId)));

    return asyncTracks.when(
      data: (List<TrackResource> tracks) {
        if (tracks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No tracks available')),
          );
        }

        final Map<int, List<TrackResource>> groupedMedia = groupBy(
          tracks,
          (TrackResource t) => t.mediumNumber ?? 1,
        );

        final bool isMultiDisc = groupedMedia.length > 1;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (final MapEntry<int, List<TrackResource>> entry
                in groupedMedia.entries) ...[
              if (isMultiDisc)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.album_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Disc ${entry.key}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${entry.value.length} tracks)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              for (int index = 0; index < entry.value.length; index++)
                _buildTrackTile(context, ref, entry.value[index], index),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: ExpressiveProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Failed to load tracks: $err'),
      ),
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    WidgetRef ref,
    TrackResource track,
    int index,
  ) {
    final bool hasFile = track.hasFile == true;
    final bool isExplicit = track.explicit == true;

    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      onTap: () => _showTrackDetails(context, ref, track),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: hasFile
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            track.trackNumber ?? '${index + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: hasFile ? cs.primary : cs.onSurfaceVariant,
                ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              track.title ?? 'Unknown Track',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                color: hasFile ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ),
          if (isExplicit) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'E',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LidarrFormatters.formatDurationMs(track.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
          ),
          const SizedBox(width: 10),
          Icon(
            hasFile ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: hasFile ? cs.tertiary : cs.outline.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  void _showTrackDetails(
    BuildContext context,
    WidgetRef ref,
    TrackResource track,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final trackFilesAsync = ref.watch(
              lidarrTrackFilesForAlbumProvider((instance, albumId)),
            );

            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                final ThemeData theme = Theme.of(context);
                final ColorScheme cs = theme.colorScheme;

                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(Insets.lg),
                    children: [
                      Row(
                        children: [
                          Icon(
                            track.hasFile == true
                                ? Icons.audio_file
                                : Icons.music_note,
                            color: cs.primary,
                            size: 28,
                          ),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title ?? 'Track Details',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Disc ${track.mediumNumber ?? 1} • Track ${track.trackNumber ?? '-'} • ${LidarrFormatters.formatDurationMs(track.duration)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.sm),
                      const Divider(),
                      const SizedBox(height: Insets.sm),
                      Text(
                        'Media & File Information',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      if (track.hasFile != true)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No downloaded track file on disk for this track.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        trackFilesAsync.when(
                          data: (trackFiles) {
                            final TrackFileResource? file =
                                trackFiles.firstWhereOrNull(
                              (f) => f.id == track.trackFileId,
                            );

                            if (file == null) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Track file present in library.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              );
                            }

                            final MediaInfoResource? media = file.mediaInfo;
                            final String? qualityName =
                                file.quality?.quality?.name;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (qualityName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Chip(
                                      avatar: const Icon(
                                        Icons.high_quality,
                                        size: 18,
                                      ),
                                      label: Text(
                                        qualityName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                if (media?.audioCodec != null ||
                                    media?.audioBitRate != null)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.graphic_eq),
                                    title: Text(
                                      '${media?.audioCodec ?? 'Audio'}${media?.audioBitRate != null ? ' (${media!.audioBitRate})' : ''}',
                                    ),
                                    subtitle: Text(
                                      [
                                        if (media?.audioSampleRate != null)
                                          LidarrFormatters.formatSampleRate(
                                            media!.audioSampleRate,
                                          ),
                                        if (media?.audioBits != null)
                                          LidarrFormatters.formatBitDepth(
                                            media!.audioBits,
                                          ),
                                        if (media?.audioChannels != null)
                                          '${media!.audioChannels!.toInt()} Channels',
                                      ].join(' • '),
                                    ),
                                  ),
                                if (file.releaseGroup != null &&
                                    file.releaseGroup!.isNotEmpty)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.group_outlined),
                                    title: const Text('Release Group'),
                                    subtitle: Text(file.releaseGroup!),
                                  ),
                                if (file.size != null && file.size! > 0)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.storage_outlined),
                                    title: const Text('Size on Disk'),
                                    subtitle: Text(
                                      LidarrFormatters.formatBytes(file.size),
                                    ),
                                  ),
                                if (file.path != null && file.path!.isNotEmpty)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.folder_outlined),
                                    title: const Text('File Path'),
                                    subtitle: Text(
                                      file.path!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: Insets.md),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.error,
                                    side: BorderSide(color: cs.error),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete Audio File'),
                                  onPressed: () async {
                                    final bool? confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext dCtx) {
                                        return AlertDialog(
                                          title:
                                              const Text('Delete Track File?'),
                                          content: Text(
                                            'Are you sure you want to delete "${track.title ?? 'this file'}" from disk?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dCtx).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: cs.error,
                                                foregroundColor: cs.onError,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(dCtx).pop(true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      try {
                                        final api = await ref.read(
                                          lidarrApiProvider(instance).future,
                                        );
                                        await api.trackFile.deleteTrackfileById(
                                          id: file.id ?? 0,
                                        );

                                        ref.invalidate(
                                          lidarrTrackFilesForAlbumProvider(
                                            (instance, albumId),
                                          ),
                                        );
                                        ref.invalidate(
                                          lidarrTracksForAlbumProvider(
                                            (instance, artistId, albumId),
                                          ),
                                        );
                                        ref.invalidate(
                                          lidarrAlbumsForArtistProvider(
                                            (instance, artistId),
                                          ),
                                        );
                                        ref.invalidate(
                                          lidarrArtistByIdProvider(
                                            (instance, artistId),
                                          ),
                                        );
                                        ref.invalidate(
                                          lidarrArtistsProvider(instance),
                                        );

                                        if (context.mounted) {
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Deleted audio file for "${track.title ?? 'track'}"',
                                              ),
                                              backgroundColor: cs.primary,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to delete track file: $e',
                                              ),
                                              backgroundColor: cs.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: ExpressiveProgressIndicator()),
                          ),
                          error: (err, _) => Text(
                            'Failed to load media info: $err',
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
