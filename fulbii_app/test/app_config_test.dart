import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/config/app_config.dart';

void main() {
  test('development uses the local simulator backend', () {
    final config = AppConfig.forEnvironment(envRaw: 'dev');

    expect(config.env, AppEnv.dev);
    expect(config.apiBaseUrl, 'http://127.0.0.1:8000/api/v1');
    expect(config.appLinkBaseUrl, 'https://fulbii.test');
    expect(config.appName, 'Fulbii Dev');
  });

  test('production continues to use fulbii.com', () {
    final config = AppConfig.forEnvironment(envRaw: 'prod');

    expect(config.env, AppEnv.prod);
    expect(config.apiBaseUrl, 'https://fulbii.com/api/v1');
  });
}
