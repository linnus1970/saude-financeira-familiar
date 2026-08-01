import 'package:flutter/material.dart';

import '../../data/planning_repository.dart';
import '../../domain/financial_goal.dart';

class GoalFormPage extends StatefulWidget {
  const GoalFormPage({required this.repository, this.goal, super.key});

  final PlanningRepository repository;
  final FinancialGoal? goal;

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _current;
  late DateTime _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = TextEditingController(text: goal?.name ?? '');
    _target = TextEditingController(
      text: goal == null ? '' : _number(goal.targetAmount),
    );
    _current = TextEditingController(
      text: goal == null ? '0,00' : _number(goal.currentAmount),
    );
    _deadline = goal?.deadline ?? DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _current.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll('.', '').replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final existing = widget.goal;
      await widget.repository.saveGoal(
        FinancialGoal(
          id: existing?.id ?? '',
          name: _name.text.trim(),
          targetAmount: _parse(_target.text)!,
          currentAmount: _parse(_current.text) ?? 0,
          deadline: _deadline,
          createdAt: existing?.createdAt ?? DateTime.now(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar a meta: $error')),
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
        title: Text(widget.goal == null ? 'Nova meta' : 'Editar meta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nome da meta',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').trim().length < 3
                      ? 'Informe o nome da meta.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor desejado',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = _parse(value ?? '');
                    return parsed == null || parsed <= 0
                        ? 'Informe um valor maior que zero.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _current,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor já acumulado',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = _parse(value ?? '');
                    return parsed == null || parsed < 0
                        ? 'Informe um valor válido.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Prazo: ${_date(_deadline)}'),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Salvar meta'),
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

String _number(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
