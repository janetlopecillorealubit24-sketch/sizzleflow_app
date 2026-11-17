import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'seed.dart';
import 'utils.dart';

/// Local (offline) database - the Flutter equivalent of db.js / IndexedDB.
class Db {
  static late Database _db;

  static Future<void> open() async {
    final path = p.join(await getDatabasesPath(), 'sizzleflow.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE users(id TEXT PRIMARY KEY, full_name TEXT, username TEXT, '
          'password_hash TEXT, role TEXT, is_active INTEGER DEFAULT 1, email TEXT, profile_photo TEXT, updated_at TEXT)');
      await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT, sync_status TEXT, updated_at TEXT)');
      await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY, category_id INTEGER, name TEXT, price REAL, '
          'options TEXT, photo TEXT, is_active INTEGER DEFAULT 1, sync_status TEXT, updated_at TEXT)');
      await db.execute('CREATE TABLE expense_categories(id INTEGER PRIMARY KEY, name TEXT)');
      await db.execute('CREATE TABLE sales(id TEXT PRIMARY KEY, receipt_no TEXT, user_id TEXT, cashier TEXT, '
          'customer_name TEXT, device_id TEXT, payment_method TEXT, total_amount REAL, sale_date TEXT, '
          'sync_status TEXT, is_deleted INTEGER DEFAULT 0, updated_at TEXT)');
      await db.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');
      await db.execute('CREATE TABLE sale_items(id TEXT PRIMARY KEY, sale_id TEXT, product_id INTEGER, name TEXT, '
          'category_id INTEGER, options TEXT, quantity INTEGER, unit_price REAL, subtotal REAL)');
      await db.execute('CREATE INDEX idx_items_sale ON sale_items(sale_id)');
      await db.execute('CREATE TABLE expenses(id TEXT PRIMARY KEY, user_id TEXT, category_id INTEGER, '
          'description TEXT, amount REAL, expense_date TEXT, sync_status TEXT, is_deleted INTEGER DEFAULT 0, '
          'updated_by TEXT, updated_at TEXT)');
      await db.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');

      final b = db.batch();
      for (final u in seedUsers()) {
        b.insert('users', u);
      }
      for (final c in seedCategories) {
        b.insert('categories', {'id': c[0], 'name': c[1], 'sync_status': 'synced'});
      }
      for (final c in seedExpenseCategories) {
        b.insert('expense_categories', {'id': c[0], 'name': c[1]});
      }
      for (final x in seedProducts) {
        b.insert('products', {
          'id': x[0],
          'category_id': x[1],
          'name': x[2],
          'price': (x[3] as num).toDouble(),
          'options': x[4] == null ? null : jsonEncode(x[4]),
          'photo': '',
          'is_active': 1,
          'sync_status': 'synced',
        });
      }
      await b.commit(noResult: true);
    });
  }

  // ---------- generic ----------
  static Future<List<Rec>> all(String table, {String? where, List<Object?>? args, String? orderBy}) async {
    final rows = await _db.query(table, where: where, whereArgs: args, orderBy: orderBy);
    return rows.map((r) => Rec.from(r)).toList();
  }

  static Future<void> put(String table, Rec v) async {
    await _db.insert(table, v, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- users ----------
  static Future<Rec?> userByLogin(String username, String hash) async {
    final r = await all('users',
        where: 'username=? AND password_hash=? AND COALESCE(is_active,1)!=0', args: [username, hash]);
    return r.isEmpty ? null : r.first;
  }

  static Future<Rec?> userById(String id) async {
    final r = await all('users', where: 'id=?', args: [id]);
    return r.isEmpty ? null : r.first;
  }

  /// Same idea as the web app: server data is merged over local data,
  /// so local-only fields (email, photo) are kept.
  static Future<void> mergeUsers(List<Rec> server) async {
    for (final u in server) {
      final id = '${u['id']}';
      final local = await userById(id) ?? <String, dynamic>{};
      await put('users', {
        ...local,
        'id': id,
        'full_name': u['full_name'],
        'username': u['username'],
        'password_hash': u['password_hash'],
        'role': u['role'],
        'is_active': int.tryParse('${u['is_active']}') ?? 1,
      });
    }
  }

  // ---------- catalog ----------
  static Future<List<Rec>> products() => all('products', where: 'is_active=1', orderBy: 'id');
  static Future<List<Rec>> categories() => all('categories', orderBy: 'id');
  static Future<List<Rec>> expenseCategories() => all('expense_categories', orderBy: 'id');

  static Future<void> saveProduct({
    int? id,
    required int categoryId,
    required String name,
    required double price,
    required Map<String, dynamic>? options,
    required String photo,
  }) =>
      put('products', {
        'id': id ?? DateTime.now().millisecondsSinceEpoch,
        'category_id': categoryId,
        'name': name,
        'price': price,
        'options': options == null ? null : jsonEncode(options),
        'photo': photo,
        'is_active': 1,
        'sync_status': 'pending',
        'updated_at': ymdhms(DateTime.now()),
      });

  static Future<void> deactivateProduct(int id) async {
    await _db.update('products', {'is_active': 0, 'sync_status': 'pending', 'updated_at': ymdhms(DateTime.now())},
        where: 'id=?', whereArgs: [id]);
  }

  static Future<void> addCategory(String name) => put('categories', {
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': name,
        'sync_status': 'pending',
        'updated_at': ymdhms(DateTime.now()),
      });

  /// Deleting a category also removes its products (same as the web app).
  static Future<void> deleteCategory(int id) async {
    await _db.update('products', {'is_active': 0, 'sync_status': 'pending', 'updated_at': ymdhms(DateTime.now())},
        where: 'category_id=?', whereArgs: [id]);
    await _db.delete('categories', where: 'id=?', whereArgs: [id]);
  }

  // ---------- sales ----------
  static Future<int> countReceipts(String prefix) async {
    final r = await _db.rawQuery('SELECT COUNT(*) AS c FROM sales WHERE receipt_no LIKE ?', ['$prefix%']);
    return (r.first['c'] as int?) ?? 0;
  }

  static Future<void> saveSale(Rec sale, List<Rec> items) async {
    final row = Rec.from(sale)..remove('items');
    await _db.transaction((txn) async {
      await txn.insert('sales', row, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final i in items) {
        final r = Rec.from(i);
        r['options'] = jsonEncode(i['options'] ?? {});
        await txn.insert('sale_items', r, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static List<Rec> _attach(List<Rec> sales, List<Map<String, Object?>> items) {
    final byId = <String, List<Rec>>{};
    for (final raw in items) {
      final i = Rec.from(raw);
      try {
        i['options'] = jsonDecode((i['options'] ?? '{}') as String);
      } catch (_) {
        i['options'] = <String, dynamic>{};
      }
      byId.putIfAbsent(i['sale_id'] as String, () => []).add(i);
    }
    for (final s in sales) {
      s['items'] = byId[s['id']] ?? <Rec>[];
    }
    return sales;
  }

  static const _rangeWhere = 'is_deleted=0 AND substr(sale_date,1,10)>=? AND substr(sale_date,1,10)<=?';

  /// Sales (not voided) between two dates, newest first, with their items.
  static Future<List<Rec>> salesBetween(String from, String to) async {
    final sales = await all('sales', where: _rangeWhere, args: [from, to], orderBy: 'sale_date DESC');
    final items = await _db.rawQuery(
        'SELECT * FROM sale_items WHERE sale_id IN (SELECT id FROM sales WHERE $_rangeWhere)', [from, to]);
    return _attach(sales, items);
  }

  static Future<List<Rec>> pendingSales() async {
    final sales = await all('sales', where: "sync_status='pending'", orderBy: 'sale_date');
    final items = await _db
        .rawQuery("SELECT * FROM sale_items WHERE sale_id IN (SELECT id FROM sales WHERE sync_status='pending')");
    return _attach(sales, items);
  }

  static Future<void> voidSale(String id) async {
    await _db.update('sales', {'is_deleted': 1, 'sync_status': 'pending', 'updated_at': ymdhms(DateTime.now())},
        where: 'id=?', whereArgs: [id]);
  }

  static Future<void> markSalesSynced(List<String> ids) async {
    for (final id in ids) {
      await _db.update('sales', {'sync_status': 'synced'}, where: 'id=?', whereArgs: [id]);
    }
  }

  // ---------- expenses ----------
  static Future<List<Rec>> expensesBetween(String from, String to) =>
      all('expenses', where: 'is_deleted=0 AND expense_date>=? AND expense_date<=?', args: [from, to], orderBy: 'expense_date DESC');

  static Future<List<Rec>> pendingExpenses() => all('expenses', where: "sync_status='pending'");

  static Future<void> deleteExpense(String id, String userId) async {
    await _db.update(
        'expenses',
        {'is_deleted': 1, 'sync_status': 'pending', 'updated_by': userId, 'updated_at': ymdhms(DateTime.now())},
        where: 'id=?', whereArgs: [id]);
  }

  static Future<void> markExpensesSynced(List<String> ids) async {
    for (final id in ids) {
      await _db.update('expenses', {'sync_status': 'synced'}, where: 'id=?', whereArgs: [id]);
    }
  }

  /// [salesPending, expensesPending]
  static Future<List<int>> pendingCount() async {
    final s = await _db.rawQuery("SELECT COUNT(*) AS c FROM sales WHERE sync_status='pending'");
    final e = await _db.rawQuery("SELECT COUNT(*) AS c FROM expenses WHERE sync_status='pending'");
    return [(s.first['c'] as int?) ?? 0, (e.first['c'] as int?) ?? 0];
  }
}
