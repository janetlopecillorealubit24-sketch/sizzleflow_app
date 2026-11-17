import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

/// "Create a Menu": categories + products with name, price and picture.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _catName = TextEditingController();
  int? _cat;
  String? _newPhoto; // base64 of a photo picked in this form
  Product? _edit;

  int? get _catValue {
    if (app.cats.any((c) => c['id'] == _cat)) return _cat;
    return app.cats.isEmpty ? null : app.cats.first['id'] as int;
  }

  Uint8List? get _previewBytes {
    if (_newPhoto != null) return base64Decode(_newPhoto!);
    return _edit?.photoBytes;
  }

  void _reset() {
    setState(() {
      _edit = null;
      _newPhoto = null;
      _name.clear();
      _price.clear();
    });
  }

  void _startEdit(Product p) {
    setState(() {
      _edit = p;
      _newPhoto = null;
      _name.text = p.name;
      _price.text = p.price == p.price.roundToDouble() ? p.price.toStringAsFixed(0) : p.price.toStringAsFixed(2);
      _cat = p.categoryId;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final cat = _catValue;
    if (name.isEmpty || price == null || price <= 0 || cat == null) {
      showMsg(context, 'Enter a name, a price above 0, and choose a category.');
      return;
    }
    await Db.saveProduct(
      id: _edit?.id,
      categoryId: cat,
      name: name,
      price: price,
      options: _edit?.options,
      photo: _newPhoto ?? _edit?.photo ?? '',
    );
    _reset();
    FocusManager.instance.primaryFocus?.unfocus();
    await app.loadCatalog();
  }

  Future<void> _addCategory() async {
    final n = _catName.text.trim();
    if (n.isEmpty) return;
    await Db.addCategory(n);
    _catName.clear();
    await app.loadCatalog();
  }

  Future<void> _deleteCategory(Rec c) async {
    final id = c['id'] as int;
    final count = app.products.where((p) => p.categoryId == id).length;
    final name = '${c['name']}';
    final msg = count > 0
        ? 'There are $count product(s) inside "$name". Are you sure you want to delete this category?\n\nThis will also delete all products inside it.'
        : 'There are no products inside "$name". Are you sure you want to delete this category?';
    if (!await confirmDialog(context, msg, yes: 'Delete')) return;
    await Db.deleteCategory(id);
    await app.loadCatalog();
  }

  Future<void> _deleteProduct(Product p) async {
    if (!await confirmDialog(context, 'Remove this menu item?', yes: 'Remove')) return;
    await Db.deactivateProduct(p.id);
    if (_edit?.id == p.id) _reset();
    await app.loadCatalog();
  }

  Widget _thumb(Uint8List? bytes, double size) => ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: bytes != null
            ? Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true)
            : Container(
                width: size,
                height: size,
                color: const Color(0xFFF3E7DF),
                alignment: Alignment.center,
                child: const Text('No photo', style: SF.mutedStyle, textAlign: TextAlign.center),
              ),
      );

  String _catNameOf(int id) {
    for (final c in app.cats) {
      if (c['id'] == id) return '${c['name']}';
    }
    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final preview = _previewBytes;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_edit == null ? 'Create a Menu' : 'Edit menu item',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Create categories first, then add products to each category with a name, price, and picture. '
                    'Saved products appear in the menu list and the New Sale screen.',
                    style: SF.mutedStyle,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _catValue,
                    isExpanded: true,
                    hint: const Text('Category'),
                    items: [
                      for (final c in app.cats) DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['name']}')),
                    ],
                    onChanged: (v) => setState(() => _cat = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _name, decoration: const InputDecoration(hintText: 'Menu item name')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Price'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (preview != null) ...[_thumb(preview, 64), const SizedBox(width: 10)],
                      Expanded(
                        child: GradientButton(
                          label: preview == null ? 'Add picture' : 'Change picture',
                          outlined: true,
                          onPressed: () async {
                            final b = await pickPhotoBase64(context);
                            if (b != null) setState(() => _newPhoto = b);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 10),
                    child: Text('Photo is stored on this device.', style: SF.mutedStyle),
                  ),
                  GradientButton(label: _edit == null ? 'Add menu item' : 'Update menu item', onPressed: _save),
                  if (_edit != null) ...[
                    const SizedBox(height: 6),
                    GradientButton(label: 'Cancel', outlined: true, onPressed: _reset),
                  ],
                ],
              ),
            ),
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _catName,
                          decoration: const InputDecoration(hintText: 'New category name'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(width: 130, child: GradientButton(label: 'Add category', onPressed: _addCategory)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in app.cats)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SfChip(label: '${c['name']}'),
                            const SizedBox(width: 2),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _deleteCategory(c),
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFF0E8)),
                                child: const Text('×', style: TextStyle(color: SF.danger, fontSize: 17, height: 1.1)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  if (app.products.isEmpty) const Text('No menu items yet.', style: SF.mutedStyle),
                  for (final p in app.products)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SF.line))),
                      child: Row(
                        children: [
                          _thumb(p.photoBytes, 44),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${_catNameOf(p.categoryId)} · ${peso(p.price)}', style: SF.mutedStyle),
                              ],
                            ),
                          ),
                          SfChip(label: 'Edit', onTap: () => _startEdit(p)),
                          const SizedBox(width: 4),
                          SfChip(label: 'Delete', color: SF.danger, onTap: () => _deleteProduct(p)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
