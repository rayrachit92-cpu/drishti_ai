import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_field.dart';
import '../widgets/panel.dart';
import '../widgets/risk_card.dart';

class DashboardScreen extends StatefulWidget {
  final DrishtiUser user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _city = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Widget> _cards = [];

  Future<void> _quickPredict() async {
    final city = _city.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a city')));
      return;
    }
    setState(() { _loading = true; _error = null; _cards = []; });
    try {
      final data = await ApiService.instance.predict(city);
      final preds = data['predictions'] as Map<String, dynamic>;
      const icons = {'flood': '🌊', 'drought': '☀️', 'heatwave': '🔥'};
      final cards = preds.entries.map((e) {
        final v = e.value as Map<String, dynamic>;
        final pct = (v['probability_percent'] as num).toDouble();
        final rl = v['risk_level']?.toString() ?? '—';
        return RiskCard(
          title: '${icons[e.key] ?? '⚠️'} ${e.key[0].toUpperCase()}${e.key.substring(1)}',
          percent: pct,
          riskLevel: rl,
        );
      }).toList();
      setState(() => _cards = cards);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Flask API not reachable. Run: python3 launch.py');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Welcome, ${widget.user.name.split(' ').first}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(widget.user.org, style: const TextStyle(color: AppColors.text2)),
        const SizedBox(height: 16),
        Panel(
          title: 'Quick City Predict',
          subtitle: 'Instant ML disaster risk for any supported city.',
          children: [
            CityField(controller: _city),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _quickPredict,
                child: Text(_loading ? 'Analysing…' : '⚡ Quick Predict'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            if (_cards.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _cards[i],
                ),
              ),
            ],
          ],
        ),
        Panel(
          title: 'Platform Overview',
          children: const [
            Text('✅ Flood · Drought · Heatwave ML models', style: TextStyle(height: 1.8)),
            Text('🌐 OpenWeatherMap + WeatherAPI', style: TextStyle(height: 1.8)),
            Text('🏙️ 20 major Indian cities', style: TextStyle(height: 1.8)),
            Text('🚨 Telegram SOS alerts', style: TextStyle(height: 1.8)),
          ],
        ),
      ],
    );
  }
}
