import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialGoal {
  const FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final DateTime createdAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  Map<String, Object?> toMap() => {
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': Timestamp.fromDate(deadline),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory FinancialGoal.fromMap(String id, Map<String, Object?> map) {
    final deadline = map['deadline'];
    final createdAt = map['createdAt'];

    return FinancialGoal(
      id: id,
      name: map['name'] as String? ?? '',
      targetAmount: (map['targetAmount'] as num? ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] as num? ?? 0).toDouble(),
      deadline: deadline is Timestamp ? deadline.toDate() : DateTime.now(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
