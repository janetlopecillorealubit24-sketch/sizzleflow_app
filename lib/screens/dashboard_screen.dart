import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loaded = false;
  List<Rec> _ts = [], _te = [], _ms = [], _me = [];
  List<int> _pending = [0, 0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final t = ymd(now);
    final m = ymd(DateTime(now.year, now.month, 1));
    final ts = await Db.salesBetween(t, t);
    final te = await Db.expensesBetween(t, t);
    final ms = await Db.salesBetween(m, t);
    final me = await Db.expensesBetween(m, t);
    final pc = await Db.pendingCount();
    if (!mounted) return;
    setState(() {
      _ts = ts;
      _te = te;
      _ms = ms;
      _me = me;
      _pending = pc;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: SF.green));
    final cash = sum(_ts.where((s) => s['payment_method'] == 'Cash').toList(), 'total_amount');
    final gcash = sum(_ts.where((s) => s['payment_method'] == 'GCash').toList(), 'total_amount');
    final best = topItems(_ms).take(5).toList();
    final waiting = _pending[0] + _pending[1];
    return RefreshIndicator(
      color: SF.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          sectionTitle('Today'),
          StatRow([
            ['Sales', peso(sum(_ts, 'total_amount'))],
            ['Expenses', peso(sum(_te, 'amount'))],
            ['Net', peso(sum(_ts, 'total_amount') - sum(_te, 'amount'))],
          ]),
          SfCard(
            child: Text('${_ts.length} orders · Cash ${peso(cash)} · GCash ${peso(gcash)}', style: SF.mutedStyle),
          ),
          sectionTitle('This month'),
          StatRow([
            ['Sales', peso(sum(_ms, 'total_amount'))],
            ['Expenses', peso(sum(_me, 'amount'))],
            ['Net', peso(sum(_ms, 'total_amount') - sum(_me, 'amount'))],
          ]),
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Best sellers (month)', style: TextStyle(fontWeight: FontWeight.w700)),
                if (best.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No sales yet.', style: SF.mutedStyle)),
                for (final b in best) LabelValueRow(b.key, '${b.value.q} pcs · ${peso(b.value.t)}'),
              ],
            ),
          ),
          SfCard(
            child: Text(
              waiting > 0
                  ? '${_pending[0]} sale(s) and ${_pending[1]} expense(s) waiting to sync. Go to Settings > Sync now.'
                  : 'Everything is synced.',
              style: SF.mutedStyle,
            ),
          ),
        ],
      ),
    );
  }
}
