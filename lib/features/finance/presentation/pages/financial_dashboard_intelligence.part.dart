part of 'financial_dashboard_page.dart';

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
