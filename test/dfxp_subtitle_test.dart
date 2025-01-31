import 'dart:io';
import 'package:test/test.dart';
import 'package:subtitle/subtitle.dart';

void main() {
  group('DFXP Subtitle Parsing', () {
    test('Test parsing of DFXP format from file', () async {
      // Read the DFXP subtitle content
      final subtitleFile = File('test/dfxp_subtitle');
      final data = await subtitleFile.readAsString();

      // Parse the subtitle string with the correct type
      var controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.dfxp,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      // Basic checks
      expect(subtitles.length, 2);

      // First
      expect(subtitles[0].index, 1);
      expect(subtitles[0].start.toString(), '0:00:00.500000');
      expect(subtitles[0].end.toString(), '0:00:02.000000');
      expect(subtitles[0].data, 'Hello from DFXP');

      // Second
      expect(subtitles[1].index, 2);
      expect(subtitles[1].start.toString(), '0:00:02.000000');
      expect(subtitles[1].end.toString(), '0:00:04.000000');
      expect(subtitles[1].data, 'Still the same TTML style');
    });
  });
}
