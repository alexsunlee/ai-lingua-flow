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

  // Gemini 3
  static const String geminiModel = 'gemini-3-flash-preview';
  static const String geminiModelValidation = 'gemini-3-flash-preview';
  static const double geminiTemperature = 1.0; // Gemini 3 strongly recommends 1.0
  static const int geminiMaxRetries = 5;

  // Gemini TTS
  static const String geminiTtsModel = 'gemini-2.5-flash-preview-tts';
  static const String geminiTtsDefaultVoice = 'Kore';
  static const int geminiTtsSampleRate = 24000;
  static const int geminiTtsBitsPerSample = 16;
  static const int geminiTtsChannels = 1;
  static const List<String> geminiTtsVoices = [
    'Aoede', 'Charon', 'Fenrir', 'Kore', 'Leda',
    'Orus', 'Puck', 'Schedar', 'Zephyr',
  ];

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
  static const String keyGeminiTtsVoice = 'gemini_tts_voice';

  // Free Dictionary API
  static const String freeDictionaryBaseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en';
}
