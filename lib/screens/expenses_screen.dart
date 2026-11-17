import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  int? _cat;
  String _date = ymd(DateTime.now());
  String _err = '';
  List<Rec> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await Db.expensesBetween(app.from, app.to);
    if (!mounted) return;
    setState(() => _list = l);
  }

  int? get _catValue {
    if (app.expCats.any((c) => c['id'] == _cat)) return _cat;
    return app.expCats.isEmpty ? null : app.expCats.first['id'] as int;
  }

  Future<void> _save() async {
    final desc = _desc.text.trim();
    final amt = double.tryParse(_amount.text.trim());
    final cat = _catValue;
    if (desc.isEmpty || amt == null || amt <= 0 || cat == null) {
      setState(() => _err = 'Enter a description and an amount above 0.');
      return;
    }
    await Db.put('expenses', {
      'id': newId(),
      'user_id': app.user!['id'],
      'category_id': cat,
      'description': desc,
      'amount': amt,
      'expense_date': _date,
      'sync_status': 'pending',
      'is_deleted': 0,
      'updated_by': app.user!['id'],
      'updated_at': ymdhms(DateTime.now()),
    });
    _desc.clear();
    _amount.clear();
    setState(() => _err = '');
    FocusManager.instance.primaryFocus?.unfocus();
    _load();
  }

  Future<void> _delete(Rec e) async {
    if (!await confirmDialog(context, 'Delete this expense?', yes: 'Delete')) return;
    await Db.deleteExpense(e['id'] as String, app.user!['id'] as String);
    _load();
  }

  String _catName(dynamic id) {
    for (final c in app.expCats) {
      if (c['id'] == id) return '${c['name']}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _catValue,
                isExpanded: true,
                items: [
                  for (final c in app.expCats) DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']}')),
                ],
                onChanged: (v) => setState(() => _cat = v),
              ),
              const SizedBox(height: 8),
              TextField(controller: _desc, decoration: const InputDecoration(hintText: 'Description (e.g. cooking oil)')),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
              const SizedBox(height: 8),
              DateField(value: _date, onChanged: (v) => setState(() => _date = v)),
              SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_err, style: const TextStyle(color: SF.danger, fontSize: 14)),
                ),
              ),
              GradientButton(label: 'Save expense', onPressed: _save),
            ],
          ),
        ),
        SfCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DateField(
                      value: app.from,
                      onChanged: (v) {
                        app.from = v;
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DateField(
                      value: app.to,
                      onChanged: (v) {
                        app.to = v;
                        _load();
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_list.length} expense(s)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(peso(sum(_list, 'amount')), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (_list.isEmpty) const Text('No expenses in this range.', style: SF.mutedStyle),
              for (final e in _list)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SF.line))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e['description']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${e['expense_date']} · ${_catName(e['category_id'])} · ${e['sync_status']}',
                                style: SF.mutedStyle),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(peso(e['amount'] as num), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          SfChip(label: 'Delete', color: SF.danger, onTap: () => _delete(e)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
