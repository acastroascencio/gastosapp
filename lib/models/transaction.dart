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

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.concept,
    required this.category,
    required this.transactionType,
    required this.targetModule,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'concept': concept,
      'category': category,
      'transaction_type': transactionType == TransactionType.gasto ? 'gasto' : 'abono',
      'target_module': targetModule == TargetModule.personal ? 'personal' : 'casa',
    };
  }
}
