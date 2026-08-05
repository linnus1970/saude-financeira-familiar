part of 'financial_dashboard_page.dart';

class _FinancialTrendsCard extends StatelessWidget {
  const _FinancialTrendsCard({required this.transactions});
  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final previousDate = DateTime(now.year, now.month - 1, 1);
    final current = transactions
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final previous = transactions
        .where(
          (e) =>
              e.date.year == previousDate.year &&
              e.date.month == previousDate.month,
        )
        .toList();

    final currentIncome = _sumIncome(current);
    final previousIncome = _sumIncome(previous);
    final currentExpenses = _sumExpenses(current);
    final previousExpenses = _sumExpenses(previous);
    final currentBalance = currentIncome - currentExpenses;
    final previousBalance = previousIncome - previousExpenses;

    final currentCats = <String, double>{};
    final previousCats = <String, double>{};
    for (final e in current.where((e) => !e.isIncome)) {
      currentCats[e.category] = (currentCats[e.category] ?? 0) + e.amount;
    }
    for (final e in previous.where((e) => !e.isIncome)) {
      previousCats[e.category] = (previousCats[e.category] ?? 0) + e.amount;
    }

    String? increaseCat;
    double increase = 0;
    String? reductionCat;
    double reduction = 0;
    for (final cat in {...currentCats.keys, ...previousCats.keys}) {
      final delta = (currentCats[cat] ?? 0) - (previousCats[cat] ?? 0);
      if (delta > increase) {
        increase = delta;
        increaseCat = cat;
      }
      if (delta < reduction) {
        reduction = delta;
        reductionCat = cat;
      }
    }

    final items =
        <({String title, String message, IconData icon, Color color})>[];
    void add(String title, String message, IconData icon, Color color) =>
        items.add((title: title, message: message, icon: icon, color: color));

    final incomeDelta = currentIncome - previousIncome;
    if (incomeDelta > 0.005) {
      add(
        'Receitas cresceram',
        'As entradas aumentaram ${_currency(incomeDelta)}.',
        Icons.trending_up_rounded,
        const Color(0xFF16A34A),
      );
    } else if (incomeDelta < -0.005) {
      add(
        'Receitas diminuíram',
        'As entradas caíram ${_currency(incomeDelta.abs())}.',
        Icons.trending_down_rounded,
        const Color(0xFFDC2626),
      );
    } else {
      add(
        'Receitas estáveis',
        'As receitas permaneceram no mesmo nível.',
        Icons.horizontal_rule_rounded,
        const Color(0xFF64748B),
      );
    }

    final expenseDelta = currentExpenses - previousExpenses;
    if (expenseDelta > 0.005) {
      add(
        'Despesas aumentaram',
        'Os gastos cresceram ${_currency(expenseDelta)}.',
        Icons.north_east_rounded,
        const Color(0xFFDC2626),
      );
    } else if (expenseDelta < -0.005) {
      add(
        'Despesas diminuíram',
        'Os gastos foram reduzidos em ${_currency(expenseDelta.abs())}.',
        Icons.south_east_rounded,
        const Color(0xFF16A34A),
      );
    } else {
      add(
        'Despesas estáveis',
        'Os gastos permaneceram no mesmo nível.',
        Icons.horizontal_rule_rounded,
        const Color(0xFF64748B),
      );
    }

    final balanceDelta = currentBalance - previousBalance;
    if (previousBalance >= 0 && currentBalance < 0) {
      add(
        'Saldo virou negativo',
        'O resultado passou de ${_currency(previousBalance)} para ${_currency(currentBalance)}.',
        Icons.warning_amber_rounded,
        const Color(0xFFDC2626),
      );
    } else if (previousBalance <= 0 && currentBalance > 0) {
      add(
        'Saldo virou positivo',
        'O resultado passou de ${_currency(previousBalance)} para ${_currency(currentBalance)}.',
        Icons.check_circle_outline_rounded,
        const Color(0xFF16A34A),
      );
    } else if (balanceDelta > 0.005) {
      add(
        'Saldo melhorou',
        'O resultado mensal melhorou ${_currency(balanceDelta)}.',
        Icons.account_balance_wallet_outlined,
        const Color(0xFF16A34A),
      );
    } else if (balanceDelta < -0.005) {
      add(
        'Saldo piorou',
        'O resultado mensal caiu ${_currency(balanceDelta.abs())}.',
        Icons.account_balance_wallet_outlined,
        const Color(0xFFDC2626),
      );
    }

    if (increaseCat != null) {
      add(
        'Maior pressão no orçamento',
        '$increaseCat aumentou ${_currency(increase)}.',
        Icons.priority_high_rounded,
        const Color(0xFFF59E0B),
      );
    }
    if (reductionCat != null) {
      add(
        'Maior redução de gastos',
        '$reductionCat caiu ${_currency(reduction.abs())}.',
        Icons.savings_outlined,
        const Color(0xFF16A34A),
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
                const Icon(Icons.auto_graph_rounded, color: Color(0xFF0F766E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tendências e destaques',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Leitura automática das principais mudanças em relação ao mês anterior',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: item.color, size: 21),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: item.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.message,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCategoryComparisonCard extends StatelessWidget {
  const _ExpenseCategoryComparisonCard({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentStart = DateTime(now.year, now.month);
    final previousStart = DateTime(now.year, now.month - 1);
    final nextStart = DateTime(now.year, now.month + 1);

    final current = <String, double>{};
    final previous = <String, double>{};

    for (final item in transactions.where((item) => item.isExpense)) {
      final date = item.date;
      if (!date.isBefore(currentStart) && date.isBefore(nextStart)) {
        current[item.category] = (current[item.category] ?? 0) + item.amount;
      } else if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
        previous[item.category] = (previous[item.category] ?? 0) + item.amount;
      }
    }

    final categories = {...current.keys, ...previous.keys}.toList()
      ..sort((a, b) {
        final aTotal = (current[a] ?? 0) + (previous[a] ?? 0);
        final bTotal = (current[b] ?? 0) + (previous[b] ?? 0);
        return bTotal.compareTo(aTotal);
      });

    const monthNames = [
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
    final currentLabel = monthNames[currentStart.month - 1];
    final previousLabel = monthNames[previousStart.month - 1];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Comparativo de despesas por categoria',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$currentLabel x $previousLabel — veja onde seus gastos aumentaram ou diminuíram',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (categories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Ainda não há despesas suficientes para comparar os dois meses.',
                ),
              )
            else
              ...List.generate(categories.length, (index) {
                final category = categories[index];
                return Column(
                  children: [
                    _ExpenseCategoryComparisonRow(
                      category: category,
                      currentLabel: currentLabel,
                      previousLabel: previousLabel,
                      current: current[category] ?? 0,
                      previous: previous[category] ?? 0,
                    ),
                    if (index < categories.length - 1)
                      const Divider(height: 18),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCategoryComparisonRow extends StatelessWidget {
  const _ExpenseCategoryComparisonRow({
    required this.category,
    required this.currentLabel,
    required this.previousLabel,
    required this.current,
    required this.previous,
  });

  final String category;
  final String currentLabel;
  final String previousLabel;
  final double current;
  final double previous;

  @override
  Widget build(BuildContext context) {
    final delta = current - previous;
    final unchanged = delta.abs() < 0.005;
    final newExpense = previous <= 0 && current > 0;
    final noCurrentExpense = previous > 0 && current <= 0;
    final reduced = delta < 0;

    final Color accent;
    final IconData icon;
    final String changeText;

    if (unchanged) {
      accent = const Color(0xFF64748B);
      icon = Icons.remove_rounded;
      changeText = 'Sem alteração';
    } else if (newExpense) {
      accent = const Color(0xFFDC2626);
      icon = Icons.add_circle_outline_rounded;
      changeText = 'Nova despesa: ${_currency(current)}';
    } else if (noCurrentExpense) {
      accent = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
      changeText = 'Sem gasto neste mês';
    } else if (reduced) {
      accent = const Color(0xFF16A34A);
      icon = Icons.arrow_downward_rounded;
      changeText = 'Redução de ${_currency(delta.abs())}';
    } else {
      accent = const Color(0xFFDC2626);
      icon = Icons.arrow_upward_rounded;
      changeText = 'Aumento de ${_currency(delta)}';
    }

    final categoryInfo = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 12,
                runSpacing: 3,
                children: [
                  Text(
                    '$previousLabel: ${_currency(previous)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$currentLabel: ${_currency(current)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    final changeBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        changeText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: constraints.maxWidth < 430
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  categoryInfo,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: changeBadge),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: categoryInfo),
                  const SizedBox(width: 10),
                  changeBadge,
                ],
              ),
      ),
    );
  }
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
    for (final item in transactions.where((item) => item.isExpense)) {
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
      .where((item) => item.isExpense)
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

    final comparisonInfo = Row(
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
      ],
    );
    final changeBadge = Container(
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
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 430
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                comparisonInfo,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: changeBadge),
              ],
            )
          : Row(
              children: [
                Expanded(child: comparisonInfo),
                const SizedBox(width: 10),
                changeBadge,
              ],
            ),
    );
  }
}
