import 'dart:io';
import 'package:test/test.dart';
import 'package:subtitle/subtitle.dart';

void main() {
  group('TTML Subtitle Parsing', () {
    test('Test parsing of TTML format from file', () async {
      // Read the TTML subtitle content from the file
      final subtitleFile = File('test/ttml_subtitle');
      final data = await subtitleFile.readAsString();

      // Parse the subtitle string with the correct type (TTML)
      var controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.ttml,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      // Basic checks
      expect(subtitles.length, 3);

      // First TTML subtitle
      expect(subtitles[0].index, 1);
      expect(subtitles[0].start.toString(), '0:00:01.000000');
      expect(subtitles[0].end.toString(), '0:00:03.000000');
      expect(subtitles[0].data, 'Hello from TTML');

      // Second TTML subtitle
      expect(subtitles[1].index, 2);
      expect(subtitles[1].start.toString(), '0:00:03.000000');
      expect(subtitles[1].end.toString(), '0:00:04.500000');
      expect(subtitles[1].data, 'This is a TTML subtitle');

      // Third TTML subtitle
      expect(subtitles[2].index, 3);
      expect(subtitles[2].start.toString(), '0:00:05.000000');
      expect(subtitles[2].end.toString(), '0:00:07.000000');
      expect(subtitles[2].data, 'Goodbye from TTML');
    });
  });
}
