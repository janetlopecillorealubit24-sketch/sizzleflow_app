import 'dart:convert';
import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _name = TextEditingController(text: '${app.user?['full_name'] ?? ''}');
  late final _email = TextEditingController(text: '${app.user?['email'] ?? ''}');

  String get _photo => '${app.user?['profile_photo'] ?? ''}';

  Future<void> _setPhoto(String b64) async {
    await app.updateUser({...app.user!, 'profile_photo': b64, 'updated_at': ymdhms(DateTime.now())});
    if (mounted) setState(() {});
  }

  Future<void> _changePhoto() async {
    final b = await pickPhotoBase64(context, maxWidth: 512);
    if (b != null) await _setPhoto(b);
  }

  void _photoMenu() {
    if (_photo.isEmpty) {
      _changePhoto();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Profile picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SF.green)),
            ),
            ListTile(
              title: const Text('View'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (c) => Dialog(
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(base64Decode(_photo)),
                          ),
                          const SizedBox(height: 10),
                          GradientButton(label: 'Close', outlined: true, onPressed: () => Navigator.pop(c)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Change'),
              onTap: () {
                Navigator.pop(ctx);
                _changePhoto();
              },
            ),
            ListTile(
              title: const Text('Delete', style: TextStyle(color: SF.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _setPhoto('');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showMsg(context, 'Please enter your full name.');
      return;
    }
    await app.updateUser({
      ...app.user!,
      'full_name': name,
      'email': _email.text.trim(),
      'updated_at': ymdhms(DateTime.now()),
    });
    if (mounted) {
      setState(() {});
      showMsg(context, 'Profile saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SfCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Center(
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _photoMenu,
                      child: Avatar(app.user, size: 96),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_photo.isEmpty ? 'Tap to add a picture' : 'Tap to manage picture',
                      textAlign: TextAlign.center, style: SF.mutedStyle),
                  const SizedBox(height: 14),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: '${app.user?['username'] ?? ''}'),
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(label: 'Save profile', onPressed: _save),
                  const SizedBox(height: 6),
                  GradientButton(label: 'Back', outlined: true, onPressed: () => app.setTab('dash')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
