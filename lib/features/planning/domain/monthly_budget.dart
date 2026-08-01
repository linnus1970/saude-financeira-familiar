import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyBudget {
  const MonthlyBudget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  final String id;
  final String category;
  final double limit;
  final int month;
  final int year;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'category': category,
    'limit': limit,
    'month': month,
    'year': year,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MonthlyBudget.fromMap(String id, Map<String, Object?> map) {
    final createdAt = map['createdAt'];

    return MonthlyBudget(
      id: id,
      category: map['category'] as String? ?? 'Outros',
      limit: (map['limit'] as num? ?? 0).toDouble(),
      month: map['month'] as int? ?? DateTime.now().month,
      year: map['year'] as int? ?? DateTime.now().year,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
