import '../../core/storage/app_storage.dart';
import '../model/difficulty.dart';
import '../lessons/opening_lesson.dart';
import '../puzzles/puzzle.dart';
import 'coin_service.dart';

/// Tek bir başarım tanımı.
class Achievement {
  const Achievement({
    required this.id,
    required this.trName,
    required this.enName,
    required this.trHint,
    required this.enHint,
    required this.coins,
    required this.isMet,
  });

  final String id;
  final String trName;
  final String enName;
  final String trHint;
  final String enHint;

  /// Kazanıldığında verilen coin.
  final int coins;

  /// Koşul; yalnızca kalıcı istatistiklerden okur.
  final bool Function() isMet;

  String label(bool turkish) => turkish ? trName : enName;
  String hint(bool turkish) => turkish ? trHint : enHint;

  bool get isUnlocked => AppStorage.statOf('ach_$id') > 0;
}

/// Başarımların tanımı ve çekme temelli denetimi.
///
/// Denetim, oyun/bulmaca/analiz sonlarında çağrılır; koşulu sağlanan ve
/// henüz açılmamış her başarım açılır, coini eklenir ve arayüzün
/// duyurabilmesi için döndürülür.
class AchievementService {
  AchievementService._();

  static bool _anyStrongWin(int minTier) => DifficultyLevel.values
      .where((d) => d.tier >= minTier)
      .any((d) => AppStorage.statOf('wins_${d.id}') > 0);

  static int _gamesTotal() =>
      AppStorage.statOf('wins') +
      AppStorage.statOf('losses') +
      AppStorage.statOf('draws');

  static bool _allPuzzlesOfDepth(int depth) => PuzzleSet.all
      .where((p) => p.mateIn == depth)
      .every((p) => AppStorage.statOf('puzzle_solved_${p.id}') > 0);

  static final List<Achievement> all = [
    Achievement(
      id: 'first_game',
      trName: 'İlk Adım',
      enName: 'First Step',
      trHint: 'Bir oyunu tamamla',
      enHint: 'Finish a game',
      coins: 5,
      isMet: () => _gamesTotal() >= 1,
    ),
    Achievement(
      id: 'first_win',
      trName: 'İlk Zafer',
      enName: 'First Victory',
      trHint: 'Bilgisayara karşı bir oyun kazan',
      enHint: 'Win a game against the computer',
      coins: 10,
      isMet: () => AppStorage.statOf('wins') >= 1,
    ),
    Achievement(
      id: 'five_wins',
      trName: 'Isınıyorum',
      enName: 'Warming Up',
      trHint: 'Beş galibiyete ulaş',
      enHint: 'Reach five wins',
      coins: 20,
      isMet: () => AppStorage.statOf('wins') >= 5,
    ),
    Achievement(
      id: 'ten_games',
      trName: 'Müdavim',
      enName: 'Regular',
      trHint: 'On oyun tamamla',
      enHint: 'Finish ten games',
      coins: 15,
      isMet: () => _gamesTotal() >= 10,
    ),
    Achievement(
      id: 'beat_club',
      trName: 'Kulüp Fatihi',
      enName: 'Club Conqueror',
      trHint: 'Kulüp seviyesinde ya da üstünde kazan',
      enHint: 'Win at club level or above',
      coins: 20,
      isMet: () => _anyStrongWin(4),
    ),
    Achievement(
      id: 'beat_master',
      trName: 'Usta Avcısı',
      enName: 'Master Hunter',
      trHint: 'Ulusal Usta ya da Büyükusta seviyesinde kazan',
      enHint: 'Win at National Master or Grandmaster level',
      coins: 40,
      isMet: () => _anyStrongWin(7),
    ),
    Achievement(
      id: 'first_puzzle',
      trName: 'Çözücü',
      enName: 'Solver',
      trHint: 'Bir bulmaca çöz',
      enHint: 'Solve a puzzle',
      coins: 5,
      isMet: () => AppStorage.statOf('puzzles_solved_total') >= 1,
    ),
    Achievement(
      id: 'puzzle_all_m1',
      trName: 'Tek Hamlelik İş',
      enName: 'One-Move Wonder',
      trHint: 'Bir hamlelik matların tümünü çöz',
      enHint: 'Solve every mate-in-one',
      coins: 15,
      isMet: () => _allPuzzlesOfDepth(1),
    ),
    Achievement(
      id: 'puzzle_master',
      trName: 'Bulmaca Ustası',
      enName: 'Puzzle Master',
      trHint: 'Tüm bulmacaları çöz',
      enHint: 'Solve every puzzle',
      coins: 40,
      isMet: () => PuzzleSet.all.every(
        (p) => AppStorage.statOf('puzzle_solved_${p.id}') > 0,
      ),
    ),
    Achievement(
      id: 'student',
      trName: 'Öğrenci',
      enName: 'Student',
      trHint: 'Bir açılış dersini bitir',
      enHint: 'Finish an opening lesson',
      coins: 10,
      isMet: () => LessonSet.all.any(
        (l) => AppStorage.statOf('lesson_done_${l.id}') > 0,
      ),
    ),
    Achievement(
      id: 'graduate',
      trName: 'Mezun',
      enName: 'Graduate',
      trHint: 'Tüm açılış derslerini bitir',
      enHint: 'Finish every opening lesson',
      coins: 30,
      isMet: () => LessonSet.all.every(
        (l) => AppStorage.statOf('lesson_done_${l.id}') > 0,
      ),
    ),
    Achievement(
      id: 'marathon',
      trName: 'Maratoncu',
      enName: 'Marathoner',
      trHint: 'Toplam bir saat oyna',
      enHint: 'Play a total of one hour',
      coins: 15,
      isMet: () => AppStorage.statOf('time_total') >= 3600,
    ),
    Achievement(
      id: 'analyst',
      trName: 'Analist',
      enName: 'Analyst',
      trHint: 'Bir maçı analiz et',
      enHint: 'Analyse a game',
      coins: 10,
      isMet: () => AppStorage.statOf('analyses_run') >= 1,
    ),
  ];

  /// Koşulu sağlanan yeni başarımları açar ve döndürür.
  static Future<List<Achievement>> checkAll() async {
    final unlocked = <Achievement>[];
    for (final achievement in all) {
      if (achievement.isUnlocked) continue;
      if (!achievement.isMet()) continue;
      await AppStorage.setStat('ach_${achievement.id}', 1);
      await CoinService.add(achievement.coins);
      unlocked.add(achievement);
    }
    return unlocked;
  }
}
