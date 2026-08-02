import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/financial_goal.dart';
import '../domain/monthly_budget.dart';

class PlanningRepository {
  PlanningRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _goals =>
      _firestore.collection('users').doc(_uid).collection('goals');

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _firestore.collection('users').doc(_uid).collection('budgets');

  Stream<List<FinancialGoal>> watchGoals() {
    return _goals
        .orderBy('deadline')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinancialGoal.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<MonthlyBudget>> watchBudgets({
    required int month,
    required int year,
  }) {
    return _budgets
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MonthlyBudget.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => a.category.compareTo(b.category)),
        );
  }

  Future<void> saveGoal(FinancialGoal goal) async {
    if (goal.id.isEmpty) {
      await _goals.add(goal.toMap());
    } else {
      await _goals.doc(goal.id).set(goal.toMap());
    }
  }

  Future<void> deleteGoal(String id) async {
    if (id.isEmpty) return;
    await _goals.doc(id).delete();
  }

  Future<void> saveBudget(MonthlyBudget budget) async {
    final existing = await _budgets
        .where('month', isEqualTo: budget.month)
        .where('year', isEqualTo: budget.year)
        .where('category', isEqualTo: budget.category)
        .get();

    final duplicateExists = existing.docs.any((doc) => doc.id != budget.id);

    if (duplicateExists) {
      throw StateError(
        'Já existe um orçamento para ${budget.category} neste mês. '
        'Edite o orçamento existente.',
      );
    }

    if (budget.id.isEmpty) {
      await _budgets.add(budget.toMap());
    } else {
      await _budgets.doc(budget.id).set(budget.toMap());
    }
  }

  Future<void> deleteBudget(String id) async {
    if (id.isEmpty) return;
    await _budgets.doc(id).delete();
  }
}
