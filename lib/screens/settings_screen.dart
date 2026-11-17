import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../db.dart';
import '../printer.dart';
import '../state.dart';
import '../sync.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _url = TextEditingController(text: app.serverUrl);
  late final _key = TextEditingController(text: app.apiKey);
  String _smsg = '';
  String _pmsg = '';
  bool _syncing = false;
  List<int> _pending = [0, 0];
  List<BluetoothInfo> _printers = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final p = await Db.pendingCount();
    if (mounted) setState(() => _pending = p);
  }

  void _keep() {
    app.serverUrl = _url.text;
    app.apiKey = _key.text;
  }

  Future<void> _test() async {
    _keep();
    setState(() => _smsg = 'Testing…');
    final ok = await Sync.ping();
    if (!mounted) return;
    setState(() => _smsg = ok
        ? '✅ Server reachable and key accepted.'
        : '❌ Cannot reach the server, or the API key does not match api/config.php.');
  }

  Future<void> _sync() async {
    _keep();
    setState(() {
      _smsg = 'Syncing…';
      _syncing = true;
    });
    try {
      final r = await Sync.syncNow();
      if (!mounted) return;
      setState(() => _smsg = '✅ Sent ${r.sales} sale(s), ${r.expenses} expense(s).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _smsg = '❌ $e');
    }
    if (mounted) setState(() => _syncing = false);
    _loadPending();
  }

  Future<void> _findPrinters() async {
    setState(() => _pmsg = 'Looking for paired printers…');
    try {
      final list = await PrinterService.pairedPrinters();
      if (!mounted) return;
      setState(() {
        _printers = list;
        _pmsg = list.isEmpty
            ? 'No paired Bluetooth devices found. First pair your printer in Android Settings > Bluetooth (PIN is usually 0000 or 1234).'
            : 'Choose your printer from the list.';
      });
    } catch (e) {
      if (mounted) setState(() => _pmsg = '❌ $e');
    }
  }

  Future<void> _testPrint() async {
    setState(() => _pmsg = 'Printing…');
    try {
      await PrinterService.printSale(PrinterService.testSale('${app.user?['full_name'] ?? ''}'));
      if (mounted) setState(() => _pmsg = '✅ Test receipt sent to the printer.');
    } catch (e) {
      if (mounted) setState(() => _pmsg = '❌ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = <String, String>{
      if (app.printerMac.isNotEmpty) app.printerMac: app.printerName.isEmpty ? app.printerMac : app.printerName,
      for (final p in _printers) p.macAdress: p.name,
    };
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Server address (API folder)', hintText: 'http://192.168.1.10/SizzleFlow/api'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _key,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'API key'),
              ),
              const SizedBox(height: 8),
              GradientButton(
                label: 'Save',
                outlined: true,
                onPressed: () {
                  _keep();
                  setState(() => _smsg = 'Saved.');
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('${_pending[0]} sale(s) and ${_pending[1]} expense(s) waiting to sync.', style: SF.mutedStyle),
              ),
              GradientButton(label: 'Test server', outlined: true, onPressed: _test),
              const SizedBox(height: 6),
              GradientButton(label: _syncing ? 'Syncing…' : 'Sync now', onPressed: _syncing ? null : _sync),
              if (_smsg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_smsg, style: SF.mutedStyle)),
            ],
          ),
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Receipt printing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Bluetooth thermal printer (58mm). Pair it in Android Settings > Bluetooth first.', style: SF.mutedStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: entries.containsKey(app.printerMac) ? app.printerMac : null,
                isExpanded: true,
                hint: const Text('No printer selected'),
                items: [
                  for (final e in entries.entries)
                    DropdownMenuItem<String>(value: e.key, child: Text('${e.value}  (${e.key})', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  app.setPrinter(v, entries[v] ?? v);
                  await PrinterService.disconnect();
                  if (mounted) setState(() => _pmsg = 'Printer selected: ${entries[v] ?? v}');
                },
              ),
              const SizedBox(height: 8),
              GradientButton(label: 'Find paired printers', outlined: true, onPressed: _findPrinters),
              const SizedBox(height: 6),
              GradientButton(label: 'Print test receipt', onPressed: _testPrint),
              if (_pmsg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_pmsg, style: SF.mutedStyle)),
            ],
          ),
        ),
      ],
    );
  }
}
