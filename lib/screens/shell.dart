import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'history_screen.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'sale_screen.dart';
import 'settings_screen.dart';

/// Header + side menu + the current screen (the web app's renderMain).
class Shell extends StatelessWidget {
  const Shell({super.key});

  static const tabs = [
    ['menu', 'Menu'],
    ['sale', 'New Sale'],
    ['hist', 'History'],
    ['exp', 'Expenses'],
    ['rep', 'Report'],
    ['dash', 'Dashboard'],
  ];

  Widget _body() {
    switch (app.tab) {
      case 'menu':
        return const MenuScreen();
      case 'sale':
        return const SaleScreen();
      case 'hist':
        return const HistoryScreen();
      case 'exp':
        return const ExpensesScreen();
      case 'rep':
        return const ReportScreen();
      case 'set':
        return const SettingsScreen();
      case 'profile':
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  // The Shell itself is const, so it listens to the app state here
  // (otherwise tab changes would not redraw it).
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: app, builder: (context, _) => _scaffold(context));

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: SF.gradient)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 3,
        scrolledUnderElevation: 3,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x33176247),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset('assets/images/logo-transparent.png', height: 40, fit: BoxFit.contain),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profile menu',
            color: Colors.white,
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) {
              if (v == 'profile') app.setTab('profile');
              if (v == 'settings') app.setTab('set');
              if (v == 'logout') app.logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${app.user?['full_name']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: SF.text)),
                    Text('${app.user?['username']} - ${app.user?['role']}', style: SF.mutedStyle),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
              const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Log out', style: TextStyle(color: SF.danger)),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Avatar(app.user),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        width: 270,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Text('SizzleFlow',
                    style: TextStyle(color: SF.green, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              const Divider(color: SF.line, height: 1),
              const SizedBox(height: 8),
              for (final t in tabs)
                ListTile(
                  selected: app.tab == t[0],
                  selectedColor: SF.green,
                  selectedTileColor: const Color(0xFFE8F3ED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(t[1],
                      style: TextStyle(fontSize: 16, fontWeight: app.tab == t[0] ? FontWeight.w600 : FontWeight.w400)),
                  onTap: () {
                    Navigator.pop(context);
                    app.setTab(t[0]);
                  },
                ),
            ],
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: KeyedSubtree(key: ValueKey(app.tab), child: _body()),
        ),
      ),
    );
  }
}
