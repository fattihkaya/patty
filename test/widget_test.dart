import 'package:flutter_test/flutter_test.dart';
import 'package:pet_ai/core/app_config.dart';

void main() {
  test('AppConfig vars parse correctly', () {
    expect(AppConfig.geminiApiKey, isA<String>());
    expect(AppConfig.isGeminiConfigured, AppConfig.geminiApiKey.isNotEmpty);
  });
}
