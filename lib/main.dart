import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.init();
  runApp(const SizzleFlowApp());
}

class SizzleFlowApp extends StatelessWidget {
  const SizzleFlowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SizzleFlow',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Cream gradient behind every screen (the web body background).
        builder: (context, child) => Container(
          decoration: const BoxDecoration(gradient: SF.bgGradient),
          child: child,
        ),
        home: ListenableBuilder(
          listenable: app,
          builder: (context, _) => app.user == null ? const LoginScreen() : const Shell(),
        ),
      );
}
