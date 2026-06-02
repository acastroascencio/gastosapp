class DetectedMovement {
  final String id;
  final String userId;
  final String provider; // 'gmail'
  final String bank; // 'BCP'
  final String emailMessageId;
  final double detectedAmount;
  final DateTime detectedDate;
  final String detectedConcept;
  final String detectedCurrency; // 'PEN'
  final String detectedType; // 'expense' | 'income' | 'unknown'
  final String suggestedCategory;
  final String status; // 'pending' | 'approved' | 'ignored'
  final DateTime createdAt;
  final DateTime updatedAt;

  DetectedMovement({
    required this.id,
    required this.userId,
    required this.provider,
    required this.bank,
    required this.emailMessageId,
    required this.detectedAmount,
    required this.detectedDate,
    required this.detectedConcept,
    required this.detectedCurrency,
    required this.detectedType,
    required this.suggestedCategory,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DetectedMovement.fromJson(Map<String, dynamic> json) {
    return DetectedMovement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: json['provider'] as String? ?? 'gmail',
      bank: json['bank'] as String? ?? 'BCP',
      emailMessageId: json['email_message_id'] as String,
      detectedAmount: double.parse(json['detected_amount'].toString()),
      detectedDate: DateTime.parse(json['detected_date'] as String),
      detectedConcept: json['detected_concept'] as String,
      detectedCurrency: json['detected_currency'] as String? ?? 'PEN',
      detectedType: json['detected_type'] as String? ?? 'expense',
      suggestedCategory: json['suggested_category'] as String? ?? 'Otros',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider,
      'bank': bank,
      'email_message_id': emailMessageId,
      'detected_amount': detectedAmount,
      'detected_date': detectedDate.toIso8601String(),
      'detected_concept': detectedConcept,
      'detected_currency': detectedCurrency,
      'detected_type': detectedType,
      'suggested_category': suggestedCategory,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DetectedMovement copyWith({
    String? id,
    String? userId,
    String? provider,
    String? bank,
    String? emailMessageId,
    double? detectedAmount,
    DateTime? detectedDate,
    String? detectedConcept,
    String? detectedCurrency,
    String? detectedType,
    String? suggestedCategory,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DetectedMovement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      bank: bank ?? this.bank,
      emailMessageId: emailMessageId ?? this.emailMessageId,
      detectedAmount: detectedAmount ?? this.detectedAmount,
      detectedDate: detectedDate ?? this.detectedDate,
      detectedConcept: detectedConcept ?? this.detectedConcept,
      detectedCurrency: detectedCurrency ?? this.detectedCurrency,
      detectedType: detectedType ?? this.detectedType,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
