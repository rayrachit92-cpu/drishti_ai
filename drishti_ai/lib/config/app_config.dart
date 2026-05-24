import 'dart:io';

/// Flask backend base URL.
/// - Android emulator: 10.0.2.2 maps to host machine localhost
/// - iOS simulator / macOS: 127.0.0.1
/// - Physical device: set your computer's LAN IP in app Settings
class AppConfig {
  static const demoEmail = 'demo@drishti.gov.in';
  static const demoPassword = 'demo1234';
  static const weatherApiKey = '14c27bb50b0044d6b37175716263101';
  static const prefsApiBaseKey = 'drishti_api_base';
  static const prefsChatIdKey = 'drishti_telegram_chat_id';
  static const prefsUserNameKey = 'drishti_user_name';
  static const prefsUserOrgKey = 'drishti_user_org';

  static String defaultApiBase() {
    if (Platform.isAndroid) return 'http://10.0.2.2:5001';
    return 'http://127.0.0.1:5001';
  }
}
