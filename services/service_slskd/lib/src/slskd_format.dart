/// Formatting helpers for slskd models and UI.
library;

import 'package:flutter/material.dart';

/// Formats a byte count into a human-readable string (e.g., '12.4 MB', '1.2 GB').
String slskdFormatBytes(num bytes) {
  if (bytes < 1024) {
    return '${bytes.round()} B';
  }
  const List<String> units = <String>['KB', 'MB', 'GB', 'TB', 'PB'];
  double value = bytes / 1024;
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final String text = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// Formats transfer speed (e.g., '1.5 MB/s').
String slskdFormatRate(num bytesPerSecond) => '${slskdFormatBytes(bytesPerSecond)}/s';

/// Formats a duration into short human format ('45s', '3m 20s', '2h 5m').
String slskdFormatDuration(Duration d) {
  if (d.inSeconds <= 0) return '0s';
  if (d.inHours > 0) {
    final mins = d.inMinutes % 60;
    return mins == 0 ? '${d.inHours}h' : '${d.inHours}h ${mins}m';
  }
  if (d.inMinutes > 0) {
    final secs = d.inSeconds % 60;
    return secs == 0 ? '${d.inMinutes}m' : '${d.inMinutes}m ${secs}s';
  }
  return '${d.inSeconds}s';
}

/// Formats a DateTime into a short time string (e.g., '14:32').
String slskdFormatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Formats a DateTime into a time string with seconds (e.g., '14:32:05').
String slskdFormatTimeWithSeconds(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Formats a DateTime into a readable date and time string ('2026-10-24 14:32:05').
String slskdFormatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d ${slskdFormatTimeWithSeconds(dt)}';
}

/// Formats a count with appropriate singular or plural noun.
/// Example: `slskdPluralize(1, 'folder')` -> '1 folder'
///          `slskdPluralize(2, 'folder')` -> '2 folders'
String slskdPluralize(int count, String singular, [String? plural]) {
  final noun = count == 1 ? singular : (plural ?? '${singular}s');
  return '$count $noun';
}

/// Formats combined folder and file counts with proper pluralization.
/// Example: `slskdFormatFolderAndFileCounts(1, 1)` -> '1 folder • 1 file'
///          `slskdFormatFolderAndFileCounts(2, 3)` -> '2 folders • 3 files'
String slskdFormatFolderAndFileCounts(
  int folderCount,
  int fileCount, {
  String fileNoun = 'file',
}) {
  return '${slskdPluralize(folderCount, 'folder')} • ${slskdPluralize(fileCount, fileNoun)}';
}

/// Theme-aware status color for peer presence (Online, Away, Offline).
/// Adheres to Material 3 dynamic color scheme with zero hardcoded hex constants.
Color slskdPresenceColor(ColorScheme colorScheme, {required bool isOnline, bool isAway = false}) {
  if (isOnline) {
    return colorScheme.primary;
  }
  if (isAway) {
    return colorScheme.tertiary;
  }
  return colorScheme.outline;
}

/// Accessible icon hint for peer presence.
IconData slskdPresenceIcon({required bool isOnline, bool isAway = false}) {
  if (isOnline) {
    return Icons.check_circle_rounded;
  }
  if (isAway) {
    return Icons.access_time_rounded;
  }
  return Icons.remove_circle_outline_rounded;
}
