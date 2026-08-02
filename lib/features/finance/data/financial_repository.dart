import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/financial_transaction.dart';

class FinancialRepository {
  FinancialRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Nenhum usuário autenticado.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _transactions {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');
  }

  Stream<List<FinancialTransaction>> watchTransactions() {
    return _transactions
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    FinancialTransaction.fromMap(document.id, document.data()),
              )
              .toList(),
        );
  }

  Future<double> availableInvestmentAmount({
    required String category,
    String? excludingTransactionId,
    DateTime? upToDate,
  }) async {
    final snapshot = await _transactions.get();
    var total = 0.0;

    for (final document in snapshot.docs) {
      if (document.id == excludingTransactionId) continue;

      final transaction = FinancialTransaction.fromMap(
        document.id,
        document.data(),
      );

      if (transaction.category != category) continue;
      if (upToDate != null && transaction.date.isAfter(upToDate)) continue;

      if (transaction.isInvestment) {
        total += transaction.amount;
      } else if (transaction.isRedemption) {
        total -= transaction.amount;
      }
    }

    return total;
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    await _transactions.add(transaction.toMap());
  }

  Future<void> updateTransaction(FinancialTransaction transaction) async {
    await _transactions.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }
}
