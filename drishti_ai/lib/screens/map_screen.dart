import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import '../widgets/risk_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _cities = [];
  int _high = 0, _mod = 0, _low = 0;

  Color _riskColor(double risk) {
    if (risk >= 60) return AppColors.danger;
    if (risk >= 30) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _cities = []; });
    try {
      final cities = await ApiService.instance.predictAllCities();
      var hi = 0, mo = 0, lo = 0;
      for (final c in cities) {
        final r = (c['max_risk'] as num?)?.toDouble() ?? 0;
        if (r >= 60) {
          hi++;
        } else if (r >= 30) {
          mo++;
        } else {
          lo++;
        }
      }
      setState(() {
        _cities = cities;
        _high = hi;
        _mod = mo;
        _low = lo;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final atRisk = _cities.where((c) => ((c['max_risk'] as num?)?.toDouble() ?? 0) >= 30).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: 'India Risk Map',
          subtitle: 'ML analysis across 20 major cities.',
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _load,
                child: Text(_loading ? 'Analysing all cities…' : '🔍 Predict All Cities'),
              ),
            ),
            if (_cities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _stat('Total', '${_cities.length}'),
                  _stat('High', '$_high', AppColors.danger),
                  _stat('Moderate', '$_mod', AppColors.warning),
                  _stat('Low', '$_low', AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 320,
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(22.5, 80.0),
                      initialZoom: 5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.drishti_ai',
                      ),
                      CircleLayer(
                        circles: _cities.map((c) {
                          final risk = (c['max_risk'] as num).toDouble();
                          return CircleMarker(
                            point: LatLng(
                              (c['lat'] as num).toDouble(),
                              (c['lon'] as num).toDouble(),
                            ),
                            radius: risk >= 60 ? 14 : risk >= 30 ? 10 : 7,
                            color: _riskColor(risk).withValues(alpha: 0.85),
                            borderColor: Colors.white,
                            borderStrokeWidth: 2,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              if (atRisk.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: atRisk.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = atRisk[i];
                      final r = (c['max_risk'] as num).toDouble();
                      return RiskCard(
                        title: '🏙️ ${c['city']}',
                        percent: r,
                        riskLevel: r >= 60 ? 'HIGH' : 'MODERATE',
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value, [Color? color]) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text3)),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color ?? AppColors.text)),
          ],
        ),
      ),
    );
  }
}
