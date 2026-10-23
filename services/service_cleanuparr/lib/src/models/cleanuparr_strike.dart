/// A download item currently holding strikes in Cleanuparr.
class CleanuparrStrikeItem {
  const CleanuparrStrikeItem({
    required this.id,
    required this.title,
    this.downloadClientName = 'Client',
    this.strikeCount = 1,
    this.maxStrikes = 3,
    this.strikes = const <CleanuparrStrikeDetail>[],
    this.hash,
  });

  final String id;
  final String title;
  final String downloadClientName;
  final int strikeCount;
  final int maxStrikes;
  final List<CleanuparrStrikeDetail> strikes;
  final String? hash;

  bool get isMaxed => strikeCount >= maxStrikes;

  factory CleanuparrStrikeItem.fromJson(Map<String, dynamic> json) {
    final String id = json['downloadItemId']?.toString() ??
        json['id']?.toString() ??
        json['hash']?.toString() ??
        '';
    final String title = json['title']?.toString() ??
        json['name']?.toString() ??
        'Unknown Item';
    final String client = json['downloadClientName']?.toString() ??
        json['client']?.toString() ??
        'Client';
    final int count = _asInt(json['strikeCount'] ?? json['strikesCount'] ?? 1);
    final int max = _asInt(json['maxStrikes'] ?? 3);
    final String? h = json['hash']?.toString() ?? json['infoHash']?.toString();

    final List<CleanuparrStrikeDetail> details = <CleanuparrStrikeDetail>[];
    final dynamic rawDetails = json['strikes'] ?? json['strikeDetails'];
    if (rawDetails is List) {
      for (final dynamic d in rawDetails) {
        if (d is Map<String, dynamic>) {
          details.add(CleanuparrStrikeDetail.fromJson(d));
        }
      }
    }

    return CleanuparrStrikeItem(
      id: id,
      title: title,
      downloadClientName: client,
      strikeCount: count > 0 ? count : (details.isNotEmpty ? details.length : 1),
      maxStrikes: max > 0 ? max : 3,
      strikes: List<CleanuparrStrikeDetail>.unmodifiable(details),
      hash: h,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value != null) return int.tryParse(value.toString()) ?? 0;
    return 0;
  }
}

class CleanuparrStrikeDetail {
  const CleanuparrStrikeDetail({
    required this.type,
    this.reason,
    this.createdAt,
    this.isDryRun = false,
  });

  final String type;
  final String? reason;
  final DateTime? createdAt;
  final bool isDryRun;

  factory CleanuparrStrikeDetail.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final dynamic rawDate = json['createdAt'] ?? json['timestamp'];
    if (rawDate != null) {
      created = DateTime.tryParse(rawDate.toString());
    }

    return CleanuparrStrikeDetail(
      type: json['type']?.toString() ?? 'Strike',
      reason: json['reason']?.toString() ?? json['message']?.toString(),
      createdAt: created,
      isDryRun: json['isDryRun'] as bool? ?? false,
    );
  }
}
