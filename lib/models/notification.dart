class FamilyNotification {
  final String id;
  final String familyId;
  final String recipientUserId;
  final String triggeredBy;
  final String type; // 'transaction_created' | 'transaction_updated' | 'transaction_deleted'
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? triggeredByName; // Helper for visual UI layout ("Mario agregó un gasto...")

  FamilyNotification({
    required this.id,
    required this.familyId,
    required this.recipientUserId,
    required this.triggeredBy,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.triggeredByName,
  });

  factory FamilyNotification.fromJson(Map<String, dynamic> json, {String? triggeredByName}) {
    return FamilyNotification(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      recipientUserId: json['recipient_user_id'] as String,
      triggeredBy: json['triggered_by'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      triggeredByName: triggeredByName ?? json['triggered_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'recipient_user_id': recipientUserId,
      'triggered_by': triggeredBy,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FamilyNotification copyWith({
    String? id,
    String? familyId,
    String? recipientUserId,
    String? triggeredBy,
    String? type,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    String? triggeredByName,
  }) {
    return FamilyNotification(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      triggeredByName: triggeredByName ?? this.triggeredByName,
    );
  }
}
