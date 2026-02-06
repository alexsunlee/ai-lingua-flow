import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await AppDatabase.database;

  // Configure dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
