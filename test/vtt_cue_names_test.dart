import 'package:test/test.dart';
import 'package:subtitle/subtitle.dart';

void main() {
  group('VTT Cue Names', () {
    test('parses VTT with named (non-numeric) cue identifiers', () async {
      const data = '''
WEBVTT

intro
00:00:00.000 --> 00:00:02.000
Hello from VTT

chapter-1
00:00:02.000 --> 00:00:03.500
This is a named cue

00:00:04.000 --> 00:00:05.000
No identifier
''';

      final controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.vtt,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      expect(subtitles.length, 3);

      expect(subtitles[0].start.toString(), '0:00:00.000000');
      expect(subtitles[0].end.toString(), '0:00:02.000000');
      expect(subtitles[0].data, 'Hello from VTT');

      expect(subtitles[1].start.toString(), '0:00:02.000000');
      expect(subtitles[1].end.toString(), '0:00:03.500000');
      expect(subtitles[1].data, 'This is a named cue');

      expect(subtitles[2].start.toString(), '0:00:04.000000');
      expect(subtitles[2].end.toString(), '0:00:05.000000');
      expect(subtitles[2].data, 'No identifier');
    });

    test('parses VTT with positioning directives on timing line', () async {
      const data = '''
WEBVTT

1
00:00:00.000 --> 00:00:02.000 line:20% position:50% align:center
Positioned subtitle

2
00:00:02.000 --> 00:00:03.500
Normal subtitle
''';

      final controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.vtt,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      expect(subtitles.length, 2);
      expect(subtitles[0].data, 'Positioned subtitle');
      expect(subtitles[1].data, 'Normal subtitle');
    });
  });
}
