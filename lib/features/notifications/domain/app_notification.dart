enum NotificationType {
  reminder,
  requestStatus,
  system;

  static NotificationType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'reminder':
        return NotificationType.reminder;
      case 'request_status':
      case 'requeststatus':
        return NotificationType.requestStatus;
      default:
        return NotificationType.system;
    }
  }

  String get dbValue {
    switch (this) {
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.requestStatus:
        return 'request_status';
      case NotificationType.system:
        return 'system';
    }
  }
}

/// Entitas domain notifikasi aplikasi sesuai PRD Bagian 5.2 (Tabel notifications)
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.relatedId,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    String? relatedId,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.dbValue,
      'is_read': isRead,
      if (relatedId != null) 'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      type: NotificationType.fromString((json['type'] ?? 'system') as String),
      isRead: (json['is_read'] ?? false) as bool,
      relatedId: json['related_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isRead == other.isRead &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ isRead.hashCode ^ title.hashCode;
}
