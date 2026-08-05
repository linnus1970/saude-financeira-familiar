import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saude_financeira_familiar/features/finance/domain/financial_transaction.dart';

void main() {
  FinancialTransaction transactionOf(TransactionType type) {
    return FinancialTransaction(
      id: 'transaction-id',
      description: 'Lançamento de teste',
      amount: 150,
      type: type,
      category: 'Teste',
      date: DateTime(2026, 8, 3),
      createdAt: DateTime(2026, 8, 3, 10),
    );
  }

  test('cada tipo de lançamento possui somente sua classificação', () {
    final income = transactionOf(TransactionType.income);
    final expense = transactionOf(TransactionType.expense);
    final investment = transactionOf(TransactionType.investment);
    final redemption = transactionOf(TransactionType.redemption);

    expect(income.isIncome, isTrue);
    expect(income.isExpense, isFalse);

    expect(expense.isExpense, isTrue);
    expect(expense.isInvestment, isFalse);

    expect(investment.isInvestment, isTrue);
    expect(investment.isExpense, isFalse);

    expect(redemption.isRedemption, isTrue);
    expect(redemption.isExpense, isFalse);
  });

  test('mapeamento do Firestore preserva os quatro tipos', () {
    for (final type in TransactionType.values) {
      final original = transactionOf(type);
      final restored = FinancialTransaction.fromMap(
        original.id,
        original.toMap(),
      );

      expect(restored.type, type);
      expect(restored.amount, original.amount);
      expect(restored.date, original.date);
      expect(restored.createdAt, original.createdAt);
      expect(original.toMap()['date'], isA<Timestamp>());
    }
  });
}
