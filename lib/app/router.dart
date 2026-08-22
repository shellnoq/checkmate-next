import 'package:go_router/go_router.dart';

import '../domain/match/match_protocol.dart';
import '../features/game/game_screen.dart';
import '../features/history/archive_screen.dart';
import '../features/home/home_screen.dart';
import '../features/play/new_game_screen.dart';
import '../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
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
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
