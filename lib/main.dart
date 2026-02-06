import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/database/app_database.dart';
import 'core/network/gemini_client.dart';
import 'core/router/app_router.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await AppDatabase.database;

  // Configure dependency injection
  await configureDependencies();

  // Auto-configure Gemini if API key exists
  const storage = FlutterSecureStorage();
  final apiKey = await storage.read(key: AppConstants.keyGeminiApiKey);
  if (apiKey != null && apiKey.isNotEmpty) {
    getIt<GeminiClient>().configure(apiKey);
  }

  // Initialize router (checks onboarding state)
  await AppRouter.init();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
