import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_field.dart';
import '../widgets/panel.dart';
import '../widgets/risk_card.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _city = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _data;

  Future<void> _analyse() async {
    final city = _city.text.trim();
    if (city.isEmpty) return;
    setState(() { _loading = true; _data = null; });
    try {
      final data = await ApiService.instance.predict(city);
      setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
    final d = _data;
    final preds = d?['predictions'] as Map<String, dynamic>?;
    const icons = {'flood': '🌊', 'drought': '☀️', 'heatwave': '🔥'};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: 'Risk Analysis Engine',
          subtitle: 'Flood, drought & heatwave — ML powered.',
          children: [
            CityField(controller: _city, hint: 'Enter city for disaster risk'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _analyse,
                child: Text(_loading ? 'Analysing…' : '📊 Analyse Disaster Risk'),
              ),
            ),
            if (preds != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final key = preds.keys.elementAt(i);
                    final v = preds[key] as Map<String, dynamic>;
                    return RiskCard(
                      title: '${icons[key] ?? '⚠️'} ${key[0].toUpperCase()}${key.substring(1)}',
                      percent: (v['probability_percent'] as num).toDouble(),
                      riskLevel: v['risk_level']?.toString() ?? '—',
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '📍 ${d!['location']} · ${d['date']} · ${d['method']}\n'
                  '🌡️ ${d['current_conditions']?['temp_c'] ?? '—'}°C  '
                  '💧 ${d['current_conditions']?['humidity'] ?? '—'}%  '
                  '🌧️ ${d['current_conditions']?['rain_mm'] ?? '—'} mm',
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
