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
    defaultValue: '1.0.0',
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
}
