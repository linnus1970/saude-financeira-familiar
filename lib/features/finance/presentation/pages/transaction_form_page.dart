import 'package:flutter/material.dart';

import '../../data/financial_repository.dart';
import '../../domain/financial_transaction.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    required this.repository,
    this.transaction,
    super.key,
  });

  final FinancialRepository repository;
  final FinancialTransaction? transaction;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;

  late TransactionType _type;
  late String _category;
  late DateTime _date;
  bool _saving = false;

  static const _incomeCategories = [
    'Salário',
    'Venda',
    'Investimentos',
    'Outras receitas',
  ];

  static const _expenseCategories = [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde',
    'Educação',
    'Lazer',
    'Outras despesas',
  ];

  static const _investmentCategories = [
    'Reserva de emergência',
    'Renda fixa',
    'Fundos',
    'Ações',
    'Previdência',
    'Criptomoedas',
    'Outros investimentos',
  ];

  List<String> get _categories {
    return switch (_type) {
      TransactionType.income => _incomeCategories,
      TransactionType.expense => _expenseCategories,
      TransactionType.investment => _investmentCategories,
      TransactionType.redemption => _investmentCategories,
    };
  }

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    _description = TextEditingController(text: transaction?.description ?? '');
    _amount = TextEditingController(
      text: transaction == null
          ? ''
          : transaction.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _type = transaction?.type ?? TransactionType.expense;
    _category =
        transaction?.category ??
        (_type == TransactionType.income
            ? _incomeCategories.first
            : _expenseCategories.first);
    _date = transaction?.date ?? DateTime.now();

    if (!_categories.contains(_category)) {
      _category = _categories.first;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final normalized = _amount.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final amount = double.parse(normalized);
      final current = widget.transaction;

      if (_type == TransactionType.redemption) {
        final available = await widget.repository.availableInvestmentAmount(
          category: _category,
          excludingTransactionId: current?.id,
          upToDate: _date,
        );

        if (amount > available) {
          throw StateError(
            'Saldo disponível para resgate em $_category: R\$ ${available.toStringAsFixed(2).replaceAll('.', ',')}.',
          );
        }
      }

      final transaction = FinancialTransaction(
        id: current?.id ?? '',
        description: _description.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        date: _date,
        createdAt: current?.createdAt ?? DateTime.now(),
      );

      if (current == null) {
        await widget.repository.addTransaction(transaction);
      } else {
        await widget.repository.updateTransaction(transaction);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar lançamento' : 'Novo lançamento'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TransactionTypeSelector(
                      selected: _type,
                      onSelected: (type) {
                        setState(() {
                          _type = type;
                          _category = _categories.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _description,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value ?? '').trim().length < 2
                          ? 'Informe uma descrição.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: switch (_type) {
                          TransactionType.income => const Color(0xFF16A34A),
                          TransactionType.expense => const Color(0xFFDC2626),
                          TransactionType.investment => const Color(0xFF2563EB),
                          TransactionType.redemption => const Color(0xFF7C3AED),
                        },
                        fontWeight: FontWeight.w800,
                      ),

                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final normalized = (value ?? '')
                            .trim()
                            .replaceAll('.', '')
                            .replaceAll(',', '.');
                        final parsed = double.tryParse(normalized);

                        if (parsed == null || parsed <= 0) {
                          return 'Informe um valor maior que zero.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Data: ${_date.day.toString().padLeft(2, '0')}/'
                          '${_date.month.toString().padLeft(2, '0')}/'
                          '${_date.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          editing ? 'Salvar alterações' : 'Cadastrar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  const _TransactionTypeSelector({
    required this.selected,
    required this.onSelected,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onSelected;

  static const _items = <(TransactionType, String, IconData)>[
    (TransactionType.income, 'Receita', Icons.trending_up),
    (TransactionType.expense, 'Despesa', Icons.trending_down),
    (TransactionType.investment, 'Investimento', Icons.savings_outlined),
    (
      TransactionType.redemption,
      'Resgate',
      Icons.account_balance_wallet_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return SegmentedButton<TransactionType>(
            segments: _items
                .map(
                  (item) => ButtonSegment(
                    value: item.$1,
                    label: Text(item.$2, maxLines: 1),
                    icon: Icon(item.$3),
                  ),
                )
                .toList(),
            selected: {selected},
            onSelectionChanged: (selection) => onSelected(selection.first),
          );
        }

        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _items.map((item) {
            final color = switch (item.$1) {
              TransactionType.income => const Color(0xFF15803D),
              TransactionType.expense => const Color(0xFFDC2626),
              TransactionType.investment => const Color(0xFF2563EB),
              TransactionType.redemption => const Color(0xFF7C3AED),
            };
            final isSelected = selected == item.$1;
            return SizedBox(
              width: itemWidth,
              child: ChoiceChip(
                avatar: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 0.16 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.$3, size: 17, color: color),
                ),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: isSelected,
                selectedColor: color.withValues(alpha: 0.12),
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                onSelected: (_) => onSelected(item.$1),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
