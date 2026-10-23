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

  bool get isMalware =>
      eventType.toLowerCase().contains('malware') ||
      severity.toLowerCase() == 'critical' ||
      (deleteReason?.toLowerCase().contains('malware') ?? false);

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
      downloadItemTitle: json['downloadItemTitle']?.toString() ??
          json['title']?.toString() ??
          json['itemName']?.toString(),
      downloadClientName: json['downloadClientName']?.toString() ??
          json['client']?.toString(),
      hash: json['hash']?.toString() ?? json['infoHash']?.toString(),
      deleteReason: json['deleteReason']?.toString() ??
          json['reason']?.toString(),
    );
  }
}
