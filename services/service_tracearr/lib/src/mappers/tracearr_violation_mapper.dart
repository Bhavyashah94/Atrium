import '../generated/models/violation.dart';
import '../models/tracearr_models.dart';

/// Pure transformation from raw [Violation] DTO to domain [TracearrViolationItem].
class TracearrViolationMapper {
  const TracearrViolationMapper._();

  static TracearrViolationItem fromDto(Violation item) {
    String ruleName = 'Security Policy';
    if (item.rule != null) {
      if (item.rule is String) {
        ruleName = item.rule as String;
      } else if (item.rule is Map<String, dynamic>) {
        final m = item.rule as Map<String, dynamic>;
        ruleName = (m['name'] as String?) ?? (m['id'] as String?) ?? ruleName;
      }
    }

    String? userId;
    String userName = 'Unknown';
    if (item.user != null) {
      if (item.user is String) {
        userName = item.user as String;
      } else if (item.user is Map<String, dynamic>) {
        final m = item.user as Map<String, dynamic>;
        userId = (m['id'] as String?) ?? (m['userId'] as String?);
        userName = (m['username'] as String?) ?? userName;
      }
    }

    String? description;
    if (item.data != null) {
      if (item.data is String) {
        description = item.data as String;
      } else if (item.data is Map<String, dynamic>) {
        final m = item.data as Map<String, dynamic>;
        description = (m['description'] as String?) ??
            (m['message'] as String?) ??
            (m['reason'] as String?);
      }
    }

    return TracearrViolationItem(
      id: item.id ?? '',
      serverId: item.serverId ?? '',
      serverName: item.serverName ?? '',
      severity: item.severity ?? 'info',
      rule: ruleName,
      username: userName,
      userId: userId,
      createdAt:
          item.createdAt != null ? DateTime.tryParse(item.createdAt!) : null,
      description: description,
      acknowledged: item.acknowledged ?? false,
    );
  }

  static List<TracearrViolationItem> fromDtoList(List<Violation>? list) {
    if (list == null || list.isEmpty) return const [];
    return list.map(fromDto).toList();
  }
}
