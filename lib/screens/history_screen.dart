import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../printer.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Rec> _sales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Db.salesBetween(app.hdate, app.hdate);
    if (!mounted) return;
    setState(() => _sales = s);
  }

  Future<void> _reprint(Rec s) async {
    try {
      await PrinterService.printSale(s);
    } catch (e) {
      if (mounted) showMsg(context, 'Could not print: $e');
    }
  }

  Future<void> _void(Rec s) async {
    if (!await confirmDialog(context, 'Void this sale? It will no longer count in totals.', yes: 'Void')) return;
    await Db.voidSale(s['id'] as String);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SfCard(
          child: Column(
            children: [
              DateField(
                value: app.hdate,
                onChanged: (v) {
                  app.hdate = v;
                  _load();
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_sales.length} sale(s)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(peso(sum(_sales, 'total_amount')),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SfCard(
          child: Column(
            children: [
              if (_sales.isEmpty) const Text('No sales on this date.', style: SF.mutedStyle),
              for (final s in _sales)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SF.line))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s['receipt_no']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${'${s['sale_date']}'.substring(11, 16)} · ${s['payment_method']} · ${s['cashier'] ?? ''} · ${s['sync_status']}',
                              style: SF.mutedStyle,
                            ),
                            Text(
                              (s['items'] as List).map((i) => '${i['quantity']}x ${i['name']}').join(', '),
                              style: SF.mutedStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(peso(s['total_amount'] as num), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: [
                              SfChip(label: 'Reprint', onTap: () => _reprint(s)),
                              if (app.isOwner) SfChip(label: 'Void', color: SF.danger, onTap: () => _void(s)),
                            ],
                          ),
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
