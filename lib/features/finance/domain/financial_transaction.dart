import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;

  FinancialTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FinancialTransaction.fromMap(String id, Map<String, Object?> map) {
    final dateValue = map['date'];
    final createdAtValue = map['createdAt'];

    return FinancialTransaction(
      id: id,
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      type: (map['type'] as String?) == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      category: map['category'] as String? ?? 'Outros',
      date: dateValue is Timestamp ? dateValue.toDate() : DateTime.now(),
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }
}
