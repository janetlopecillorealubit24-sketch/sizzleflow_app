import 'dart:convert';
import 'dart:typed_data';

/// A database row / JSON object.
typedef Rec = Map<String, dynamic>;

class Product {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final Map<String, dynamic>? options;
  final String photo; // base64 text, '' when none
  final Uint8List? photoBytes;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.options,
    required this.photo,
    required this.photoBytes,
  });

  factory Product.fromRow(Rec r) {
    Map<String, dynamic>? o;
    final raw = r['options'];
    if (raw is String && raw.isNotEmpty) {
      try {
        o = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        o = null;
      }
    }
    final photo = (r['photo'] ?? '') as String;
    Uint8List? bytes;
    if (photo.isNotEmpty) {
      try {
        bytes = base64Decode(photo);
      } catch (_) {
        bytes = null;
      }
    }
    return Product(
      id: r['id'] as int,
      categoryId: r['category_id'] as int,
      name: r['name'] as String,
      price: (r['price'] as num).toDouble(),
      options: o,
      photo: photo,
      photoBytes: bytes,
    );
  }

  String? get type => options?['type'] as String?;

  List<Map<String, dynamic>> get sizes {
    final s = options?['sizes'];
    if (s is! List) return const [];
    return s.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  double priceFor(String? size) {
    if (size != null) {
      for (final s in sizes) {
        if (s['name'] == size) return (s['price'] as num).toDouble();
      }
    }
    return price;
  }
}

class CartLine {
  final String key;
  final Product product;
  final Map<String, String> options;
  final String included;
  final double unitPrice;
  int quantity;

  CartLine({
    required this.key,
    required this.product,
    required this.options,
    required this.included,
    required this.unitPrice,
    this.quantity = 0,
  });

  String get optionText => options.values.where((v) => v.isNotEmpty).join(' · ');

  /// e.g. "Combo A - Regular Burger + Fruit Soda - Lychee"
  String get displayName =>
      [product.name, included, optionText].where((e) => e.isNotEmpty).join(' - ');
}
