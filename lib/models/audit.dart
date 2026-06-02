class TransactionAudit {
  final String id;
  final String transactionId;
  final String familyId;
  final String action; // 'created' | 'updated' | 'deleted'
  final String performedBy;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;
  final String? performedByName; // Helper for UI display ("Brenda Castro")

  TransactionAudit({
    required this.id,
    required this.transactionId,
    required this.familyId,
    required this.action,
    required this.performedBy,
    this.previousData,
    this.newData,
    required this.createdAt,
    this.performedByName,
  });

  factory TransactionAudit.fromJson(Map<String, dynamic> json, {String? userFullName}) {
    return TransactionAudit(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      familyId: json['family_id'] as String,
      action: json['action'] as String,
      performedBy: json['performed_by'] as String,
      previousData: json['previous_data'] as Map<String, dynamic>?,
      newData: json['new_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      performedByName: userFullName ?? json['performed_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'family_id': familyId,
      'action': action,
      'performed_by': performedBy,
      'previous_data': previousData,
      'new_data': newData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
