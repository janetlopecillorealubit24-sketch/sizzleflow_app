import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

String money(num n) {
  final s = n.toStringAsFixed(2);
  final neg = s.startsWith('-');
  final parts = (neg ? s.substring(1) : s).split('.');
  final whole = parts[0];
  final b = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) b.write(',');
    b.write(whole[i]);
  }
  return '${neg ? '-' : ''}$b.${parts[1]}';
}

/// Screen format: ₱1,234.50
String peso(num n) => '₱${money(n)}';

/// Receipt format (thermal printers can't print ₱): PHP 1234.50
String plain(num n) => 'PHP ${n.toStringAsFixed(2)}';

String pad2(int n) => n.toString().padLeft(2, '0');
String ymd(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';
String ymdhms(DateTime d) => '${ymd(d)} ${pad2(d.hour)}:${pad2(d.minute)}:${pad2(d.second)}';

String newId() => const Uuid().v4();
String sha256Hex(String text) => sha256.convert(utf8.encode(text)).toString();

double sum(List<Rec> rows, String key) =>
    rows.fold(0.0, (t, x) => t + ((x[key] as num?) ?? 0).toDouble());

class ItemAgg {
  int q = 0;
  double t = 0;
}

/// Items sold, best seller (by amount) first.
List<MapEntry<String, ItemAgg>> topItems(List<Rec> sales) {
  final m = <String, ItemAgg>{};
  for (final s in sales) {
    for (final i in (s['items'] as List? ?? const [])) {
      final name = i['name'] as String;
      final a = m.putIfAbsent(name, () => ItemAgg());
      a.q += (i['quantity'] as num).toInt();
      a.t += (i['subtotal'] as num).toDouble();
    }
  }
  final list = m.entries.toList();
  list.sort((a, b) => b.value.t.compareTo(a.value.t));
  return list;
}
