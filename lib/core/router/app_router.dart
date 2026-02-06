import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/text_study/presentation/pages/text_input_page.dart';
import '../../features/text_study/presentation/pages/text_reader_page.dart';
import '../../features/video_study/presentation/pages/video_input_page.dart';
import '../../features/video_study/presentation/pages/video_player_page.dart';
import '../../features/shadowing/presentation/pages/shadowing_list_page.dart';
import '../../features/shadowing/presentation/pages/shadowing_practice_page.dart';
import '../../features/vocabulary/presentation/pages/vocabulary_list_page.dart';
import '../../features/vocabulary/presentation/pages/review_session_page.dart';
import '../../features/vocabulary/presentation/pages/dictation_page.dart';
import '../../features/assessment/presentation/pages/assessment_page.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/text-study',
    routes: [
      // Bottom navigation shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Text Study
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/text-study',
                builder: (context, state) => const TextInputPage(),
                routes: [
                  GoRoute(
                    path: 'reader/:id',
                    builder: (context, state) => TextReaderPage(
                      studyTextId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 1: Video Study
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/video-study',
                builder: (context, state) => const VideoInputPage(),
                routes: [
                  GoRoute(
                    path: 'player/:id',
                    builder: (context, state) => VideoPlayerPage(
                      videoResourceId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Shadowing
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shadowing',
                builder: (context, state) => const ShadowingListPage(),
                routes: [
                  GoRoute(
                    path: 'practice/:id',
                    builder: (context, state) => ShadowingPracticePage(
                      sourceId: state.pathParameters['id']!,
                      sourceType: state.uri.queryParameters['type'] ?? 'text',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Vocabulary
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vocabulary',
                builder: (context, state) => const VocabularyListPage(),
                routes: [
                  GoRoute(
                    path: 'review',
                    builder: (context, state) => const ReviewSessionPage(),
                  ),
                  GoRoute(
                    path: 'dictation',
                    builder: (context, state) => const DictationPage(),
                  ),
                ],
              ),
            ],
          ),
          // Tab 4: Assessment
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assessment',
                builder: (context, state) => const AssessmentPage(),
              ),
            ],
          ),
        ],
      ),
      // Standalone routes
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
