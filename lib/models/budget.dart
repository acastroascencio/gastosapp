class Budget {
  final String id;
  final String userId;
  final double limitAmount;
  final String monthYear; // Formato: 'MM-YYYY'

  Budget({
    required this.id,
    required this.userId,
    required this.limitAmount,
    required this.monthYear,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      limitAmount: double.parse(json['limit_amount'].toString()),
      monthYear: json['month_year'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limit_amount': limitAmount,
      'month_year': monthYear,
    };
  }
}
