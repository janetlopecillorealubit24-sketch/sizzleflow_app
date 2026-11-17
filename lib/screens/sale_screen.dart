import 'package:flutter/material.dart';
import '../models.dart';
import '../printer.dart';
import '../seed.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});
  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  late final TextEditingController _customer = TextEditingController(text: app.customerName);
  bool _busy = false;

  String _priceLabel(Product p) {
    final s = p.sizes;
    if (s.isNotEmpty) return '${peso(s.first['price'] as num)} – ${peso(s.last['price'] as num)}';
    return peso(p.price);
  }

  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged,
      {List<String>? labels}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            hint: Text('Select ${label.toLowerCase().contains('size') ? 'size' : 'flavor'}'),
            items: [
              for (var i = 0; i < items.length; i++)
                DropdownMenuItem<String>(value: items[i], child: Text(labels != null ? labels[i] : items[i])),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Items with options (sizes / flavors / combos) ask first, like the web popup.
  Future<void> _chooseProduct(Product p) async {
    final type = p.type;
    if (type == null) {
      app.addToCart(p, {});
      return;
    }
    final o = p.options!;
    final requires = (o['requires'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    final needSoda = type == 'flavorSize' || (type == 'combo' && requires.contains('sodaFlavor'));
    final needFries = type == 'fries' || (type == 'combo' && requires.contains('friesFlavor'));
    final needSize = type == 'flavorSize' || type == 'size';
    final friesFlavors = (o['flavors'] is List && (o['flavors'] as List).isNotEmpty)
        ? (o['flavors'] as List).map((e) => '$e').toList()
        : List<String>.from(kFriesFlavors);
    final sizes = p.sizes;

    String? soda, fries, size, error;
    final picked = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(p.name, style: const TextStyle(color: SF.green, fontSize: 18, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose the required options', style: SF.mutedStyle),
                if (needSoda) _dropdown('Fruit Soda flavor', kSodaFlavors, soda, (v) => setS(() => soda = v)),
                if (needFries) _dropdown('Fries flavor', friesFlavors, fries, (v) => setS(() => fries = v)),
                if (needSize)
                  _dropdown('Size', [for (final s in sizes) '${s['name']}'], size, (v) => setS(() => size = v),
                      labels: [for (final s in sizes) '${s['name']} – ${peso(s['price'] as num)}']),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!, style: const TextStyle(color: SF.danger, fontSize: 14)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (needSoda && soda == null) return setS(() => error = 'Please select a Fruit Soda flavor.');
                if (needFries && fries == null) return setS(() => error = 'Please select a Fries flavor.');
                if (needSize && size == null) return setS(() => error = 'Please select a size.');
                Navigator.pop(ctx, <String, String>{
                  if (needSoda) 'sodaFlavor': soda!,
                  if (needFries) 'friesFlavor': fries!,
                  if (needSize) 'size': size!,
                });
              },
              child: const Text('Add to order'),
            ),
          ],
        ),
      ),
    );
    if (picked != null) app.addToCart(p, picked);
  }

  Future<void> _complete() async {
    setState(() => _busy = true);
    final sale = await app.completeSale(); // saved on the phone first - works offline
    _customer.clear();
    setState(() => _busy = false);
    try {
      await PrinterService.printSale(sale);
    } catch (e) {
      if (mounted) showMsg(context, 'Sale saved. Receipt not printed: $e');
    }
  }

  Widget _qtyButton(String text, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: SF.green),
          ),
          child: Text(text, style: const TextStyle(color: SF.green, fontSize: 16)),
        ),
      );

  Widget _tile(Product p) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _chooseProduct(p),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: SF.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.photoBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.memory(p.photoBytes!,
                      height: 72, width: double.infinity, fit: BoxFit.cover, gaplessPlayback: true),
                ),
                const SizedBox(height: 6),
              ],
              Text(p.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(_priceLabel(p), style: const TextStyle(color: SF.green, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.products.where((p) => app.catFilter == 0 || p.categoryId == app.catFilter).toList();
        final anyPhoto = list.any((p) => p.photoBytes != null);
        final lines = app.cart.values.toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  SfChip(label: 'All', selected: app.catFilter == 0, onTap: () => app.setCategoryFilter(0)),
                  for (final c in app.cats) ...[
                    const SizedBox(width: 6),
                    SfChip(
                      label: '${c['name']}',
                      selected: app.catFilter == c['id'],
                      onTap: () => app.setCategoryFilter(c['id'] as int),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: anyPhoto ? 168 : 104,
              ),
              itemBuilder: (_, i) => _tile(list[i]),
            ),
            const SizedBox(height: 12),
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customer,
                    onChanged: (v) => app.customerName = v,
                    decoration: const InputDecoration(hintText: 'Customer name (optional)'),
                  ),
                  const SizedBox(height: 6),
                  if (lines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Tap an item to add it.', style: SF.mutedStyle),
                    ),
                  for (final l in lines)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SF.line))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.displayName),
                                Text('${peso(l.unitPrice)} each', style: SF.mutedStyle),
                              ],
                            ),
                          ),
                          _qtyButton('−', () => app.changeQty(l.key, -1)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${l.quantity}')),
                          _qtyButton('+', () => app.changeQty(l.key, 1)),
                          const SizedBox(width: 10),
                          Text(peso(l.quantity * l.unitPrice), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(peso(app.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final m in ['Cash', 'GCash']) ...[
                        if (m != 'Cash') const SizedBox(width: 6),
                        Expanded(
                          child: GradientButton(label: m, outlined: app.pay != m, onPressed: () => app.setPay(m)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: _busy ? 'Saving…' : 'Complete sale & print receipt',
                    onPressed: (app.cartTotal > 0 && !_busy) ? _complete : null,
                  ),
                  const SizedBox(height: 6),
                  GradientButton(
                    label: 'Clear order',
                    outlined: true,
                    onPressed: () {
                      _customer.clear();
                      app.clearOrder();
                    },
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
