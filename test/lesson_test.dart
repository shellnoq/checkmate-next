import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/lessons/opening_lesson.dart';

void main() {
  group('LessonSet', () {
    test('her ders başlangıçtan itibaren yasal bir satırdır', () {
      for (final lesson in LessonSet.all) {
        expect(lesson.uci.length, lesson.plies.length, reason: lesson.id);
        Position position = Chess.initial;
        for (final uci in lesson.uci) {
          final move = position.normalizeMove(NormalMove.fromUci(uci));
          expect(position.isLegal(move), isTrue, reason: '${lesson.id}: $uci');
          position = position.play(move);
        }
      }
    });

    test('sıra düzeni doğru: beyaz hamleleri öğrencinin', () {
      for (final lesson in LessonSet.all) {
        for (int i = 0; i < lesson.plies.length; i++) {
          expect(
            lesson.plies[i].isStudent,
            i.isEven,
            reason: '${lesson.id} ply $i',
          );
        }
      }
    });

    test('her adımın iki dilde anlatımı var ve kimlikler tekil', () {
      final ids = <String>{};
      for (final lesson in LessonSet.all) {
        expect(ids.add(lesson.id), isTrue);
        for (final ply in lesson.plies) {
          expect(ply.tr, isNotEmpty);
          expect(ply.en, isNotEmpty);
        }
      }
    });
  });
}
