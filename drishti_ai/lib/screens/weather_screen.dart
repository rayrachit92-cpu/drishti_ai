import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_field.dart';
import '../widgets/panel.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _city = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _current;

  Future<void> _fetch() async {
    final city = _city.text.trim();
    if (city.isEmpty) return;
    setState(() { _loading = true; _current = null; });
    try {
      final data = await ApiService.instance.fetchWeather(city);
      setState(() => _current = data['current'] as Map<String, dynamic>);
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
    final c = _current;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: 'City Weather Lookup',
          subtitle: 'Live temperature, humidity, rainfall, wind.',
          children: [
            CityField(controller: _city),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _fetch,
                child: Text(_loading ? 'Loading…' : '🔍 Get Weather'),
              ),
            ),
            if (c != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _tile('Temperature', '${c['temp_c']}°C'),
                  _tile('Humidity', '${c['humidity']}%'),
                  _tile('Rainfall', '${c['precip_mm']} mm'),
                  _tile('Wind', '${c['wind_kph']} km/h'),
                  _tile('Condition', (c['condition'] as Map)['text']?.toString() ?? '—'),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
