/// Runtime / build-time configuration.
/// API keys should be provided via --dart-define in production.
class AppConfig {
  /// Gemini API key for Patty analysis.
  /// Set at build/run: flutter run --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty;

  /// Kullanım Şartları sayfası URL'i.
  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue: 'https://sites.google.com/view/terms-of-use-patty',
  );

  /// Gizlilik Politikası sayfası URL'i.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://sites.google.com/view/privacy-policy-patty',
  );

  /// Destek / İletişim sayfası URL'i.
  static const String supportUrl = String.fromEnvironment(
    'SUPPORT_URL',
    defaultValue: 'https://sites.google.com/view/patty-page/',
  );

  /// RevenueCat API Key (iOS)
  static const String revenueCatApiKeyIOS = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: 'test_SXWIZWCwCzlcrCZtvzmsbMOSgGF',
  );

  /// RevenueCat API Key (Android) - if you have one
  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  /// RevenueCat Entitlement ID
  static const String entitlementId = 'Patty Pro';

}
