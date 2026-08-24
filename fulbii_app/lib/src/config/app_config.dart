import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnv { dev, stg, prod }

// OAuth 2.0 Web client IDs are not secrets. Android was migrated to the
// current Firebase project; keep the existing iOS client as the default for
// new iOS builds so the working TestFlight configuration is not replaced.
const _defaultAndroidGoogleWebClientId =
    '706272816323-4bnqeamoe4qucq7the2oscmq8si5huep.apps.googleusercontent.com';
const _defaultIosGoogleWebClientId =
    '14247591730-nru6ieshjvg4fp480rheupp2fjevkq2s.apps.googleusercontent.com';
const _configuredGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);

class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.appLinkBaseUrl,
    required this.googleWebClientId,
    required this.appName,
  });

  final AppEnv env;
  final String apiBaseUrl;
  final String appLinkBaseUrl;
  final String googleWebClientId;
  final String appName;

  static AppConfig fromEnvironment() {
    return forEnvironment(
      envRaw: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: kReleaseMode ? 'prod' : 'dev',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: '',
      ),
      appLinkBaseUrl: const String.fromEnvironment(
        'APP_LINK_BASE_URL',
        defaultValue: '',
      ),
      googleWebClientId: _configuredGoogleWebClientId.trim().isEmpty
          ? (defaultTargetPlatform == TargetPlatform.iOS
              ? _defaultIosGoogleWebClientId
              : _defaultAndroidGoogleWebClientId)
          : _configuredGoogleWebClientId.trim(),
    );
  }

  /// Keeps environment resolution testable without compile-time defines.
  static AppConfig forEnvironment({
    required String envRaw,
    String apiBaseUrl = '',
    String appLinkBaseUrl = '',
    String googleWebClientId = '',
  }) {
    envRaw = envRaw.trim();
    if (kReleaseMode && (envRaw.isEmpty || envRaw == 'dev')) {
      envRaw = 'prod';
    }
    final env = switch (envRaw) {
      'prod' => AppEnv.prod,
      'stg' => AppEnv.stg,
      _ => AppEnv.dev,
    };

    final defaultBaseUrl = switch (env) {
      AppEnv.dev => 'https://fulbii.test/api/v1',
      AppEnv.stg => 'https://fulbii.com/api/v1',
      AppEnv.prod => 'https://fulbii.com/api/v1',
    };
    apiBaseUrl = apiBaseUrl.trim();
    if (kReleaseMode && (apiBaseUrl.isEmpty || apiBaseUrl.contains('127.0.0.1') || apiBaseUrl.contains('localhost') || apiBaseUrl.contains('fulbii.test'))) {
      apiBaseUrl = 'https://fulbii.com/api/v1';
    }
    appLinkBaseUrl = appLinkBaseUrl.trim();
    googleWebClientId = googleWebClientId.trim();

    return AppConfig(
      env: env,
      apiBaseUrl: apiBaseUrl.isEmpty ? defaultBaseUrl : apiBaseUrl,
      appLinkBaseUrl: appLinkBaseUrl.isEmpty
          ? switch (env) {
              AppEnv.dev => 'https://fulbii.test',
              AppEnv.stg => 'https://fulbii.com',
              AppEnv.prod => 'https://fulbii.com',
            }
          : appLinkBaseUrl,
      googleWebClientId: googleWebClientId,
      appName: switch (env) {
        AppEnv.dev => 'Fulbii Dev',
        AppEnv.stg => 'Fulbii Stg',
        AppEnv.prod => 'Fulbii',
      },
    );
  }
}

final appConfigProvider = Provider<AppConfig>((_) {
  throw UnimplementedError('AppConfig must be overridden from main.dart');
});
