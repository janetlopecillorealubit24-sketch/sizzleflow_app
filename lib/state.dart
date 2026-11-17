import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'db.dart';
import 'models.dart';
import 'utils.dart';

/// App-wide state (logged-in user, menu, cart, settings).
class AppState extends ChangeNotifier {
  late SharedPreferences prefs;

  Rec? user;
  String tab = 'dash';

  List<Product> products = [];
  List<Rec> cats = [];
  List<Rec> expCats = [];

  // New Sale screen
  int catFilter = 0;
  final Map<String, CartLine> cart = {};
  String customerName = '';
  String pay = 'Cash';

  // date ranges (Expenses + Report share from/to, History has its own)
  late String from;
  late String to;
  late String hdate;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    await Db.open();
    final now = DateTime.now();
    from = ymd(DateTime(now.year, now.month, 1));
    to = ymd(now);
    hdate = ymd(now);
    await loadCatalog();
    final uid = prefs.getString('user_id');
    if (uid != null) {
      user = await Db.userById(uid);
      if (user != null) tab = 'dash';
    }
  }

  // ---------- settings ----------
  String get serverUrl => prefs.getString('sf_url') ?? AppConfig.defaultServerUrl;
  set serverUrl(String v) => prefs.setString('sf_url', v.trim().replaceAll(RegExp(r'/+$'), ''));

  String get apiKey => prefs.getString('sf_key') ?? AppConfig.apiKey;
  set apiKey(String v) => prefs.setString('sf_key', v.trim());

  String get printerMac => prefs.getString('sf_printer_mac') ?? '';
  String get printerName => prefs.getString('sf_printer_name') ?? '';
  void setPrinter(String mac, String name) {
    prefs.setString('sf_printer_mac', mac);
    prefs.setString('sf_printer_name', name);
  }

  String get deviceId {
    var d = prefs.getString('sf_device');
    if (d == null) {
      d = 'android-${newId().substring(0, 8)}';
      prefs.setString('sf_device', d);
    }
    return d;
  }

  // ---------- auth ----------
  bool get isOwner => user?['role'] == 'owner';

  Future<bool> login(String username, String password) async {
    final u = await Db.userByLogin(username, sha256Hex(password));
    if (u == null) return false;
    user = u;
    tab = 'dash';
    await prefs.setString('user_id', u['id'] as String);
    notifyListeners();
    return true;
  }

  void logout() {
    user = null;
    cart.clear();
    customerName = '';
    prefs.remove('user_id');
    notifyListeners();
  }

  Future<void> updateUser(Rec u) async {
    await Db.put('users', u);
    user = u;
    notifyListeners();
  }

  void setTab(String t) {
    tab = t;
    notifyListeners();
  }

  // ---------- catalog ----------
  Future<void> loadCatalog() async {
    products = (await Db.products()).map(Product.fromRow).toList();
    cats = await Db.categories();
    expCats = await Db.expenseCategories();
    notifyListeners();
  }

  // ---------- cart ----------
  double get cartTotal => cart.values.fold(0.0, (t, l) => t + l.quantity * l.unitPrice);

  void setCategoryFilter(int id) {
    catFilter = id;
    notifyListeners();
  }

  void setPay(String m) {
    pay = m;
    notifyListeners();
  }

  void addToCart(Product p, Map<String, String> options) {
    final entries = options.entries.map((e) => '${e.key}=${e.value}').toList()..sort();
    final key = '${p.id}|${entries.join('|')}';
    final line = cart.putIfAbsent(
      key,
      () => CartLine(
        key: key,
        product: p,
        options: options,
        included: p.type == 'combo' ? '${p.options?['included'] ?? ''}' : '',
        unitPrice: options.containsKey('size') ? p.priceFor(options['size']) : p.price,
      ),
    );
    line.quantity++;
    notifyListeners();
  }

  void changeQty(String key, int delta) {
    final line = cart[key];
    if (line == null) return;
    line.quantity += delta;
    if (line.quantity <= 0) cart.remove(key);
    notifyListeners();
  }

  void clearOrder() {
    cart.clear();
    customerName = '';
    notifyListeners();
  }

  /// Saves the sale on the phone (works offline) and returns it for printing.
  Future<Rec> completeSale() async {
    final now = DateTime.now();
    final id = newId();
    final items = cart.values
        .map((l) => <String, dynamic>{
              'id': newId(),
              'sale_id': id,
              'product_id': l.product.id,
              'name': l.displayName,
              'category_id': l.product.categoryId,
              'options': l.options,
              'quantity': l.quantity,
              'unit_price': l.unitPrice,
              'subtotal': l.quantity * l.unitPrice,
            })
        .toList();
    final prefix = 'SS-${ymd(now).replaceAll('-', '')}-';
    final n = await Db.countReceipts(prefix) + 1;
    final sale = <String, dynamic>{
      'id': id,
      'receipt_no': '$prefix${n.toString().padLeft(3, '0')}',
      'user_id': user!['id'],
      'cashier': user!['full_name'],
      'customer_name': customerName.trim(),
      'device_id': deviceId,
      'payment_method': pay,
      'total_amount': cartTotal,
      'sale_date': ymdhms(now),
      'sync_status': 'pending',
      'is_deleted': 0,
      'updated_at': ymdhms(now),
      'items': items,
    };
    await Db.saveSale(sale, items);
    cart.clear();
    customerName = '';
    notifyListeners();
    return sale;
  }
}

final AppState app = AppState();
