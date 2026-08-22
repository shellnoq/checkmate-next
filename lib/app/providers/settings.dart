import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_storage.dart';
import '../../domain/model/difficulty.dart';
import '../../domain/model/time_control.dart';
import '../../features/board/piece_set.dart';
import '../theme/board_theme.dart';

/// Kullanıcı tercihleri.
@immutable
class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final BoardTheme boardTheme;
  final PieceSet pieceSet;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool showCoordinates;
  final bool showLegalMoves;
  final bool showEvaluation;
  final bool autoQueenPromotion;
  final DifficultyLevel lastDifficulty;
  final TimeControl lastTimeControl;

  const AppSettings({
    required this.locale,
    required this.themeMode,
    required this.boardTheme,
    required this.pieceSet,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.showCoordinates,
    required this.showLegalMoves,
    required this.showEvaluation,
    required this.autoQueenPromotion,
    required this.lastDifficulty,
    required this.lastTimeControl,
  });

  bool get turkish => locale.languageCode == 'tr';

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    BoardTheme? boardTheme,
    PieceSet? pieceSet,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? showCoordinates,
    bool? showLegalMoves,
    bool? showEvaluation,
    bool? autoQueenPromotion,
    DifficultyLevel? lastDifficulty,
    TimeControl? lastTimeControl,
  }) => AppSettings(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    boardTheme: boardTheme ?? this.boardTheme,
    pieceSet: pieceSet ?? this.pieceSet,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    showLegalMoves: showLegalMoves ?? this.showLegalMoves,
    showEvaluation: showEvaluation ?? this.showEvaluation,
    autoQueenPromotion: autoQueenPromotion ?? this.autoQueenPromotion,
    lastDifficulty: lastDifficulty ?? this.lastDifficulty,
    lastTimeControl: lastTimeControl ?? this.lastTimeControl,
  );

  static AppSettings load() => AppSettings(
    locale: Locale(AppStorage.get<String>('locale', 'tr')),
    themeMode: switch (AppStorage.get<String>('themeMode', 'system')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
    boardTheme: BoardTheme.fromId(
      AppStorage.get<String>('boardTheme', 'walnut'),
    ),
    pieceSet: PieceSet.fromId(AppStorage.get<String>('pieceSet', 'classic')),
    soundEnabled: AppStorage.get<bool>('sound', true),
    hapticsEnabled: AppStorage.get<bool>('haptics', true),
    showCoordinates: AppStorage.get<bool>('coordinates', true),
    showLegalMoves: AppStorage.get<bool>('legalMoves', true),
    showEvaluation: AppStorage.get<bool>('evaluation', true),
    autoQueenPromotion: AppStorage.get<bool>('autoQueen', false),
    lastDifficulty: DifficultyLevel.fromId(
      AppStorage.get<String>('difficulty', 'club'),
    ),
    lastTimeControl: TimeControl.fromId(
      AppStorage.get<String>('timeControl', 'rapid10'),
    ),
  );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(AppSettings.load());

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await AppStorage.set('locale', locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await AppStorage.set('themeMode', mode.name);
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    state = state.copyWith(boardTheme: theme);
    await AppStorage.set('boardTheme', theme.id);
  }

  Future<void> setPieceSet(PieceSet set) async {
    state = state.copyWith(pieceSet: set);
    await AppStorage.set('pieceSet', set.id);
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await AppStorage.set('sound', value);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await AppStorage.set('haptics', value);
  }

  Future<void> setCoordinates(bool value) async {
    state = state.copyWith(showCoordinates: value);
    await AppStorage.set('coordinates', value);
  }

  Future<void> setLegalMoves(bool value) async {
    state = state.copyWith(showLegalMoves: value);
    await AppStorage.set('legalMoves', value);
  }

  Future<void> setEvaluation(bool value) async {
    state = state.copyWith(showEvaluation: value);
    await AppStorage.set('evaluation', value);
  }

  Future<void> setAutoQueen(bool value) async {
    state = state.copyWith(autoQueenPromotion: value);
    await AppStorage.set('autoQueen', value);
  }

  Future<void> rememberSetup(
    DifficultyLevel difficulty,
    TimeControl timeControl,
  ) async {
    state = state.copyWith(
      lastDifficulty: difficulty,
      lastTimeControl: timeControl,
    );
    await AppStorage.set('difficulty', difficulty.id);
    await AppStorage.set('timeControl', timeControl.id);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(),
);
