class CategoryLearningRule {
  final String id;
  final String userId;
  final String keyword; // e.g. 'LUZ DEL SUR', 'SEDAPAL'
  final String suggestedCategory;
  final String? suggestedScope; // 'personal' | 'family' | null
  final String? suggestedFamilyId;
  final int confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryLearningRule({
    required this.id,
    required this.userId,
    required this.keyword,
    required this.suggestedCategory,
    this.suggestedScope,
    this.suggestedFamilyId,
    this.confidence = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryLearningRule.fromJson(Map<String, dynamic> json) {
    return CategoryLearningRule(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      keyword: json['keyword'] as String,
      suggestedCategory: json['suggested_category'] as String,
      suggestedScope: json['suggested_scope'] as String?,
      suggestedFamilyId: json['suggested_family_id'] as String?,
      confidence: json['confidence'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'keyword': keyword,
      'suggested_category': suggestedCategory,
      'suggested_scope': suggestedScope,
      'suggested_family_id': suggestedFamilyId,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CategoryLearningRule copyWith({
    String? id,
    String? userId,
    String? keyword,
    String? suggestedCategory,
    String? suggestedScope,
    String? suggestedFamilyId,
    int? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryLearningRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      keyword: keyword ?? this.keyword,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedScope: suggestedScope ?? this.suggestedScope,
      suggestedFamilyId: suggestedFamilyId ?? this.suggestedFamilyId,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
