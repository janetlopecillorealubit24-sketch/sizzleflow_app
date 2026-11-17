import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db.dart';
import 'models.dart';
import 'state.dart';

class SfException implements Exception {
  final String message;
  SfException(this.message);
  @override
  String toString() => message;
}

class SyncResult {
  final int sales;
  final int expenses;
  SyncResult(this.sales, this.expenses);
}

/// Talks to the same PHP API as the web version (api/*.php).
class Sync {
  static Map<String, String> get _headers => {'X-API-KEY': app.apiKey, 'Content-Type': 'application/json'};
  static Uri _uri(String file) => Uri.parse('${app.serverUrl}/$file');

  static Future<bool> ping() async {
    try {
      final r = await http.get(_uri('ping.php'), headers: _headers).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Rec> _call(String file, {String? body}) async {
    http.Response r;
    try {
      final f = body == null
          ? http.get(_uri(file), headers: _headers)
          : http.post(_uri(file), headers: _headers, body: body);
      r = await f.timeout(const Duration(seconds: 20));
    } catch (_) {
      throw SfException('Cannot reach the server. Check the address, your internet/Wi-Fi, and that Apache is running.');
    }
    if (r.statusCode == 401) {
      throw SfException('API key rejected. Make sure it matches API_KEY in api/config.php.');
    }
    if (r.statusCode != 200) {
      var detail = '';
      try {
        detail = ': ${(jsonDecode(r.body) as Map)['error']}';
      } catch (_) {}
      throw SfException('Server error ${r.statusCode}$detail');
    }
    try {
      return Rec.from(jsonDecode(r.body) as Map);
    } catch (_) {
      throw SfException('The server sent an unexpected reply. Check the server address in Settings.');
    }
  }

  static Rec _saleJson(Rec s) {
    final j = Rec.from(s)..remove('cashier');
    return j;
  }

  static List<Rec> _recs(dynamic v) =>
      ((v as List?) ?? const []).map((x) => Rec.from(x as Map)).toList();

  /// Upload pending sales/expenses, then download staff accounts and expense categories.
  static Future<SyncResult> syncNow() async {
    final sales = await Db.pendingSales();
    final exps = await Db.pendingExpenses();
    var s = 0, e = 0;
    if (sales.isNotEmpty || exps.isNotEmpty) {
      final res = await _call('sync_push.php',
          body: jsonEncode({'device_id': app.deviceId, 'sales': sales.map(_saleJson).toList(), 'expenses': exps}));
      final ss = ((res['synced_sales'] as List?) ?? const []).map((x) => '$x').toList();
      final se = ((res['synced_expenses'] as List?) ?? const []).map((x) => '$x').toList();
      await Db.markSalesSynced(ss);
      await Db.markExpensesSynced(se);
      s = ss.length;
      e = se.length;
    }
    final c = await _call('sync_pull.php');
    await Db.mergeUsers(_recs(c['users']));
    // The menu on the phone is the source of truth (same rule as the web app).
    for (final x in _recs(c['expense_categories'])) {
      final id = int.tryParse('${x['id']}');
      if (id != null) await Db.put('expense_categories', {'id': id, 'name': x['name']});
    }
    await app.loadCatalog();
    return SyncResult(s, e);
  }
}
