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
