import 'package:go_router/go_router.dart';

import '../domain/match/match_protocol.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/game/game_screen.dart';
import '../features/history/archive_screen.dart';
import '../features/history/replay_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lessons/lesson_screen.dart';
import '../features/lessons/lessons_screen.dart';
import '../features/openings/openings_screen.dart';
import '../features/parent/parent_area_screen.dart';
import '../features/puzzles/puzzle_play_screen.dart';
import '../features/puzzles/puzzles_screen.dart';
import '../features/play/new_game_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stories/stories_screen.dart';
import '../features/stories/story_screen.dart';
import '../features/themes/themes_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/new-game',
      builder: (context, state) => NewGameScreen(
        kind: state.uri.queryParameters['mode'] == 'local'
            ? MatchKind.passAndPlay
            : MatchKind.engine,
      ),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) =>
          GameScreen(config: state.extra! as MatchConfig),
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveScreen(),
    ),
    GoRoute(
      path: '/replay',
      builder: (context, state) =>
          ReplayScreen(game: state.extra! as Map<String, Object?>),
    ),
    GoRoute(
      path: '/openings',
      builder: (context, state) => const OpeningsScreen(),
    ),
    GoRoute(
      path: '/lessons',
      builder: (context, state) => const LessonsScreen(),
    ),
    GoRoute(
      path: '/lesson',
      builder: (context, state) =>
          LessonScreen(lessonId: state.extra! as String),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/puzzles',
      builder: (context, state) => const PuzzlesScreen(),
    ),
    GoRoute(
      path: '/puzzle',
      builder: (context, state) =>
          PuzzlePlayScreen(puzzleId: state.extra! as String),
    ),
    GoRoute(
      path: '/parent',
      builder: (context, state) => const ParentAreaScreen(),
    ),
    GoRoute(
      path: '/stories',
      builder: (context, state) => const StoriesScreen(),
    ),
    GoRoute(
      path: '/story',
      builder: (context, state) => StoryScreen(storyId: state.extra! as String),
    ),
    GoRoute(path: '/themes', builder: (context, state) => const ThemesScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
