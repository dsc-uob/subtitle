import 'dart:io';
import 'package:test/test.dart';
import 'package:subtitle/subtitle.dart';

void main() {
  group('Subtitle Parsing', () {
    test('Test parsing of subtitle from text file', () async {
      // Read subtitle content from the text file
      final subtitleFile = File('test/string_subtitle');
      final data = await subtitleFile.readAsString();

      // Parse the subtitle string
      var controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.vtt,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      // Expected output
      expect(subtitles.length, 10);
      expect(subtitles[0].index, 1);
      expect(subtitles[0].start.toString(), '0:00:02.250000');
      expect(subtitles[0].end.toString(), '0:00:03.509000');
      expect(subtitles[0].data, 'Why am I here?');

      expect(subtitles[9].index, 10);
      expect(subtitles[9].start.toString(), '0:00:16.729000');
      expect(subtitles[9].end.toString(), '0:00:17.829000');
      expect(subtitles[9].data, 'Uh Thanks.');
    });
  });
}
