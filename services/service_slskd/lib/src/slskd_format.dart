/// Formatting helpers for slskd models and UI.
library;

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
