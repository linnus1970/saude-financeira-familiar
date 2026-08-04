import 'financial_transaction.dart';

class IncomeExpenseTotals {
  const IncomeExpenseTotals({required this.income, required this.expenses});

  final double income;
  final double expenses;

  double get totalMoved => income + expenses;

  double get incomePercentage =>
      totalMoved == 0 ? 0 : (income / totalMoved) * 100;

  double get expensePercentage =>
      totalMoved == 0 ? 0 : (expenses / totalMoved) * 100;
}

IncomeExpenseTotals incomeExpenseTotals(
  Iterable<FinancialTransaction> transactions,
) {
  var income = 0.0;
  var expenses = 0.0;

  for (final transaction in transactions) {
    if (transaction.isIncome) {
      income += transaction.amount;
    } else if (transaction.isExpense) {
      expenses += transaction.amount;
    }
  }

  return IncomeExpenseTotals(income: income, expenses: expenses);
}

double availableBalance(Iterable<FinancialTransaction> transactions) {
  var balance = 0.0;

  for (final transaction in transactions) {
    balance += switch (transaction.type) {
      TransactionType.income => transaction.amount,
      TransactionType.expense => -transaction.amount,
      TransactionType.investment => -transaction.amount,
      TransactionType.redemption => transaction.amount,
    };
  }

  return balance;
}
