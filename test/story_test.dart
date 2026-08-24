import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/stories/chess_stories.dart';

void main() {
  test('hikâyeler tekil, iki dilli ve boş paragrafsız', () {
    final ids = <String>{};
    for (final story in StorySet.all) {
      expect(ids.add(story.id), isTrue);
      expect(story.trTitle, isNotEmpty);
      expect(story.enTitle, isNotEmpty);
      expect(story.paragraphs.length, greaterThanOrEqualTo(4));
      for (final paragraph in story.paragraphs) {
        expect(paragraph.tr.trim(), isNotEmpty);
        expect(paragraph.en.trim(), isNotEmpty);
      }
    }
    expect(StorySet.all.length, greaterThanOrEqualTo(5));
  });
}
