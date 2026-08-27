import 'dart:io';
import '../config/app_config.dart';

/// Global HttpOverrides that enforces custom User-Agent and security policies
/// across the entire Dart/Flutter process (including Dio, Image.network, GoogleFonts, etc.).
class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.userAgent = AppConfig.effectiveUserAgent;
    return client;
  }
}
