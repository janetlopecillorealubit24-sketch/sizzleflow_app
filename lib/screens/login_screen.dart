import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  String _err = '';
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    final ok = await app.login(_u.text.trim().toLowerCase(), _p.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _err = ok ? '' : 'Wrong username or password.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SfCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/logo-transparent.png', height: 120, fit: BoxFit.contain),
                      const SizedBox(height: 12),
                      const Text('SizzleFlow sales system', textAlign: TextAlign.center, style: SF.mutedStyle),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _u,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: const InputDecoration(hintText: 'Username'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _p,
                        obscureText: true,
                        onSubmitted: (_) => _go(),
                        decoration: const InputDecoration(hintText: 'Password'),
                      ),
                      SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_err, style: const TextStyle(color: SF.danger, fontSize: 14)),
                        ),
                      ),
                      GradientButton(label: _busy ? 'Please wait…' : 'Log in', onPressed: _busy ? null : _go),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
