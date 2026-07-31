import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/financial_repository.dart';
import '../../domain/financial_transaction.dart';
import 'transaction_form_page.dart';

class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage> {
  final FinancialRepository _repository = FinancialRepository();

  Future<void> _openTransactionForm([FinancialTransaction? transaction]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionFormPage(
          repository: _repository,
          transaction: transaction,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FinancialTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir lançamento'),
          content: Text('Deseja excluir "${transaction.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteTransaction(transaction.id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final firstName = displayName == null || displayName.isEmpty
        ? 'Família'
        : displayName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel financeiro'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTransactionForm,
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: _repository.watchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;
          final income = transactions
              .where((transaction) => transaction.isIncome)
              .fold<double>(0, (sum, transaction) => sum + transaction.amount);
          final expenses = transactions
              .where((transaction) => !transaction.isIncome)
              .fold<double>(0, (sum, transaction) => sum + transaction.amount);
          final balance = income - expenses;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Text(
                  'Olá, $firstName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Veja o resumo atualizado das finanças da família.'),
                const SizedBox(height: 20),
                _BalanceCard(balance: balance),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Receitas',
                        value: income,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Despesas',
                        value: expenses,
                        icon: Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'Lançamentos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text('${transactions.length} registro(s)'),
                  ],
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  const _EmptyTransactions()
                else
                  ...transactions.map(
                    (transaction) => _TransactionCard(
                      transaction: transaction,
                      onEdit: () => _openTransactionForm(transaction),
                      onDelete: () => _confirmDelete(transaction),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo atual'),
            const SizedBox(height: 8),
            Text(
              _currency(balance),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 14),
            Text(label),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                _currency(value),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final FinancialTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final signedAmount = transaction.isIncome
        ? transaction.amount
        : -transaction.amount;

    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${transaction.category} • ${_date(transaction.date)}'),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções',
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                _currency(signedAmount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Excluir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhum lançamento ainda',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Use o botão “Novo lançamento” para cadastrar sua primeira receita ou despesa.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os dados.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) {
  final negative = value < 0;
  final absolute = value.abs().toStringAsFixed(2);
  final parts = absolute.split('.');
  final integer = parts[0];
  final decimal = parts[1];
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final reverseIndex = integer.length - index;

    buffer.write(integer[index]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${negative ? '-' : ''}R\$ ${buffer.toString()},$decimal';
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}
