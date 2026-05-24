import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_field.dart';
import '../widgets/panel.dart';
import '../widgets/risk_card.dart';

class LiveAlertScreen extends StatefulWidget {
  const LiveAlertScreen({super.key});

  @override
  State<LiveAlertScreen> createState() => _LiveAlertScreenState();
}

class _LiveAlertScreenState extends State<LiveAlertScreen> {
  final _city = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _alert;

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'RED':
        return AppColors.danger;
      case 'ORANGE':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Future<void> _fetch() async {
    final city = _city.text.trim();
    if (city.isEmpty) return;
    setState(() { _loading = true; _alert = null; });
    try {
      final data = await ApiService.instance.liveAlert(city);
      setState(() => _alert = data);
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
    final d = _alert;
    final ml = d?['ml_predictions'] as Map<String, dynamic>?;
    const icons = {'flood': '🌊', 'drought': '☀️', 'heatwave': '🔥'};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: 'Rainfall Alert Checker',
          subtitle: 'RED / ORANGE / GREEN + ML overlay.',
          children: [
            CityField(controller: _city),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _fetch,
                child: Text(_loading ? 'Fetching…' : '📡 Get Live Alert'),
              ),
            ),
            if (d != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _levelColor(d['level']?.toString() ?? '').withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _levelColor(d['level']?.toString() ?? '').withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 ${d['city']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('🌡️ ${d['temperature']}°C  💧 ${d['humidity']}%  🌧️ ${d['rain_mm']} mm/h'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor(d['level']?.toString() ?? ''),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        d['level']?.toString() ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(d['message']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              if (ml != null && ml.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ml.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final key = ml.keys.elementAt(i);
                      final v = ml[key] as Map<String, dynamic>;
                      return RiskCard(
                        title: '${icons[key] ?? '⚠️'} ${key[0].toUpperCase()}${key.substring(1)}',
                        percent: (v['probability_percent'] as num).toDouble(),
                        riskLevel: v['risk_level']?.toString() ?? '—',
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 260,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        (d['lat'] as num).toDouble(),
                        (d['lon'] as num).toDouble(),
                      ),
                      initialZoom: 10,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.drishti_ai',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              (d['lat'] as num).toDouble(),
                              (d['lon'] as num).toDouble(),
                            ),
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on, color: _levelColor(d['level']?.toString() ?? ''), size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
