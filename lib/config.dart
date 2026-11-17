/// Central settings. The server address and API key can also be changed
/// inside the app (Settings > Server), so these are only the defaults.
class AppConfig {
  /// Must match API_KEY in api/config.php.
  static const String apiKey = 'change-this-secret-key';

  /// 10.0.2.2 is how the Android EMULATOR reaches XAMPP on your PC.
  /// On a real phone, type your PC's Wi-Fi address in Settings instead,
  /// e.g. http://192.168.1.10/SizzleFlow/api
  static const String defaultServerUrl = 'http://10.0.2.2/SizzleFlow/api';
}
