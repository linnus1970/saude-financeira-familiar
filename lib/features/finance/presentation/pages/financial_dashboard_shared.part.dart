part of 'financial_dashboard_page.dart';

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
                      Text(
                        _currency(entry.value),
                        style: const TextStyle(
                          color: Color(0xFFDC2626), // expense-category-value
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
