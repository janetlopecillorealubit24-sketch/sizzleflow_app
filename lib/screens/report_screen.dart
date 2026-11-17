import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Rec> _sales = [], _exps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Db.salesBetween(app.from, app.to);
    final e = await Db.expensesBetween(app.from, app.to);
    if (!mounted) return;
    setState(() {
      _sales = s;
      _exps = e;
    });
  }

  String _catName(dynamic id) {
    for (final c in app.expCats) {
      if (c['id'] == id) return '${c['name']}';
    }
    return 'Other';
  }

  /// Builds the CSV and opens Android's share sheet (save to Drive, send by Messenger, etc.).
  Future<void> _exportCsv() async {
    String q(dynamic v) {
      final t = '$v'.replaceAll('"', '""');
      return '"$t"';
    }
    final rows = <List<dynamic>>[
      ['Receipt', 'Date', 'Cashier', 'Payment', 'Total'],
      for (final s in _sales) [s['receipt_no'], s['sale_date'], s['cashier'] ?? '', s['payment_method'], s['total_amount']],
    ];
    final csv = rows.map((r) => r.map(q).join(',')).join('\n');
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sales_${app.from}_to_${app.to}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'SizzleFlow sales ${app.from} to ${app.to}');
    } catch (e) {
      if (mounted) showMsg(context, 'Could not export: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <String, double>{};
    for (final s in _sales) {
      final d = '${s['sale_date']}'.substring(0, 10);
      byDay[d] = (byDay[d] ?? 0) + (s['total_amount'] as num).toDouble();
    }
    final byCat = <String, double>{};
    for (final e in _exps) {
      final n = _catName(e['category_id']);
      byCat[n] = (byCat[n] ?? 0) + (e['amount'] as num).toDouble();
    }
    final days = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final items = topItems(_sales);
    final salesTotal = sum(_sales, 'total_amount');
    final expTotal = sum(_exps, 'amount');

    Widget group(String title, List<Widget> rows, String empty) => SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(empty, style: SF.mutedStyle)),
              ...rows,
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SfCard(
          child: Row(
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
        ),
        StatRow([
          ['Sales', peso(salesTotal)],
          ['Expenses', peso(expTotal)],
          ['Net income', peso(salesTotal - expTotal)],
        ]),
        group('Sales per day', [for (final d in days) LabelValueRow(d.key, peso(d.value))], 'No sales.'),
        group('Items sold', [for (final i in items) LabelValueRow(i.key, '${i.value.q} pcs · ${peso(i.value.t)}')], 'No sales.'),
        group('Expenses by category', [for (final c in byCat.entries) LabelValueRow(c.key, peso(c.value))], 'No expenses.'),
        GradientButton(label: 'Export sales CSV', outlined: true, onPressed: _exportCsv),
      ],
    );
  }
}
