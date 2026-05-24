import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'live_alert_screen.dart';
import 'map_screen.dart';
import 'prediction_screen.dart';
import 'sos_screen.dart';
import 'weather_screen.dart';

class MainShell extends StatefulWidget {
  final DrishtiUser user;

  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _clock = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    _clock.value = DateTime.now();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _tick();
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('drishti_user_name');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  String get _initials {
    return widget.user.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(user: widget.user),
      const WeatherScreen(),
      const PredictionScreen(),
      const LiveAlertScreen(),
      const MapScreen(),
      const SosScreen(),
    ];

    final titles = [
      'Dashboard',
      'Weather',
      'Prediction',
      'Live Alert',
      'Risk Map',
      'SOS',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DRISHTI', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
            Text(titles[_index], style: const TextStyle(fontSize: 12, color: AppColors.text2, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: _clock,
            builder: (_, t, __) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  DateFormat('dd MMM, HH:mm:ss').format(t),
                  style: const TextStyle(fontSize: 11, color: AppColors.text2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                  child: Text(_initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue)),
                ),
                const SizedBox(width: 6),
                Text(widget.user.name.split(' ').first, style: const TextStyle(fontSize: 13)),
                IconButton(icon: const Icon(Icons.logout, size: 20), onPressed: _logout, tooltip: 'Sign out'),
              ],
            ),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: 'Weather'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Predict'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Alert'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.sos_outlined), selectedIcon: Icon(Icons.sos), label: 'SOS'),
        ],
      ),
    );
  }
}
