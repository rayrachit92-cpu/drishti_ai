import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _name = TextEditingController();
  final _chatId = TextEditingController();
  bool _sending = false;
  String? _result;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadChatId();
  }

  Future<void> _loadChatId() async {
    final prefs = await SharedPreferences.getInstance();
    _chatId.text = prefs.getString(AppConfig.prefsChatIdKey) ?? '';
  }

  Future<void> _send() async {
    final name = _name.text.trim().isEmpty ? 'Unknown' : _name.text.trim();
    setState(() { _sending = true; _result = null; });

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw ApiException('Location permission denied. Enable GPS in Settings.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (_chatId.text.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.prefsChatIdKey, _chatId.text.trim());
      }

      final msg = await ApiService.instance.sendSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        name: name,
        telegramChatId: _chatId.text.trim().isEmpty ? null : _chatId.text.trim(),
      );

      setState(() {
        _success = true;
        _result = '✅ $msg\n📍 ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } on ApiException catch (e) {
      setState(() { _success = false; _result = '❌ ${e.message}'; });
    } catch (e) {
      setState(() { _success = false; _result = '❌ $e'; });
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _chatId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: 'Emergency SOS',
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '⚠ FOR GENUINE EMERGENCIES ONLY\n'
                'Sends GPS coordinates to Telegram with a Google Maps link.',
                style: TextStyle(color: AppColors.danger, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Your full name')),
            const SizedBox(height: 12),
            TextField(
              controller: _chatId,
              decoration: const InputDecoration(
                labelText: 'Telegram Chat ID',
                hintText: 'e.g. 123456789',
                helperText: 'Get ID from @GetMyChatID_Bot — start @risksosbot first',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Sending…' : '🚨 SEND EMERGENCY SOS'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_success ? AppColors.success : AppColors.danger).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_result!, style: TextStyle(color: _success ? AppColors.success : AppColors.danger)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
