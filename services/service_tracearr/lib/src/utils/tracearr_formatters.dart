/// Utility formatters for Tracearr UI screens.
library;

/// Checks if a string matches a standard UUID pattern.
bool isUuid(String? text) {
  if (text == null || text.trim().isEmpty) return false;
  final RegExp uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  return uuidRegExp.hasMatch(text.trim());
}

/// Resolves a human-readable server name using a server map, falling back to
/// clean server type descriptors instead of raw UUIDs.
String resolveServerName({
  required Map<String, String> serverMap,
  String? serverName,
  String? serverId,
  String? serverType,
}) {
  if (serverName != null && serverName.trim().isNotEmpty && !isUuid(serverName)) {
    return serverName.trim();
  }

  if (serverId != null && serverMap.containsKey(serverId)) {
    final String? mapped = serverMap[serverId];
    if (mapped != null && mapped.trim().isNotEmpty && !isUuid(mapped)) {
      return mapped.trim();
    }
  }

  final String type = (serverType != null && serverType.trim().isNotEmpty)
      ? serverType.trim().toUpperCase()
      : 'MEDIA';

  if (serverId != null && serverId.trim().isNotEmpty && !isUuid(serverId)) {
    return '$type (${serverId.trim()})';
  }

  return '$type Server';
}

/// Formats ISO timestamps into human-readable exact date and time strings.
String formatTracearrTimestamp(String? isoString) {
  if (isoString == null || isoString.trim().isEmpty) return '';
  try {
    final DateTime dt = DateTime.parse(isoString.trim()).toLocal();
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[dt.month - 1];
    final int hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';

    return '$month ${dt.day}, ${dt.year} at $hour:$minute $period';
  } catch (_) {
    return isoString;
  }
}

/// Formats watch time in milliseconds into human readable hours/minutes format.
String formatTracearrWatchTime(int? watchTimeMs) {
  if (watchTimeMs == null || watchTimeMs <= 0) return '';
  final int totalMinutes = watchTimeMs ~/ 60000;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  return '${minutes}m';
}

/// Formats season and episode numbers into S1 • E4 or Season 1 format.
String formatTracearrSeasonEpisode(int? seasonNumber, int? episodeNumber) {
  if (seasonNumber != null && episodeNumber != null) {
    return 'S$seasonNumber • E$episodeNumber';
  }
  if (seasonNumber != null) {
    return 'Season $seasonNumber';
  }
  if (episodeNumber != null) {
    return 'Episode $episodeNumber';
  }
  return '';
}

/// Formats raw file size byte count into human-readable B, KB, MB, GB, or TB string.
String formatTracearrBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const double kb = 1024;
  const double mb = kb * 1024;
  const double gb = mb * 1024;
  const double tb = gb * 1024;

  if (bytes >= tb) {
    return '${(bytes / tb).toStringAsFixed(1)} TB';
  }
  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(1)} GB';
  }
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(1)} MB';
  }
  if (bytes >= kb) {
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}


