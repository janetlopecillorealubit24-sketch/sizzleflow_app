import 'dart:convert';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'models.dart';
import 'state.dart';
import 'sync.dart';
import 'utils.dart';

/// Prints receipts on a paired Bluetooth thermal printer (58mm, ESC/POS).
/// Works with no internet - printing is phone <-> printer only.
class PrinterService {
  static const int width = 32; // characters per line on a 58mm printer

  static String receiptText(Rec s) {
    final line = '-' * width;
    String c(String t) => ' ' * max(0, (width - t.length) >> 1) + t;
    String lr(String a, String b) => a + ' ' * max(1, width - a.length - b.length) + b;
    final customer = '${s['customer_name'] ?? ''}';
    final lines = <String>[
      c('SIP & SIZZLE'),
      c('Official Receipt'),
      line,
      'Receipt: ${s['receipt_no']}',
      'Date: ${s['sale_date']}',
      'Cashier: ${s['cashier'] ?? ''}',
      line,
      if (customer.isNotEmpty) 'Customer: $customer',
      for (final i in (s['items'] as List))
        '${i['name']}\n${lr('  ${i['quantity']} x ${plain(i['unit_price'] as num)}', plain(i['subtotal'] as num))}',
      line,
      lr('TOTAL', plain(s['total_amount'] as num)),
      'Payment: ${s['payment_method']}',
      line,
      c('Thank you!'),
      '',
      '',
      '',
    ];
    return lines.join('\n');
  }

  /// ESC @ (reset) + text + feed/cut. Non-ASCII characters become '?'.
  static List<int> escpos(Rec s) {
    final text = receiptText(s).replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
    return [0x1b, 0x40, ...utf8.encode(text), 0x1d, 0x56, 0x42, 0x00];
  }

  static Future<bool> _permission() async {
    await Permission.bluetoothConnect.request();
    return PrintBluetoothThermal.isPermissionBluetoothGranted;
  }

  /// Printers already paired in Android Settings > Bluetooth.
  static Future<List<BluetoothInfo>> pairedPrinters() async {
    if (!await _permission()) {
      throw SfException('Bluetooth permission was denied. Allow "Nearby devices" for SizzleFlow in Android settings.');
    }
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  static Future<void> ensureConnected() async {
    if (await PrintBluetoothThermal.connectionStatus) return;
    final mac = app.printerMac;
    if (mac.isEmpty) {
      throw SfException('No printer selected. Go to Settings > Receipt printing and choose your printer.');
    }
    if (!await _permission()) {
      throw SfException('Bluetooth permission was denied.');
    }
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw SfException('Bluetooth is turned off. Turn it on and try again.');
    }
    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!ok) {
      throw SfException('Could not connect to the printer. Is it on, close by, and paired in Bluetooth settings?');
    }
  }

  static Future<void> printSale(Rec sale) async {
    await ensureConnected();
    final ok = await PrintBluetoothThermal.writeBytes(escpos(sale));
    if (!ok) {
      throw SfException('The printer did not accept the data. Try reconnecting it in Settings.');
    }
  }

  static Rec testSale(String cashier) => {
        'receipt_no': 'TEST-001',
        'sale_date': ymdhms(DateTime.now()),
        'cashier': cashier,
        'payment_method': 'Cash',
        'total_amount': 100,
        'items': [
          {'name': 'Test item', 'quantity': 2, 'unit_price': 50, 'subtotal': 100}
        ],
      };
}
