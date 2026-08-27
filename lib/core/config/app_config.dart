class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:4002/api',
  );
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'E-Dokter',
  );
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.3.0',
  );
  static const int connectTimeout = int.fromEnvironment(
    'CONNECT_TIMEOUT',
    defaultValue: 15000,
  );
  static const int receiveTimeout = int.fromEnvironment(
    'RECEIVE_TIMEOUT',
    defaultValue: 20000,
  );
  static const bool enableWriteAccess = bool.fromEnvironment(
    'ENABLE_WRITE_ACCESS',
    defaultValue: false,
  );
  static const bool enableInAppNotifications = bool.fromEnvironment(
    'ENABLE_IN_APP_NOTIFICATIONS',
    defaultValue: true,
  );
  static const bool enableSystemNotifications = bool.fromEnvironment(
    'ENABLE_SYSTEM_NOTIFICATIONS',
    defaultValue: true,
  );
  static const String userAgent = String.fromEnvironment(
    'USER_AGENT',
    defaultValue: 'SIMRS-Dokter/1.3.0 (Flutter; Mobile)',
  );
  static const String wafCustomHeader = String.fromEnvironment(
    'WAF_CUSTOM_HEADER',
    defaultValue: 'X-Custom-Token',
  );
  static const String wafCustomValue = String.fromEnvironment(
    'WAF_CUSTOM_VALUE',
    defaultValue: 'f0110wm3',
  );

  /// Dynamically builds the complete User-Agent string. If a WAF bypass value
  /// is defined, it embeds it directly so that 100% of socket connections
  /// (including font loaders, images, and non-Dio network calls) carry the token.
  static String get effectiveUserAgent {
    if (wafCustomValue.isNotEmpty) {
      return '$userAgent Token:$wafCustomValue';
    }
    return userAgent;
  }
}
