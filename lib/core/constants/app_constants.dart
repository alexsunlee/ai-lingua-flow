class AppConstants {
  AppConstants._();

  static const String appName = 'AI LinguaFlow';
  static const String appVersion = '1.0.0';

  // Language pair (hardcoded for V1.0)
  static const String nativeLanguage = 'zh'; // Chinese
  static const String targetLanguage = 'en'; // English
  static const String nativeLanguageName = '中文';
  static const String targetLanguageName = 'English';

  // Database
  static const String databaseName = 'lingua_flow.db';
  static const int databaseVersion = 1;

  // Gemini
  static const String geminiModel = 'gemini-2.0-flash';
  static const double geminiTemperature = 0.3;
  static const int geminiMaxRetries = 5;

  // TTS
  static const int ttsShortTextMaxWords = 3;

  // SM-2 defaults
  static const double sm2DefaultEaseFactor = 2.5;
  static const double sm2MinEaseFactor = 1.3;
  static const int sm2FirstInterval = 1;
  static const int sm2SecondInterval = 6;

  // Storage keys
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyOnboardingComplete = 'onboarding_complete';

  // Free Dictionary API
  static const String freeDictionaryBaseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en';
}
