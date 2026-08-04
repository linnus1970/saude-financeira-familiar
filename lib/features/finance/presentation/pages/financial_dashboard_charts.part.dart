part of 'financial_dashboard_page.dart';

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
  double get totalMoved => income + expenses;
  double get incomePercentage =>
      totalMoved == 0 ? 0 : (income / totalMoved) * 100;
  double get expensePercentage =>
      totalMoved == 0 ? 0 : (expenses / totalMoved) * 100;
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

    final totals = incomeExpenseTotals(items);

    points.add(
      _MonthlyChartPoint(
        year: date.year,
        month: date.month,
        income: totals.income,
        expenses: totals.expenses,
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

    if (!points.any((item) => item.income > 0 || item.expenses > 0)) {
      return const _ChartEmptyCard(
        icon: Icons.bar_chart_rounded,
        title: 'Receitas x despesas',
        message:
            'O comparativo aparecerá quando houver receitas ou despesas nos últimos 6 meses.',
      );
    }

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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Comparativo colorido dos últimos 6 meses',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _ChartLegend(color: _incomeColor, label: 'Receitas'),
                _ChartLegend(color: _expenseColor, label: 'Despesas'),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: MediaQuery.sizeOf(context).width < 400 ? 220 : 250,
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
                        final point = points[group.x];
                        final percentage = rodIndex == 0
                            ? point.incomePercentage
                            : point.expensePercentage;
                        return BarTooltipItem(
                          '${_monthLong(point.month)} ${point.year}\n'
                          '$type: ${_currency(rod.toY)}\n'
                          '${_percentage(percentage)}',
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
                          color: _incomeColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                        BarChartRodData(
                          toY: item.expenses,
                          width: 13,
                          color: _expenseColor,
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
            const SizedBox(height: 12),
            _IncomeExpenseCompactSummary(points: points),
          ],
        ),
      ),
    );
  }
}

String _percentage(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')}%';

String _monthLong(int month) => const [
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
][month - 1];

class _IncomeExpenseCompactSummary extends StatelessWidget {
  const _IncomeExpenseCompactSummary({required this.points});

  final List<_MonthlyChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final populated = points.where((point) => point.totalMoved > 0);
    return Column(
      children: populated
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${point.label}/${point.year}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 14,
                    runSpacing: 3,
                    children: [
                      Text(
                        'Receitas: ${_currency(point.income)} · '
                        '${_percentage(point.incomePercentage)}',
                        style: const TextStyle(
                          color: _incomeColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Despesas: ${_currency(point.expenses)} · '
                        '${_percentage(point.expensePercentage)}',
                        style: const TextStyle(
                          color: _expenseColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
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

class _ChartEmptyCard extends StatelessWidget {
  const _ChartEmptyCard({
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
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
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

  for (final item in transactions.where((item) => item.isExpense)) {
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

    final balance = availableBalance(
      transactions.where((item) => !item.date.isAfter(monthEnd)),
    );

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
    if (transactions.isEmpty) {
      return const _ChartEmptyCard(
        icon: Icons.show_chart_rounded,
        title: 'Evolução do saldo acumulado',
        message: 'A evolução aparecerá quando houver lançamentos cadastrados.',
      );
    }

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
              'Veja como o saldo disponível evoluiu nos últimos 6 meses',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: MediaQuery.sizeOf(context).width < 400 ? 220 : 245,
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
                            '${_monthLong(point.month)} ${point.year}\n'
                            'Saldo: ${_currency(point.balance)}',
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
            const SizedBox(height: 12),
            _BalanceCompactSummary(points: points),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: lineColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'Passe o mouse ou toque nos pontos para ver o saldo acumulado de cada mês.'
                        : 'Toque nos pontos para consultar o saldo de cada mês.',
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

class _BalanceCompactSummary extends StatelessWidget {
  const _BalanceCompactSummary({required this.points});
  final List<_BalanceEvolutionPoint> points;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: points
          .map(
            (point) => Container(
              width: MediaQuery.sizeOf(context).width < 400 ? 94 : 132,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: _investmentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${point.label}/${point.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    child: Text(
                      _currency(point.balance),
                      style: const TextStyle(
                        color: _investmentColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
      } else if (item.isExpense) {
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

    if (!points.any((item) => item.hasIncome)) {
      return const _ChartEmptyCard(
        icon: Icons.savings_outlined,
        title: 'Taxa de economia mensal',
        message:
            'A taxa será calculada quando houver receitas cadastradas nos últimos 6 meses.',
      );
    }

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
              height: MediaQuery.sizeOf(context).width < 400 ? 220 : 245,
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
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _SavingsRateLegend(
                  color: Color(0xFF16A34A),
                  label: 'Economia positiva',
                ),
                _SavingsRateLegend(
                  color: Color(0xFFDC2626),
                  label: 'Gastos acima da renda',
                ),
                _SavingsRateLegend(
                  color: Color(0xFF94A3B8),
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
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
