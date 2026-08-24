import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_storage.dart';
import '../../core/utils/age_group.dart';
import '../../domain/model/difficulty.dart';
import '../../domain/model/time_control.dart';
import '../../features/board/piece_set.dart';
import '../theme/board_theme.dart';
import '../theme/theme_packs.dart';

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
  final AgeGroup ageGroup;

  /// Günlük oyun süresi sınırı. `Duration.zero` ise sınır yoktur.
  final Duration dailyLimit;

  /// Etkin tema paketi.
  final ThemePack themePack;

  /// Fon müziği düzeyi (0-1); 0 kapalı.
  final double musicVolume;

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
    required this.ageGroup,
    required this.dailyLimit,
    required this.themePack,
    required this.musicVolume,
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
    AgeGroup? ageGroup,
    Duration? dailyLimit,
    ThemePack? themePack,
    double? musicVolume,
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
    ageGroup: ageGroup ?? this.ageGroup,
    dailyLimit: dailyLimit ?? this.dailyLimit,
    themePack: themePack ?? this.themePack,
    musicVolume: musicVolume ?? this.musicVolume,
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
    ageGroup: AgeGroup.fromId(AppStorage.get<String>('ageGroup', 'adult')),
    dailyLimit: Duration(minutes: AppStorage.get<int>('dailyLimitMinutes', 0)),
    themePack: ThemePacks.fromId(
      AppStorage.get<String>('themePack', 'classic'),
    ),
    musicVolume: (AppStorage.get<double>('musicVolume', 0.0)).clamp(0.0, 1.0),
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

  /// Yaş grubunu değiştirir ve o gruba uygun taş takımını uygular.
  /// Kullanıcı taş takımını sonradan yine serbestçe değiştirebilir.
  Future<void> setAgeGroup(AgeGroup group) async {
    state = state.copyWith(ageGroup: group, pieceSet: group.suggestedPieceSet);
    await AppStorage.set('ageGroup', group.id);
    await AppStorage.set('pieceSet', group.suggestedPieceSet.id);
  }

  /// Tema paketini uygular: tahta, taş takımı ve arka plan birlikte değişir.
  Future<void> setThemePack(ThemePack pack) async {
    state = state.copyWith(
      themePack: pack,
      boardTheme: pack.boardTheme,
      pieceSet: pack.pieceSet,
    );
    await AppStorage.set('themePack', pack.id);
    await AppStorage.set('boardTheme', pack.boardTheme.id);
    await AppStorage.set('pieceSet', pack.pieceSet.id);
  }

  Future<void> setMusicVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(musicVolume: clamped);
    await AppStorage.set('musicVolume', clamped);
  }

  /// Günlük süre sınırını ayarlar. Sıfır dakika sınırı kaldırır.
  Future<void> setDailyLimit(Duration limit) async {
    state = state.copyWith(dailyLimit: limit);
    await AppStorage.set('dailyLimitMinutes', limit.inMinutes);
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
