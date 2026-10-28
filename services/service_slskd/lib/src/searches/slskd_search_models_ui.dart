import '../models/slskd_models.dart';
import '../slskd_format.dart';

/// Available sorting criteria for search results.
enum SlskdSearchSort {
  fastestSpeed,
  highestQuality,
  shortestQueue,
  fileCount;

  String get label => switch (this) {
        SlskdSearchSort.fastestSpeed => 'Fastest Speed',
        SlskdSearchSort.highestQuality => 'Highest Quality (FLAC/Bitrate)',
        SlskdSearchSort.shortestQueue => 'Shortest Queue',
        SlskdSearchSort.fileCount => 'Most Tracks (Full Albums)',
      };
}

/// Available audio format filters for search results.
enum SlskdSearchFormatFilter {
  all,
  flacOnly,
  mp3Only;

  String get label => switch (this) {
        SlskdSearchFormatFilter.all => 'All Formats',
        SlskdSearchFormatFilter.flacOnly => 'FLAC Only',
        SlskdSearchFormatFilter.mp3Only => 'MP3 Only',
      };
}

/// Grouped search results representing an entire album directory from a single peer.
class SlskdAlbumGroup {
  const SlskdAlbumGroup({
    required this.albumDirectory,
    required this.username,
    required this.hasFreeUploadSlot,
    required this.queueLength,
    required this.uploadSpeed,
    required this.files,
  });

  final String albumDirectory;
  final String username;
  final bool hasFreeUploadSlot;
  final int queueLength;
  final int uploadSpeed;
  final List<SlskdSearchFile> files;

  /// Extract friendly album name from full directory path.
  String get albumTitle {
    if (albumDirectory.isEmpty) return 'Loose Tracks';
    final sep = albumDirectory.contains('\\') ? '\\' : '/';
    final parts = albumDirectory.split(sep).where((p) => p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : albumDirectory;
  }

  /// Full total byte size of all tracks in this album directory.
  int get totalSize => files.fold<int>(0, (sum, f) => sum + f.size);

  /// Human formatted size (e.g. '420 MB').
  String get formattedTotalSize => slskdFormatBytes(totalSize);

  /// Formatted upload speed (e.g. '2.5 MB/s').
  String get formattedSpeed => uploadSpeed > 0 ? slskdFormatRate(uploadSpeed) : 'Unknown';

  /// Predominant quality in this folder.
  String get qualityBadge {
    if (files.any((f) => f.extension.toUpperCase() == 'FLAC')) {
      final highRes = files.firstWhere(
        (f) => f.bitDepth != null && f.bitDepth! > 16,
        orElse: () => files.first,
      );
      if (highRes.bitDepth != null && highRes.bitDepth! > 16) {
        return 'FLAC ${highRes.bitDepth}-bit';
      }
      return 'FLAC';
    }
    final maxBitrate = files.fold<int>(0, (max, f) => (f.bitRate ?? 0) > max ? f.bitRate! : max);
    if (maxBitrate > 0) return 'MP3 ${maxBitrate}k';
    return files.isNotEmpty ? files.first.extension.toUpperCase() : 'AUDIO';
  }
}
