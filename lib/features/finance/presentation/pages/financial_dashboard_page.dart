import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
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

        final diagnosis = _buildFinancialDiagnosis(
          monthIncome: monthIncome,
          monthExpenses: monthExpenses,
          savingsRate: savingsRate,
        );

        final recommendations = _buildFinancialRecommendations(
          monthIncome: monthIncome,
          monthExpenses: monthExpenses,
          savingsRate: savingsRate,
          transactions: monthItems,
        );

        final forecast = _buildMonthlyForecast(
          now: now,
          monthIncome: monthIncome,
          monthExpenses: monthExpenses,
        );

        final score = _buildFinancialScore(
          monthIncome: monthIncome,
          monthExpenses: monthExpenses,
          savingsRate: savingsRate,
          forecast: forecast,
        );
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
            const SizedBox(height: 16),
            _MonthComparisonCard(transactions: transactions),
            const SizedBox(height: 16),
            _MonthlyConsolidatedReportCard(transactions: monthItems),
            const SizedBox(height: 16),
            _IncomeExpenseBarChart(transactions: transactions),

            const SizedBox(height: 12),
            _BalanceEvolutionChart(transactions: transactions),

            const SizedBox(height: 12),
            _MonthlySavingsRateChart(transactions: transactions),
            const SizedBox(height: 16),
            _FinancialDiagnosisCard(diagnosis: diagnosis),

            const SizedBox(height: 12),
            _FinancialRecommendationsCard(recommendations: recommendations),

            const SizedBox(height: 12),
            _MonthlyForecastCard(forecast: forecast),

            const SizedBox(height: 12),
            _FinancialScoreCard(score: score),
            const SizedBox(height: 24),
            Text(
              'Despesas por categoria',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _CategoryBars(transactions: monthItems),

            const SizedBox(height: 12),
            _ExpenseCategoryDonutChart(transactions: monthItems),
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

List<String> _buildFinancialRecommendations({
  required double monthIncome,
  required double monthExpenses,
  required double savingsRate,
  required List<FinancialTransaction> transactions,
}) {
  final recommendations = <String>[];
  final monthMargin = monthIncome - monthExpenses;

  final expenseTotals = <String, double>{};
  for (final item in transactions.where((item) => !item.isIncome)) {
    expenseTotals[item.category] =
        (expenseTotals[item.category] ?? 0) + item.amount;
  }

  String? topCategory;
  double topCategoryAmount = 0;
  for (final entry in expenseTotals.entries) {
    if (entry.value > topCategoryAmount) {
      topCategory = entry.key;
      topCategoryAmount = entry.value;
    }
  }

  if (monthIncome == 0 && monthExpenses == 0) {
    recommendations.add(
      'Registre receitas e despesas do mês para receber recomendações personalizadas.',
    );
    recommendations.add(
      'Defina ao menos um orçamento mensal para acompanhar limites por categoria.',
    );
    return recommendations;
  }

  if (monthIncome <= 0 && monthExpenses > 0) {
    recommendations.add(
      'Confira se todas as receitas do mês foram registradas antes de tomar decisões com base no saldo.',
    );
    if (topCategory != null) {
      recommendations.add(
        'Revise os gastos em $topCategory, hoje a categoria com maior despesa no mês (${_currency(topCategoryAmount)}).',
      );
    }
    recommendations.add(
      'Evite novos gastos não essenciais até que as receitas do mês estejam atualizadas.',
    );
    return recommendations;
  }

  if (monthExpenses > monthIncome) {
    final deficit = monthExpenses - monthIncome;
    recommendations.add(
      'Reduza ou adie gastos não essenciais para eliminar o déficit mensal de ${_currency(deficit)}.',
    );
    if (topCategory != null) {
      recommendations.add(
        'Comece por $topCategory, que concentra ${_currency(topCategoryAmount)} das despesas deste mês.',
      );
    }
    recommendations.add(
      'Revise os limites do Planejamento e priorize despesas essenciais até o saldo mensal voltar ao positivo.',
    );
    return recommendations;
  }

  if (savingsRate >= 20) {
    final suggestedGoalAmount = monthMargin * 0.5;
    recommendations.add(
      'Direcione cerca de ${_currency(suggestedGoalAmount)} da sobra do mês para sua principal meta financeira.',
    );
    recommendations.add(
      'Mantenha a taxa de economia acima de 20% e preserve uma reserva para imprevistos.',
    );
    if (topCategory != null) {
      recommendations.add(
        'Continue acompanhando $topCategory, atualmente a maior categoria de despesa do mês.',
      );
    }
    return recommendations;
  }

  if (savingsRate >= 10) {
    recommendations.add(
      'Tente elevar sua economia mensal de ${savingsRate.toStringAsFixed(0)}% para pelo menos 20%.',
    );
    if (topCategory != null) {
      final suggestedReduction = topCategoryAmount * 0.1;
      recommendations.add(
        'Uma redução de 10% em $topCategory liberaria aproximadamente ${_currency(suggestedReduction)} neste mês.',
      );
    }
    recommendations.add(
      'Use parte da margem positiva de ${_currency(monthMargin)} para acelerar uma meta financeira.',
    );
    return recommendations;
  }

  recommendations.add(
    'Sua margem está positiva, mas pequena. Busque chegar a pelo menos 10% de economia mensal.',
  );
  if (topCategory != null) {
    recommendations.add(
      'Revise $topCategory, sua maior categoria de despesa no mês (${_currency(topCategoryAmount)}).',
    );
  }
  recommendations.add(
    'Evite ampliar compromissos fixos enquanto a margem mensal estiver abaixo de 10%.',
  );

  return recommendations;
}

class _FinancialRecommendationsCard extends StatelessWidget {
  const _FinancialRecommendationsCard({required this.recommendations});

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Recomendações para este mês',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...recommendations.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyForecast {
  const _MonthlyForecast({
    required this.averageDailyExpense,
    required this.projectedExpenses,
    required this.projectedBalance,
    required this.daysElapsed,
    required this.daysInMonth,
  });

  final double averageDailyExpense;
  final double projectedExpenses;
  final double projectedBalance;
  final int daysElapsed;
  final int daysInMonth;
}

_MonthlyForecast _buildMonthlyForecast({
  required DateTime now,
  required double monthIncome,
  required double monthExpenses,
}) {
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysElapsed = now.day.clamp(1, daysInMonth);
  final averageDailyExpense = monthExpenses / daysElapsed;
  final projectedExpenses = averageDailyExpense * daysInMonth;
  final projectedBalance = monthIncome - projectedExpenses;

  return _MonthlyForecast(
    averageDailyExpense: averageDailyExpense,
    projectedExpenses: projectedExpenses,
    projectedBalance: projectedBalance,
    daysElapsed: daysElapsed,
    daysInMonth: daysInMonth,
  );
}

class _MonthlyForecastCard extends StatelessWidget {
  const _MonthlyForecastCard({required this.forecast});
  final _MonthlyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = forecast.projectedBalance >= 0;
    final accent = positive ? scheme.primary : scheme.error;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats_outlined, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Previsão até o fim do mês',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estimativa baseada no ritmo médio de despesas dos '
              '${forecast.daysElapsed} primeiros dias de ${forecast.daysInMonth}.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ForecastMetric(
                    label: 'Média diária',
                    value: _currency(forecast.averageDailyExpense),
                    icon: Icons.today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ForecastMetric(
                    label: 'Despesas previstas',
                    value: _currency(forecast.projectedExpenses),
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    positive
                        ? Icons.savings_outlined
                        : Icons.warning_amber_rounded,
                    color: accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      positive
                          ? 'Saldo mensal previsto: ${_currency(forecast.projectedBalance)}'
                          : 'Déficit mensal previsto: ${_currency(forecast.projectedBalance.abs())}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A previsão é uma referência e muda automaticamente conforme novos lançamentos são registrados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  const _ForecastMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(label),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialScore {
  const _FinancialScore({
    required this.value,
    required this.label,
    required this.message,
    required this.level,
    required this.savingsPoints,
    required this.commitmentPoints,
    required this.forecastPoints,
  });

  final int value;
  final String label;
  final String message;
  final _FinancialHealthLevel level;
  final int savingsPoints;
  final int commitmentPoints;
  final int forecastPoints;
}

_FinancialScore _buildFinancialScore({
  required double monthIncome,
  required double monthExpenses,
  required double savingsRate,
  required _MonthlyForecast forecast,
}) {
  final commitmentRate = monthIncome <= 0
      ? (monthExpenses > 0 ? 100.0 : 0.0)
      : (monthExpenses / monthIncome) * 100;

  final savingsPoints = monthIncome <= 0
      ? 0
      : savingsRate >= 20
      ? 40
      : savingsRate >= 10
      ? 30
      : savingsRate >= 0
      ? 15
      : 0;

  final commitmentPoints = monthIncome <= 0
      ? 0
      : commitmentRate <= 70
      ? 35
      : commitmentRate <= 90
      ? 25
      : commitmentRate <= 100
      ? 10
      : 0;

  final forecastPoints = forecast.projectedBalance > 0
      ? 25
      : forecast.projectedBalance == 0
      ? 15
      : 0;

  final rawScore = savingsPoints + commitmentPoints + forecastPoints;
  final value = rawScore.clamp(0, 100);

  if (value >= 80) {
    return _FinancialScore(
      value: value,
      label: 'Excelente',
      message:
          'Sua estrutura financeira está equilibrada. Continue preservando margem, orçamento e metas.',
      level: _FinancialHealthLevel.healthy,
      savingsPoints: savingsPoints,
      commitmentPoints: commitmentPoints,
      forecastPoints: forecastPoints,
    );
  }

  if (value >= 60) {
    return _FinancialScore(
      value: value,
      label: 'Estável',
      message:
          'Sua situação está sob controle, mas ainda há espaço para melhorar a economia e reduzir o comprometimento.',
      level: _FinancialHealthLevel.stable,
      savingsPoints: savingsPoints,
      commitmentPoints: commitmentPoints,
      forecastPoints: forecastPoints,
    );
  }

  if (value >= 35) {
    return _FinancialScore(
      value: value,
      label: 'Atenção',
      message:
          'Alguns indicadores precisam de ajuste. Priorize margem positiva e controle das despesas.',
      level: _FinancialHealthLevel.attention,
      savingsPoints: savingsPoints,
      commitmentPoints: commitmentPoints,
      forecastPoints: forecastPoints,
    );
  }

  return _FinancialScore(
    value: value,
    label: 'Crítica',
    message:
        'Os indicadores atuais mostram risco financeiro. Revise receitas, gastos e orçamento com prioridade.',
    level: _FinancialHealthLevel.critical,
    savingsPoints: savingsPoints,
    commitmentPoints: commitmentPoints,
    forecastPoints: forecastPoints,
  );
}

class _FinancialScoreCard extends StatelessWidget {
  const _FinancialScoreCard({required this.score});

  final _FinancialScore score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = switch (score.level) {
      _FinancialHealthLevel.healthy => scheme.primary,
      _FinancialHealthLevel.stable => scheme.secondary,
      _FinancialHealthLevel.attention => scheme.tertiary,
      _FinancialHealthLevel.critical => scheme.error,
    };

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed_outlined, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pontuação de saúde financeira',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score.value / 100,
                        strokeWidth: 10,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.12),
                      ),
                      Text(
                        '${score.value}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(score.message),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _ScoreChip(
                  label: 'Economia',
                  points: score.savingsPoints,
                  maxPoints: 40,
                ),
                _ScoreChip(
                  label: 'Comprometimento',
                  points: score.commitmentPoints,
                  maxPoints: 35,
                ),
                _ScoreChip(
                  label: 'Previsão',
                  points: score.forecastPoints,
                  maxPoints: 25,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.points,
    required this.maxPoints,
  });

  final String label;
  final int points;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $points/$maxPoints',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MonthlyChartPoint {
  const _MonthlyChartPoint({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
  });

  final int year;
  final int month;
  final double income;
  final double expenses;

  String get label => _monthShort(month);
}

List<_MonthlyChartPoint> _buildMonthlyChartData(
  List<FinancialTransaction> transactions,
) {
  final now = DateTime.now();
  final points = <_MonthlyChartPoint>[];

  for (var offset = 5; offset >= 0; offset--) {
    final date = DateTime(now.year, now.month - offset, 1);
    final items = transactions.where(
      (item) => item.date.year == date.year && item.date.month == date.month,
    );

    var income = 0.0;
    var expenses = 0.0;

    for (final item in items) {
      if (item.isIncome) {
        income += item.amount;
      } else {
        expenses += item.amount;
      }
    }

    points.add(
      _MonthlyChartPoint(
        year: date.year,
        month: date.month,
        income: income,
        expenses: expenses,
      ),
    );
  }

  return points;
}

String _monthShort(int month) {
  const labels = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return labels[month - 1];
}

class _MonthlyConsolidatedReportCard extends StatelessWidget {
  const _MonthlyConsolidatedReportCard({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final income = _sumIncome(transactions);
    final expenses = _sumExpenses(transactions);
    final balance = income - expenses;
    final savingsRate = income <= 0
        ? 0.0
        : ((income - expenses) / income) * 100;

    final expenseTotals = <String, double>{};
    for (final item in transactions.where((item) => !item.isIncome)) {
      expenseTotals[item.category] =
          (expenseTotals[item.category] ?? 0) + item.amount;
    }

    MapEntry<String, double>? topCategory;
    for (final entry in expenseTotals.entries) {
      if (topCategory == null || entry.value > topCategory.value) {
        topCategory = entry;
      }
    }

    final hasIncome = income > 0;
    final positive = balance >= 0 && hasIncome;

    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusMessage;

    if (!hasIncome && expenses > 0) {
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Resultado deficitário';
      statusMessage =
          'Há despesas registradas no mês, mas nenhuma receita. Atualize as entradas para ter uma visão completa.';
    } else if (positive && savingsRate >= 20) {
      statusColor = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_outline_rounded;
      statusTitle = 'Mês positivo';
      statusMessage =
          'As receitas cobriram as despesas e a taxa de economia está em um nível saudável.';
    } else if (positive) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.info_outline_rounded;
      statusTitle = 'Atenção aos gastos';
      statusMessage =
          'O mês está positivo, mas há espaço para aumentar a parcela da renda que sobra após as despesas.';
    } else {
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.trending_down_rounded;
      statusTitle = 'Resultado deficitário';
      statusMessage =
          'As despesas superaram as receitas do mês. Revise os maiores gastos e priorize o equilíbrio do orçamento.';
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize_outlined, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Relatório mensal consolidado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Resumo dos principais indicadores financeiros do mês',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MonthlyReportMetric(
                  label: 'Receitas',
                  value: _currency(income),
                  icon: Icons.trending_up_rounded,
                ),
                _MonthlyReportMetric(
                  label: 'Despesas',
                  value: _currency(expenses),
                  icon: Icons.trending_down_rounded,
                ),
                _MonthlyReportMetric(
                  label: 'Saldo do mês',
                  value: _currency(balance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _MonthlyReportMetric(
                  label: 'Taxa de economia',
                  value: hasIncome ? '${savingsRate.toStringAsFixed(1)}%' : '—',
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      topCategory == null
                          ? 'Maior categoria de gastos: nenhuma despesa registrada'
                          : 'Maior categoria de gastos: ${topCategory.key} (${_currency(topCategory.value)})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(statusIcon, color: statusColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          statusMessage,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyReportMetric extends StatelessWidget {
  const _MonthlyReportMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 225,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthComparisonData {
  const _MonthComparisonData({
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpenses,
    required this.previousExpenses,
  });

  final double currentIncome;
  final double previousIncome;
  final double currentExpenses;
  final double previousExpenses;

  double get currentBalance => currentIncome - currentExpenses;
  double get previousBalance => previousIncome - previousExpenses;
}

_MonthComparisonData _buildMonthComparisonData(
  List<FinancialTransaction> transactions,
) {
  final now = DateTime.now();
  final previousDate = DateTime(now.year, now.month - 1, 1);

  final currentItems = transactions.where(
    (item) => item.date.year == now.year && item.date.month == now.month,
  );
  final previousItems = transactions.where(
    (item) =>
        item.date.year == previousDate.year &&
        item.date.month == previousDate.month,
  );

  double income(Iterable<FinancialTransaction> items) => items
      .where((item) => item.isIncome)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double expenses(Iterable<FinancialTransaction> items) => items
      .where((item) => !item.isIncome)
      .fold<double>(0, (sum, item) => sum + item.amount);

  return _MonthComparisonData(
    currentIncome: income(currentItems),
    previousIncome: income(previousItems),
    currentExpenses: expenses(currentItems),
    previousExpenses: expenses(previousItems),
  );
}

double? _comparisonPercent(double current, double previous) {
  if (previous == 0) return current == 0 ? 0 : null;
  return ((current - previous) / previous.abs()) * 100;
}

class _MonthComparisonCard extends StatelessWidget {
  const _MonthComparisonCard({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final data = _buildMonthComparisonData(transactions);
    final now = DateTime.now();
    final previousDate = DateTime(now.year, now.month - 1, 1);
    final currentLabel = _monthShort(now.month);
    final previousLabel = _monthShort(previousDate.month);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows_rounded,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Comparativo mensal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$currentLabel x $previousLabel — veja como suas finanças mudaram de um mês para o outro',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _MonthComparisonRow(
              title: 'Receitas',
              icon: Icons.trending_up_rounded,
              current: data.currentIncome,
              previous: data.previousIncome,
              higherIsBetter: true,
            ),
            const Divider(height: 24),
            _MonthComparisonRow(
              title: 'Despesas',
              icon: Icons.trending_down_rounded,
              current: data.currentExpenses,
              previous: data.previousExpenses,
              higherIsBetter: false,
            ),
            const Divider(height: 24),
            _MonthComparisonRow(
              title: 'Saldo mensal',
              icon: Icons.account_balance_wallet_outlined,
              current: data.currentBalance,
              previous: data.previousBalance,
              higherIsBetter: true,
              describeSignChange: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthComparisonRow extends StatelessWidget {
  const _MonthComparisonRow({
    required this.title,
    required this.icon,
    required this.current,
    required this.previous,
    required this.higherIsBetter,
    this.describeSignChange = false,
  });

  final String title;
  final IconData icon;
  final double current;
  final double previous;
  final bool higherIsBetter;
  final bool describeSignChange;

  @override
  Widget build(BuildContext context) {
    final percent = _comparisonPercent(current, previous);
    final delta = current - previous;
    final unchanged = delta.abs() < 0.005;
    final improved = unchanged
        ? null
        : higherIsBetter
        ? delta > 0
        : delta < 0;

    final accent = unchanged
        ? const Color(0xFF64748B)
        : improved!
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    final crossedToNegative =
        describeSignChange && previous >= 0 && current < 0;
    final crossedToPositive =
        describeSignChange && previous <= 0 && current > 0;

    final changeText = crossedToNegative
        ? 'Virou negativo'
        : crossedToPositive
        ? 'Virou positivo'
        : percent == null
        ? 'Sem base no mês anterior'
        : unchanged
        ? 'Sem alteração'
        : '${delta > 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';

    final changeIcon = crossedToNegative
        ? Icons.trending_down_rounded
        : crossedToPositive
        ? Icons.trending_up_rounded
        : unchanged
        ? Icons.remove_rounded
        : delta > 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  Text(
                    'Atual: ${_currency(current)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Anterior: ${_currency(previous)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(changeIcon, size: 15, color: accent),
              const SizedBox(width: 3),
              Text(
                changeText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomeExpenseBarChart extends StatelessWidget {
  const _IncomeExpenseBarChart({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final points = _buildMonthlyChartData(transactions);
    final maxValue = points.fold<double>(
      0,
      (current, item) =>
          [current, item.income, item.expenses].reduce((a, b) => a > b ? a : b),
    );
    final chartMax = maxValue <= 0 ? 100.0 : maxValue * 1.22;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Receitas x despesas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _ChartLegend(color: Color(0xFF16A34A), label: 'Receitas'),
                const SizedBox(width: 10),
                const _ChartLegend(color: Color(0xFFF97316), label: 'Despesas'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Comparativo colorido dos últimos 6 meses',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 18,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMax / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[index].label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Receitas' : 'Despesas';
                        return BarTooltipItem(
                          '$type\n${_currency(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: points.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 5,
                      barRods: [
                        BarChartRodData(
                          toY: item.income,
                          width: 13,
                          color: const Color(0xFF16A34A),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                        BarChartRodData(
                          toY: item.expenses,
                          width: 13,
                          color: const Color(0xFFF97316),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ExpenseCategorySlice {
  const _ExpenseCategorySlice({
    required this.category,
    required this.amount,
    required this.color,
  });

  final String category;
  final double amount;
  final Color color;
}

List<_ExpenseCategorySlice> _buildExpenseCategorySlices(
  List<FinancialTransaction> transactions,
) {
  final totals = <String, double>{};

  for (final item in transactions.where((item) => !item.isIncome)) {
    totals[item.category] = (totals[item.category] ?? 0) + item.amount;
  }

  const palette = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFFEAB308),
    Color(0xFFDB2777),
  ];

  final sorted = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;

    return _ExpenseCategorySlice(
      category: item.key,
      amount: item.value,
      color: palette[index % palette.length],
    );
  }).toList();
}

class _ExpenseCategoryDonutChart extends StatefulWidget {
  const _ExpenseCategoryDonutChart({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  State<_ExpenseCategoryDonutChart> createState() =>
      _ExpenseCategoryDonutChartState();
}

class _ExpenseCategoryDonutChartState
    extends State<_ExpenseCategoryDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final slices = _buildExpenseCategorySlices(widget.transactions);
    final total = slices.fold<double>(0, (sum, item) => sum + item.amount);

    if (slices.isEmpty || total <= 0) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.donut_large_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'O gráfico por categoria aparecerá quando houver despesas no mês.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.donut_large_rounded, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Distribuição das despesas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Veja quais categorias mais pesam no orçamento do mês',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;

                final chart = SizedBox(
                  height: 240,
                  width: compact ? double.infinity : 300,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 56,
                      sectionsSpace: 3,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response?.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex =
                                response!.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: slices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final slice = entry.value;
                        final percentage = (slice.amount / total) * 100;
                        final active = index == touchedIndex;

                        return PieChartSectionData(
                          value: slice.amount,
                          color: slice.color,
                          radius: active ? 72 : 62,
                          title: percentage >= 6
                              ? '${percentage.toStringAsFixed(0)}%'
                              : '',
                          titleStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: active ? 15 : 13,
                          ),
                          badgeWidget: active
                              ? _DonutValueBadge(
                                  value: _currency(slice.amount),
                                  color: slice.color,
                                )
                              : null,
                          badgePositionPercentageOffset: 1.25,
                        );
                      }).toList(),
                    ),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                  ),
                );

                final legend = Column(
                  children: slices.map((slice) {
                    final percentage = (slice.amount / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: slice.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slice.category,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Text(_currency(slice.amount)),
                        ],
                      ),
                    );
                  }).toList(),
                );

                if (compact) {
                  return Column(
                    children: [chart, const SizedBox(height: 14), legend],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    const SizedBox(width: 24),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutValueBadge extends StatelessWidget {
  const _DonutValueBadge({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BalanceEvolutionPoint {
  const _BalanceEvolutionPoint({
    required this.year,
    required this.month,
    required this.balance,
  });

  final int year;
  final int month;
  final double balance;

  String get label => _monthShort(month);
}

List<_BalanceEvolutionPoint> _buildBalanceEvolutionData(
  List<FinancialTransaction> transactions,
) {
  final now = DateTime.now();
  final points = <_BalanceEvolutionPoint>[];

  for (var offset = 5; offset >= 0; offset--) {
    final date = DateTime(now.year, now.month - offset, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    var balance = 0.0;

    for (final item in transactions.where(
      (item) => !item.date.isAfter(monthEnd),
    )) {
      balance += item.isIncome ? item.amount : -item.amount;
    }

    points.add(
      _BalanceEvolutionPoint(
        year: date.year,
        month: date.month,
        balance: balance,
      ),
    );
  }

  return points;
}

class _BalanceEvolutionChart extends StatelessWidget {
  const _BalanceEvolutionChart({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final points = _buildBalanceEvolutionData(transactions);
    final values = points.map((item) => item.balance).toList();

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    final spread = (maxValue - minValue).abs();
    final padding = spread <= 0 ? 100.0 : spread * 0.25;
    final minY = minValue - padding;
    final maxY = maxValue + padding;

    const lineColor = Color(0xFF2563EB);
    const areaColor = Color(0xFF60A5FA);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded, color: lineColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evolução do saldo acumulado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Veja como o saldo acumulado (receitas - despesas) evoluiu nos últimos 6 meses',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 245,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[index].label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final index = spot.x.toInt();
                          final point = points[index];
                          return LineTooltipItem(
                            '${point.label}\nSaldo acumulado\n${_currency(point.balance)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.balance,
                        );
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.28,
                      barWidth: 4,
                      color: lineColor,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: lineColor,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: areaColor.withValues(alpha: 0.20),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: lineColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Passe o mouse ou toque nos pontos para ver o saldo acumulado de cada mês.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySavingsRatePoint {
  const _MonthlySavingsRatePoint({
    required this.month,
    required this.rate,
    required this.hasIncome,
  });

  final int month;
  final double rate;
  final bool hasIncome;

  String get label => _monthShort(month);
}

List<_MonthlySavingsRatePoint> _buildMonthlySavingsRateData(
  List<FinancialTransaction> transactions,
) {
  final now = DateTime.now();
  final points = <_MonthlySavingsRatePoint>[];

  for (var offset = 5; offset >= 0; offset--) {
    final date = DateTime(now.year, now.month - offset, 1);
    final items = transactions.where(
      (item) => item.date.year == date.year && item.date.month == date.month,
    );

    var income = 0.0;
    var expenses = 0.0;
    for (final item in items) {
      if (item.isIncome) {
        income += item.amount;
      } else {
        expenses += item.amount;
      }
    }

    final rate = income <= 0 ? 0.0 : ((income - expenses) / income) * 100;

    points.add(
      _MonthlySavingsRatePoint(
        month: date.month,
        rate: rate,
        hasIncome: income > 0,
      ),
    );
  }

  return points;
}

class _MonthlySavingsRateChart extends StatelessWidget {
  const _MonthlySavingsRateChart({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final points = _buildMonthlySavingsRateData(transactions);
    final rates = points.map((item) => item.rate).toList();
    final minRate = rates.reduce((a, b) => a < b ? a : b);
    final maxRate = rates.reduce((a, b) => a > b ? a : b);
    final minY = minRate < 0 ? minRate - 15 : -10.0;
    final maxY = maxRate > 100 ? maxRate + 15 : 110.0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined, color: Color(0xFF16A34A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Taxa de economia mensal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Percentual da renda que sobrou após as despesas em cada mês',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 245,
              child: BarChart(
                BarChartData(
                  minY: minY,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                      strokeWidth: 1,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[index].label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = points[group.x];
                        final text = point.hasIncome
                            ? '${point.label}\nEconomia: ${point.rate.toStringAsFixed(1)}%'
                            : '${point.label}\nSem receita registrada';
                        return BarTooltipItem(
                          text,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: points.asMap().entries.map((entry) {
                    final point = entry.value;
                    final positive = point.rate >= 0;
                    final color = !point.hasIncome
                        ? const Color(0xFF94A3B8)
                        : positive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626);

                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: point.rate,
                          width: 22,
                          color: color,
                          borderRadius: BorderRadius.vertical(
                            top: positive
                                ? const Radius.circular(7)
                                : Radius.zero,
                            bottom: positive
                                ? Radius.zero
                                : const Radius.circular(7),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SavingsRateLegend(
                  color: const Color(0xFF16A34A),
                  label: 'Economia positiva',
                ),
                const SizedBox(width: 14),
                _SavingsRateLegend(
                  color: const Color(0xFFDC2626),
                  label: 'Gastos acima da renda',
                ),
                const SizedBox(width: 14),
                _SavingsRateLegend(
                  color: const Color(0xFF94A3B8),
                  label: 'Sem receita',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsRateLegend extends StatelessWidget {
  const _SavingsRateLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialDiagnosis {
  const _FinancialDiagnosis({
    required this.title,
    required this.message,
    required this.icon,
    required this.commitmentRate,
    required this.monthMargin,
    required this.level,
  });

  final String title;
  final String message;
  final IconData icon;
  final double commitmentRate;
  final double monthMargin;
  final _FinancialHealthLevel level;
}

enum _FinancialHealthLevel { healthy, stable, attention, critical }

_FinancialDiagnosis _buildFinancialDiagnosis({
  required double monthIncome,
  required double monthExpenses,
  required double savingsRate,
}) {
  final monthMargin = monthIncome - monthExpenses;
  final commitmentRate = monthIncome <= 0
      ? (monthExpenses > 0 ? 100.0 : 0.0)
      : (monthExpenses / monthIncome) * 100;

  if (monthIncome == 0 && monthExpenses == 0) {
    return const _FinancialDiagnosis(
      title: 'Mês começando',
      message:
          'Ainda não há movimentações neste mês. Registre receitas e despesas para gerar um diagnóstico.',
      icon: Icons.insights_outlined,
      commitmentRate: 0,
      monthMargin: 0,
      level: _FinancialHealthLevel.stable,
    );
  }

  if (monthIncome <= 0 && monthExpenses > 0) {
    return _FinancialDiagnosis(
      title: 'Atenção às receitas',
      message:
          'Existem despesas no mês, mas nenhuma receita registrada. Confira se as entradas estão atualizadas.',
      icon: Icons.warning_amber_rounded,
      commitmentRate: commitmentRate,
      monthMargin: monthMargin,
      level: _FinancialHealthLevel.attention,
    );
  }

  if (monthExpenses > monthIncome) {
    return _FinancialDiagnosis(
      title: 'Situação crítica',
      message:
          'As despesas do mês já ultrapassaram as receitas. Priorize gastos essenciais e revise os limites do orçamento.',
      icon: Icons.error_outline,
      commitmentRate: commitmentRate,
      monthMargin: monthMargin,
      level: _FinancialHealthLevel.critical,
    );
  }

  if (savingsRate >= 20) {
    return _FinancialDiagnosis(
      title: 'Saúde financeira boa',
      message:
          'Você está preservando pelo menos 20% das receitas do mês. Mantenha o ritmo e direcione parte da sobra para suas metas.',
      icon: Icons.verified_outlined,
      commitmentRate: commitmentRate,
      monthMargin: monthMargin,
      level: _FinancialHealthLevel.healthy,
    );
  }

  if (savingsRate >= 10) {
    return _FinancialDiagnosis(
      title: 'Situação estável',
      message:
          'O mês está positivo, mas ainda há espaço para aumentar a margem de segurança e acelerar suas metas.',
      icon: Icons.trending_up,
      commitmentRate: commitmentRate,
      monthMargin: monthMargin,
      level: _FinancialHealthLevel.stable,
    );
  }

  return _FinancialDiagnosis(
    title: 'Atenção ao orçamento',
    message:
        'A margem do mês está pequena. Revise as categorias com maior gasto para evitar terminar o mês no negativo.',
    icon: Icons.monitor_heart_outlined,
    commitmentRate: commitmentRate,
    monthMargin: monthMargin,
    level: _FinancialHealthLevel.attention,
  );
}

class _FinancialDiagnosisCard extends StatelessWidget {
  const _FinancialDiagnosisCard({required this.diagnosis});

  final _FinancialDiagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (diagnosis.level) {
      _FinancialHealthLevel.healthy => colorScheme.primary,
      _FinancialHealthLevel.stable => colorScheme.secondary,
      _FinancialHealthLevel.attention => colorScheme.tertiary,
      _FinancialHealthLevel.critical => colorScheme.error,
    };

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                  child: Icon(diagnosis.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnóstico financeiro',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        diagnosis.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(diagnosis.message),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _DiagnosticChip(
                  icon: Icons.pie_chart_outline,
                  label:
                      'Comprometimento: ${diagnosis.commitmentRate.toStringAsFixed(0)}%',
                ),
                _DiagnosticChip(
                  icon: diagnosis.monthMargin >= 0
                      ? Icons.savings_outlined
                      : Icons.trending_down,
                  label: 'Margem: ${_currency(diagnosis.monthMargin)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticChip extends StatelessWidget {
  const _DiagnosticChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
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
