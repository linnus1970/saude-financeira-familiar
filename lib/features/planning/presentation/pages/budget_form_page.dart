import 'package:flutter/material.dart';

import '../../data/planning_repository.dart';
import '../../domain/monthly_budget.dart';

class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({
    required this.repository,
    required this.month,
    required this.year,
    this.budget,
    super.key,
  });

  final PlanningRepository repository;
  final int month;
  final int year;
  final MonthlyBudget? budget;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late final TextEditingController _limit;
  bool _saving = false;

  static const categories = [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde',
    'Educação',
    'Lazer',
    'Outras despesas',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.budget?.category ?? categories.first;
    _limit = TextEditingController(
      text: widget.budget == null
          ? ''
          : widget.budget!.limit.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll('.', '').replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final existing = widget.budget;
      await widget.repository.saveBudget(
        MonthlyBudget(
          id: existing?.id ?? '',
          category: _category,
          limit: _parse(_limit.text)!,
          month: widget.month,
          year: widget.year,
          createdAt: existing?.createdAt ?? DateTime.now(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.budget == null ? 'Novo orçamento' : 'Editar orçamento',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Limite mensal',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = _parse(value ?? '');
                    return parsed == null || parsed <= 0
                        ? 'Informe um limite maior que zero.'
                        : null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(_saving ? 'Salvando...' : 'Salvar orçamento'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
