import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regOrg = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _serverUrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    await ApiService.instance.loadBaseUrl();
    _serverUrl.text = ApiService.instance.baseUrl;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regOrg.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _serverUrl.dispose();
    super.dispose();
  }

  Future<void> _saveSession(DrishtiUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsUserNameKey, user.name);
    await prefs.setString(AppConfig.prefsUserOrgKey, user.org);
  }

  Future<void> _goHome(DrishtiUser user) async {
    await _saveSession(user);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(user: user)),
    );
  }

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ApiService.instance.setBaseUrl(_serverUrl.text.trim());
      final data = await ApiService.instance.login(
        _loginEmail.text,
        _loginPass.text,
      );
      final user = DrishtiUser.fromJson(data['user'] as Map<String, dynamic>);
      await _goHome(user);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Cannot reach server. Start Flask: python3 launch.py');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    setState(() { _busy = true; _error = null; });
    try {
      if (_regPass.text.length < 8) {
        throw ApiException('Password must be at least 8 characters.');
      }
      await ApiService.instance.setBaseUrl(_serverUrl.text.trim());
      final user = await ApiService.instance.register(
        name: _regName.text,
        org: _regOrg.text,
        email: _regEmail.text,
        password: _regPass.text,
      );
      await _goHome(user);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Cannot reach server. Start Flask: python3 launch.py');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillDemo() {
    _loginEmail.text = AppConfig.demoEmail;
    _loginPass.text = AppConfig.demoPassword;
    _tabs.index = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEF2FF), Color(0xFFF0FDF4), Color(0xFFFFF7ED)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    const Text('🛰️', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.saffron, AppColors.blue, AppColors.teal],
                      ).createShader(bounds),
                      child: const Text(
                        'DRISHTI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Disaster Risk Intelligence for India',
                      style: TextStyle(color: AppColors.text2, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabs,
                            labelColor: AppColors.blue,
                            unselectedLabelColor: AppColors.text2,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Register'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _serverUrl,
                            decoration: const InputDecoration(
                              labelText: 'Flask server URL',
                              hintText: 'http://10.0.2.2:5001',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Emulator: http://10.0.2.2:5001 · iPhone/Mac: http://127.0.0.1:5001 · Phone: your PC LAN IP',
                            style: TextStyle(fontSize: 11, color: AppColors.text3.withValues(alpha: 1)),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _loginForm(),
                                _registerForm(),
                              ],
                            ),
                          ),
                          const Divider(),
                          InkWell(
                            onTap: _fillDemo,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'DEMO: demo@drishti.gov.in / demo1234 (tap to fill)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.text2, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginEmail,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPass,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _login,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ACCESS SYSTEM'),
          ),
        ),
      ],
    );
  }

  Widget _registerForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              TextField(controller: _regName, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 10),
              TextField(controller: _regOrg, decoration: const InputDecoration(labelText: 'Organisation')),
              const SizedBox(height: 10),
              TextField(controller: _regEmail, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(controller: _regPass, decoration: const InputDecoration(labelText: 'Password (min 8)'), obscureText: true),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _register,
            child: const Text('CREATE ACCOUNT'),
          ),
        ),
      ],
    );
  }
}
