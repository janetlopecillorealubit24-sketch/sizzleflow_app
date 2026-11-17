import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'theme.dart';
import 'utils.dart';

class SfCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SfCard({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xF0FFFFFF),
          border: Border.all(color: SF.line),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0D176247), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

/// The green->orange gradient button (.btn); [outlined] gives the white .btn.alt look.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  const GradientButton({super.key, required this.label, required this.onPressed, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: outlined ? null : SF.gradient,
            color: outlined ? Colors.white : null,
            border: outlined ? Border.all(color: SF.green) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              alignment: Alignment.center,
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: outlined ? SF.green : Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped chip (.chip). Selected = gradient.
class SfChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;
  const SfChip({super.key, required this.label, this.selected = false, this.onTap, this.color = SF.green});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: selected ? SF.gradient : null,
            color: selected ? null : Colors.white,
            border: Border.all(color: selected ? Colors.transparent : color),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 14)),
        ),
      );
}

/// Row of summary cards: [[label, value], ...]
class StatRow extends StatelessWidget {
  final List<List<String>> stats;
  const StatRow(this.stats, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: SfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats[i][0], style: SF.mutedStyle),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(stats[i][1], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
}

class LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  const LabelValueRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SF.line))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            Text(value),
          ],
        ),
      );
}

class Avatar extends StatelessWidget {
  final Rec? user;
  final double size;
  const Avatar(this.user, {super.key, this.size = 36});

  String get _initials {
    final parts = '${user?['full_name'] ?? '?'}'.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final s = parts.map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }

  @override
  Widget build(BuildContext context) {
    final photo = '${user?['profile_photo'] ?? ''}';
    Widget inner = Center(
      child: Text(_initials,
          style: TextStyle(color: SF.greenDark, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
    );
    if (photo.isNotEmpty) {
      try {
        inner = Image.memory(base64Decode(photo), width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true);
      } catch (_) {}
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFFF6A12B), Color(0xFFFFF0D7)]),
        border: Border.all(color: const Color(0xE6FFFFFF), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: inner,
    );
  }
}

/// Date text field that opens the calendar. Value is yyyy-mm-dd.
class DateField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const DateField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(value) ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (d != null) onChanged(ymd(d));
        },
        child: InputDecorator(
          decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today, size: 18, color: SF.green)),
          child: Text(value),
        ),
      );
}

Future<bool> confirmDialog(BuildContext context, String message, {String yes = 'Yes'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
      ],
    ),
  );
  return r ?? false;
}

void showMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );

/// Lets the user pick a gallery photo or take one; returns it as base64 text (or null).
Future<String?> pickPhotoBase64(BuildContext context, {double maxWidth = 600}) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: SF.green),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: SF.green),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (src == null) return null;
  final x = await ImagePicker().pickImage(source: src, maxWidth: maxWidth, imageQuality: 75);
  if (x == null) return null;
  return base64Encode(await x.readAsBytes());
}
