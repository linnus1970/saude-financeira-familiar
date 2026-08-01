import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../planning/data/planning_repository.dart';
import '../../../planning/domain/financial_goal.dart';
import '../../../planning/domain/monthly_budget.dart';
import '../../../planning/presentation/pages/budget_form_page.dart';
import '../../../planning/presentation/pages/goal_form_page.dart';
import '../../data/financial_repository.dart';
import '../../domain/financial_transaction.dart';
import 'transaction_form_page.dart';

class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage> {
  final FinancialRepository _financialRepository = FinancialRepository();
  final PlanningRepository _planningRepository = PlanningRepository();

  int _index = 0;
  DateTime _referenceMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Future<void> _openTransactionForm([FinancialTransaction? transaction]) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionFormPage(
          repository: _financialRepository,
          transaction: transaction,
        ),
      ),
    );
  }

  Future<void> _openGoal([FinancialGoal? goal]) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GoalFormPage(repository: _planningRepository, goal: goal),
      ),
    );
  }

  Future<void> _openBudget([MonthlyBudget? budget]) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BudgetFormPage(
          repository: _planningRepository,
          month: _referenceMonth.month,
          year: _referenceMonth.year,
          budget: budget,
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _referenceMonth = DateTime(
        _referenceMonth.year,
        _referenceMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _OverviewTab(
        financialRepository: _financialRepository,
        planningRepository: _planningRepository,
      ),
      _TransactionsTab(
        repository: _financialRepository,
        onOpen: _openTransactionForm,
      ),
      _PlanningTab(
        financialRepository: _financialRepository,
        planningRepository: _planningRepository,
        referenceMonth: _referenceMonth,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onOpenGoal: _openGoal,
        onOpenBudget: _openBudget,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_index) {
          0 => 'Visão geral',
          1 => 'Lançamentos',
          _ => 'Planejamento',
        }),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => _openTransactionForm(),
              icon: const Icon(Icons.add),
              label: const Text('Novo lançamento'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Lançamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Planejamento',
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.financialRepository,
    required this.planningRepository,
  });

  final FinancialRepository financialRepository;
  final PlanningRepository planningRepository;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final firstName = displayName == null || displayName.isEmpty
        ? 'Família'
        : displayName.split(' ').first;

    return StreamBuilder<List<FinancialTransaction>>(
      stream: financialRepository.watchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorView(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!;
        final now = DateTime.now();
        final monthItems = transactions
            .where(
              (item) =>
                  item.date.year == now.year && item.date.month == now.month,
            )
            .toList();

        final monthIncome = _sumIncome(monthItems);
        final monthExpenses = _sumExpenses(monthItems);
        final balance = _sumIncome(transactions) - _sumExpenses(transactions);
        final savingsRate = monthIncome <= 0
            ? 0.0
            : ((monthIncome - monthExpenses) / monthIncome) * 100;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              'Olá, $firstName!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Seu panorama financeiro em um só lugar.'),
            const SizedBox(height: 20),
            _HeroBalanceCard(balance: balance, savingsRate: savingsRate),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Receitas do mês',
                    value: _currency(monthIncome),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Despesas do mês',
                    value: _currency(monthExpenses),
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Despesas por categoria',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _CategoryBars(transactions: monthItems),
            const SizedBox(height: 24),
            Text(
              'Metas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<FinancialGoal>>(
              stream: planningRepository.watchGoals(),
              builder: (context, goalSnapshot) {
                if (!goalSnapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final goals = goalSnapshot.data!;
                if (goals.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Crie metas na aba Planejamento para acompanhar seus objetivos.',
                      ),
                    ),
                  );
                }

                return Column(
                  children: goals.take(3).map((goal) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text('${(goal.progress * 100).round()}%'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: goal.progress),
                            const SizedBox(height: 8),
                            Text(
                              '${_currency(goal.currentAmount)} de '
                              '${_currency(goal.targetAmount)}',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab({required this.repository, required this.onOpen});

  final FinancialRepository repository;
  final Future<void> Function([FinancialTransaction?]) onOpen;

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: widget.repository.watchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorView(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data!;
        if (_filter == 'Receitas') {
          items = items.where((item) => item.isIncome).toList();
        } else if (_filter == 'Despesas') {
          items = items.where((item) => !item.isIncome).toList();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Todos', label: Text('Todos')),
                ButtonSegment(value: 'Receitas', label: Text('Receitas')),
                ButtonSegment(value: 'Despesas', label: Text('Despesas')),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nenhum lançamento',
                message: 'Cadastre receitas e despesas para começar.',
              )
            else
              ...items.map(
                (transaction) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        transaction.isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      ),
                    ),
                    title: Text(transaction.description),
                    subtitle: Text(
                      '${transaction.category} • ${_date(transaction.date)}',
                    ),
                    trailing: Text(
                      _currency(
                        transaction.isIncome
                            ? transaction.amount
                            : -transaction.amount,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => widget.onOpen(transaction),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanningTab extends StatelessWidget {
  const _PlanningTab({
    required this.financialRepository,
    required this.planningRepository,
    required this.referenceMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenGoal,
    required this.onOpenBudget,
  });

  final FinancialRepository financialRepository;
  final PlanningRepository planningRepository;
  final DateTime referenceMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function([FinancialGoal?]) onOpenGoal;
  final Future<void> Function([MonthlyBudget?]) onOpenBudget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: financialRepository.watchTransactions(),
      builder: (context, transactionSnapshot) {
        final transactions =
            transactionSnapshot.data ?? const <FinancialTransaction>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(referenceMonth),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orçamento mensal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => onOpenBudget(),
                  icon: const Icon(Icons.add),
                  label: const Text('Orçamento'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<MonthlyBudget>>(
              stream: planningRepository.watchBudgets(
                month: referenceMonth.month,
                year: referenceMonth.year,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                final budgets = snapshot.data!;
                if (budgets.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Sem orçamento definido',
                    message:
                        'Defina limites por categoria para controlar os gastos.',
                  );
                }

                return Column(
                  children: budgets.map((budget) {
                    final spent = transactions
                        .where(
                          (item) =>
                              !item.isIncome &&
                              item.category == budget.category &&
                              item.date.month == budget.month &&
                              item.date.year == budget.year,
                        )
                        .fold<double>(0, (sum, item) => sum + item.amount);
                    final ratio = budget.limit <= 0
                        ? 0.0
                        : spent / budget.limit;
                    final progress = ratio.clamp(0.0, 1.0);
                    final exceeded = spent > budget.limit;
                    final excess = exceeded ? spent - budget.limit : 0.0;

                    return Card(
                      child: ListTile(
                        title: Text(budget.category),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 4),
                            Text(
                              '${_currency(spent)} de ${_currency(budget.limit)} (${(ratio * 100).round()}%)',
                            ),
                            if (exceeded) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Orçamento excedido em ${_currency(excess)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'Editar',
                          onPressed: () => onOpenBudget(budget),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Metas financeiras',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => onOpenGoal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Meta'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<FinancialGoal>>(
              stream: planningRepository.watchGoals(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                final goals = snapshot.data!;
                if (goals.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'Nenhuma meta',
                    message: 'Crie uma meta de reserva, viagem ou compra.',
                  );
                }

                return Column(
                  children: goals.map((goal) {
                    return Card(
                      child: InkWell(
                        onTap: () => onOpenGoal(goal),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text('${(goal.progress * 100).round()}%'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(value: goal.progress),
                              const SizedBox(height: 8),
                              Text(
                                '${_currency(goal.currentAmount)} / '
                                '${_currency(goal.targetAmount)}',
                              ),
                              const SizedBox(height: 4),
                              Text('Prazo: ${_date(goal.deadline)}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.balance, required this.savingsRate});

  final double balance;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo total'),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: Text(
                      _currency(balance),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const Text('Economia'),
                const SizedBox(height: 8),
                Text(
                  '${savingsRate.toStringAsFixed(0)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
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

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final item in transactions.where((item) => !item.isIncome)) {
      totals[item.category] = (totals[item.category] ?? 0) + item.amount;
    }

    if (totals.isEmpty) {
      return const _EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'Sem despesas neste mês',
        message: 'Os gastos por categoria aparecerão aqui.',
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.first.value;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: sorted.take(5).map((entry) {
            final ratio = maxValue <= 0 ? 0.0 : entry.value / maxValue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text(_currency(entry.value)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: ratio),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
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
        child: Text(
          'Não foi possível carregar os dados.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

double _sumIncome(List<FinancialTransaction> items) => items
    .where((item) => item.isIncome)
    .fold(0, (sum, item) => sum + item.amount);

double _sumExpenses(List<FinancialTransaction> items) => items
    .where((item) => !item.isIncome)
    .fold(0, (sum, item) => sum + item.amount);

String _currency(double value) {
  final negative = value < 0;
  final absolute = value.abs().toStringAsFixed(2);
  final parts = absolute.split('.');
  final integer = parts[0];
  final decimal = parts[1];
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;
    buffer.write(integer[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }

  return '${negative ? '-' : ''}R\$ ${buffer.toString()},$decimal';
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _monthLabel(DateTime value) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[value.month - 1]} ${value.year}';
}
