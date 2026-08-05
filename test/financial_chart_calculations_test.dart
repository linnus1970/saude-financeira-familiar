import 'package:flutter_test/flutter_test.dart';
import 'package:saude_financeira_familiar/features/finance/domain/financial_chart_calculations.dart';
import 'package:saude_financeira_familiar/features/finance/domain/financial_transaction.dart';

void main() {
  FinancialTransaction transaction(TransactionType type, double amount) {
    return FinancialTransaction(
      id: '${type.name}-$amount',
      description: 'Teste',
      amount: amount,
      type: type,
      category: 'Teste',
      date: DateTime(2026, 8, 1),
      createdAt: DateTime(2026, 8, 1),
    );
  }

  test('percentuais são zero quando não há movimentação', () {
    final totals = incomeExpenseTotals(const []);

    expect(totals.totalMoved, 0);
    expect(totals.incomePercentage, 0);
    expect(totals.expensePercentage, 0);
  });

  test('comparativo considera somente receitas e despesas', () {
    final totals = incomeExpenseTotals([
      transaction(TransactionType.income, 8500),
      transaction(TransactionType.expense, 3950),
      transaction(TransactionType.investment, 2000),
      transaction(TransactionType.redemption, 500),
    ]);

    expect(totals.income, 8500);
    expect(totals.expenses, 3950);
    expect(totals.incomePercentage, closeTo(68.273, 0.001));
    expect(totals.expensePercentage, closeTo(31.727, 0.001));
  });

  test('saldo disponível reduz investimento e aumenta resgate', () {
    final balance = availableBalance([
      transaction(TransactionType.income, 10000),
      transaction(TransactionType.expense, 2500),
      transaction(TransactionType.investment, 1800),
      transaction(TransactionType.redemption, 600),
    ]);

    expect(balance, 6300);
  });
}
