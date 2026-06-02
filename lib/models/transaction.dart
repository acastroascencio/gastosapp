enum TransactionType { gasto, abono }
enum TargetModule { personal, casa }

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String concept;
  final String category;
  final TransactionType transactionType;
  final TargetModule targetModule;
  final DateTime createdAt;

  // New fields for family, audit and soft-delete support
  final String? familyId;
  final String? updatedBy;
  final bool deleted;
  final String? deletedBy;
  final DateTime? deletedAt;
  final String? createdByName; // Populated helper for UI display ("Registrado por...")

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.concept,
    required this.category,
    required this.transactionType,
    required this.targetModule,
    required this.createdAt,
    this.familyId,
    this.updatedBy,
    this.deleted = false,
    this.deletedBy,
    this.deletedAt,
    this.createdByName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json, {String? userFullName}) {
    final rawCategory = json['category'] as String;
    // Normalize 'Teléfono' or 'Teléfono / Internet' to 'Celular' for unification
    final normalizedCategory = (rawCategory == 'Teléfono' || rawCategory == 'Teléfono / Internet')
        ? 'Celular'
        : rawCategory;

    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: double.parse(json['amount'].toString()),
      concept: json['concept'] as String,
      category: normalizedCategory,
      transactionType: json['transaction_type'] == 'gasto'
          ? TransactionType.gasto
          : TransactionType.abono,
      targetModule: json['target_module'] == 'personal'
          ? TargetModule.personal
          : TargetModule.casa,
      createdAt: DateTime.parse(json['created_at'] as String),
      familyId: json['family_id'] as String?,
      updatedBy: json['updated_by'] as String?,
      deleted: json['deleted'] as bool? ?? false,
      deletedBy: json['deleted_by'] as String?,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      createdByName: userFullName ?? json['created_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'concept': concept,
      'category': category,
      'transaction_type': transactionType == TransactionType.gasto ? 'gasto' : 'abono',
      'target_module': targetModule == TargetModule.personal ? 'personal' : 'casa',
      'family_id': familyId,
      'updated_by': updatedBy,
      'deleted': deleted,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? concept,
    String? category,
    TransactionType? transactionType,
    TargetModule? targetModule,
    DateTime? createdAt,
    String? familyId,
    String? updatedBy,
    bool? deleted,
    String? deletedBy,
    DateTime? deletedAt,
    String? createdByName,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      concept: concept ?? this.concept,
      category: category ?? this.category,
      transactionType: transactionType ?? this.transactionType,
      targetModule: targetModule ?? this.targetModule,
      createdAt: createdAt ?? this.createdAt,
      familyId: familyId ?? this.familyId,
      updatedBy: updatedBy ?? this.updatedBy,
      deleted: deleted ?? this.deleted,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

