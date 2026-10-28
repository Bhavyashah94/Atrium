/// Data models for slskd Community (Chat Rooms and Direct Messages).
library;

import 'slskd_browse_models.dart';

enum MessageDirection {
  inbound,
  outbound;

  static MessageDirection fromJson(dynamic v) {
    if (v == 0) return MessageDirection.outbound;
    if (v == 1) return MessageDirection.inbound;
    final s = v?.toString().toLowerCase() ?? '';
    if (s.contains('out') || s == '0') {
      return MessageDirection.outbound;
    }
    return MessageDirection.inbound;
  }

  String toJson() => name;
}

class SlskdRoom {
  const SlskdRoom({
    required this.name,
    this.userCount,
    this.isPrivate = false,
    this.isOwned = false,
    this.isModerated = false,
    this.operatorCount,
    this.operators = const [],
    this.owner,
    this.users = const [],
    this.messages = const [],
  });

  factory SlskdRoom.fromJson(Map<String, dynamic> json) {
    List<String> parseOperators(dynamic raw) {
      if (raw is Iterable) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    }

    List<SlskdUserPresence> parseUsers(dynamic raw) {
      final List<SlskdUserPresence> list = [];
      if (raw is Iterable) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            list.add(SlskdUserPresence.fromJson(item));
          }
        }
      }
      return list;
    }

    List<SlskdRoomMessage> parseMessages(dynamic raw) {
      final List<SlskdRoomMessage> list = [];
      if (raw is Iterable) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            list.add(SlskdRoomMessage.fromJson(item));
          }
        }
      }
      return list;
    }

    final usersList = parseUsers(json['users'] ?? json['Users']);
    final int? count = (json['userCount'] ?? json['UserCount']) as int?;

    return SlskdRoom(
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      userCount: count ?? (usersList.isNotEmpty ? usersList.length : null),
      isPrivate: (json['isPrivate'] ?? json['IsPrivate'] ?? false) as bool? ?? false,
      isOwned: (json['isOwned'] ?? json['IsOwned'] ?? false) as bool? ?? false,
      isModerated: (json['isModerated'] ?? json['IsModerated'] ?? false) as bool? ?? false,
      operatorCount: (json['operatorCount'] ?? json['OperatorCount']) as int?,
      operators: parseOperators(json['operators'] ?? json['Operators']),
      owner: (json['owner'] ?? json['Owner'])?.toString(),
      users: usersList,
      messages: parseMessages(json['messages'] ?? json['Messages']),
    );
  }

  final String name;
  final int? userCount;
  final bool isPrivate;
  final bool isOwned;
  final bool isModerated;
  final int? operatorCount;
  final List<String> operators;
  final String? owner;
  final List<SlskdUserPresence> users;
  final List<SlskdRoomMessage> messages;

  int get memberCount => userCount ?? users.length;

  Map<String, dynamic> toJson() => {
        'name': name,
        'isPrivate': isPrivate,
        'isOwned': isOwned,
        'isModerated': isModerated,
        if (userCount != null) 'userCount': userCount,
        if (operatorCount != null) 'operatorCount': operatorCount,
        'operators': operators,
        if (owner != null) 'owner': owner,
        'users': users.map((u) => u.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}

class SlskdRoomMessage {
  const SlskdRoomMessage({
    required this.timestamp,
    required this.username,
    required this.message,
    required this.roomName,
    this.self = false,
  });

  factory SlskdRoomMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return SlskdRoomMessage(
      timestamp: parseDate(json['timestamp'] ?? json['Timestamp']) ?? DateTime.now(),
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      roomName: (json['roomName'] ?? json['RoomName'] ?? '').toString(),
      self: (json['self'] ?? json['Self'] ?? false) as bool? ?? false,
    );
  }

  final DateTime timestamp;
  final String username;
  final String message;
  final String roomName;
  final bool self;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'username': username,
        'message': message,
        'roomName': roomName,
        'self': self,
      };
}

class SlskdConversation {
  const SlskdConversation({
    required this.username,
    this.isActive = true,
    this.unAcknowledgedMessageCount = 0,
    this.messages = const [],
  });

  factory SlskdConversation.fromJson(Map<String, dynamic> json) {
    final msgsRaw = json['messages'] ?? json['Messages'];
    final List<SlskdPrivateMessage> msgList = [];
    if (msgsRaw is Iterable) {
      for (final item in msgsRaw) {
        if (item is Map<String, dynamic>) {
          msgList.add(SlskdPrivateMessage.fromJson(item));
        }
      }
    }

    return SlskdConversation(
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      isActive: (json['isActive'] ?? json['IsActive'] ?? true) as bool? ?? true,
      unAcknowledgedMessageCount: (json['unAcknowledgedMessageCount'] ??
              json['UnAcknowledgedMessageCount'] ??
              0) as int? ??
          0,
      messages: msgList,
    );
  }

  final String username;
  final bool isActive;
  final int unAcknowledgedMessageCount;
  final List<SlskdPrivateMessage> messages;

  bool get hasUnAcknowledgedMessages => unAcknowledgedMessageCount > 0;

  SlskdPrivateMessage? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  Map<String, dynamic> toJson() => {
        'username': username,
        'isActive': isActive,
        'unAcknowledgedMessageCount': unAcknowledgedMessageCount,
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}

class SlskdPrivateMessage {
  const SlskdPrivateMessage({
    required this.id,
    required this.username,
    required this.timestamp,
    required this.direction,
    required this.message,
    this.isAcknowledged = false,
    this.wasReplayed = false,
  });

  factory SlskdPrivateMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return SlskdPrivateMessage(
      id: ((json['id'] ?? json['Id'] ?? 0) as num).toInt(),
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      timestamp: parseDate(json['timestamp'] ?? json['Timestamp']) ?? DateTime.now(),
      direction: MessageDirection.fromJson(json['direction'] ?? json['Direction']),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      isAcknowledged: (json['isAcknowledged'] ?? json['IsAcknowledged'] ?? false) as bool? ?? false,
      wasReplayed: (json['wasReplayed'] ?? json['WasReplayed'] ?? false) as bool? ?? false,
    );
  }

  final int id;
  final String username;
  final DateTime timestamp;
  final MessageDirection direction;
  final String message;
  final bool isAcknowledged;
  final bool wasReplayed;

  bool get isOutbound => direction == MessageDirection.outbound;
  bool get isInbound => direction == MessageDirection.inbound;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'timestamp': timestamp.toIso8601String(),
        'direction': direction.toJson(),
        'message': message,
        'isAcknowledged': isAcknowledged,
        'wasReplayed': wasReplayed,
      };
}

class SlskdRoomInfo {
  const SlskdRoomInfo({
    required this.name,
    this.userCount = 0,
    this.isPrivate = false,
    this.isOwned = false,
    this.isModerated = false,
  });

  factory SlskdRoomInfo.fromJson(Map<String, dynamic> json) {
    return SlskdRoomInfo(
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      userCount: ((json['userCount'] ?? json['UserCount'] ?? 0) as num).toInt(),
      isPrivate: (json['isPrivate'] ?? json['IsPrivate'] ?? false) as bool? ?? false,
      isOwned: (json['isOwned'] ?? json['IsOwned'] ?? false) as bool? ?? false,
      isModerated: (json['isModerated'] ?? json['IsModerated'] ?? false) as bool? ?? false,
    );
  }

  final String name;
  final int userCount;
  final bool isPrivate;
  final bool isOwned;
  final bool isModerated;

  Map<String, dynamic> toJson() => {
        'name': name,
        'userCount': userCount,
        'isPrivate': isPrivate,
        'isOwned': isOwned,
        'isModerated': isModerated,
      };
}
