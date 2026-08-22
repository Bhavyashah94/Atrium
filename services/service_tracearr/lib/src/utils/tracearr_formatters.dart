import 'package:intl/intl.dart';

/// Helper utilities for formatting bytes, durations and dates in Tracearr.
///
/// Image URLs are not built here. Posters and avatars go through
/// `TracearrMediaUrlResolver.buildProxyPosterUrl`, which targets Tracearr's
/// deliberately unauthenticated image proxy and so never carries a token.
abstract class TracearrFormatters {
  /// Formats byte counts into human-readable strings (e.g., 570.1 GB).
  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    if (gb < 1024) return '${gb.toStringAsFixed(1)} GB';
    final tb = gb / 1024;
    return '${tb.toStringAsFixed(2)} TB';
  }

  /// Formats ISO date string into readable date (e.g., "Aug 11, 2026").
  static String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }

  /// Formats millisecond duration into "1h 45m" or "22m".
  static String formatDurationMs(int? durationMs) {
    if (durationMs == null || durationMs <= 0) return '0m';
    final seconds = durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return '${hours}h ${remMinutes}m';
  }

  /// Formats DateTime to relative string (e.g. "12m ago", "2h ago", "Yesterday", "MMM d").
  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date.toLocal());
  }
}
