/// An audit or operational event recorded by Cleanuparr.
class CleanuparrEvent {
  const CleanuparrEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    required this.message,
    this.downloadItemTitle,
    this.downloadClientName,
    this.hash,
    this.deleteReason,
  });

  final String id;
  final DateTime timestamp;
  final String eventType;
  final String severity;
  final String message;
  final String? downloadItemTitle;
  final String? downloadClientName;
  final String? hash;
  final String? deleteReason;

  bool get isMalware {
    final String reason = (deleteReason ?? '').toLowerCase();
    final String ev = eventType.toLowerCase();
    return reason.contains('blocked') ||
        reason.contains('malware') ||
        ev.contains('malware');
  }

  bool get isStrike =>
      eventType.toLowerCase().contains('strike');

  bool get isRemoval =>
      eventType.toLowerCase().contains('delet') ||
      eventType.toLowerCase().contains('remov') ||
      eventType.toLowerCase().contains('clean');

  factory CleanuparrEvent.fromJson(Map<String, dynamic> json) {
    DateTime ts = DateTime.now();
    final dynamic rawTs = json['timestamp'] ?? json['createdAt'] ?? json['time'];
    if (rawTs != null) {
      ts = DateTime.tryParse(rawTs.toString()) ?? ts;
    }

    return CleanuparrEvent(
      id: json['id']?.toString() ?? '${ts.millisecondsSinceEpoch}',
      timestamp: ts,
      eventType: json['eventType']?.toString() ??
          json['type']?.toString() ??
          'Event',
      severity: json['severity']?.toString() ??
          (json['level']?.toString() ?? 'Info'),
      message: json['message']?.toString() ??
          (json['description']?.toString() ?? 'Operation completed'),
      downloadItemTitle: json['itemTitle']?.toString() ??
          json['downloadItemTitle']?.toString() ??
          json['title']?.toString() ??
          json['itemName']?.toString(),
      downloadClientName: json['downloadClientName']?.toString() ??
          json['client']?.toString(),
      hash: json['itemHash']?.toString() ??
          json['hash']?.toString() ??
          json['infoHash']?.toString(),
      deleteReason: json['deleteReason']?.toString() ??
          json['cleanReason']?.toString() ??
          json['reason']?.toString(),
    );
  }
}
