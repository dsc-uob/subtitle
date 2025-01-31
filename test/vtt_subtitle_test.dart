import 'dart:io';
import 'package:test/test.dart';
import 'package:subtitle/subtitle.dart';

void main() {
  group('VTT Subtitle Parsing', () {
    test('Test parsing of VTT format from file', () async {
      // Read the VTT subtitle content from the file
      final subtitleFile = File('test/vtt_subtitle');
      final data = await subtitleFile.readAsString();

      // Parse the subtitle string with the correct type
      var controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.vtt,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      // Basic checks
      expect(subtitles.length, 3);

      // First
      expect(subtitles[0].index, 1);
      expect(subtitles[0].start.toString(), '0:00:00.000000');
      expect(subtitles[0].end.toString(), '0:00:02.000000');
      expect(subtitles[0].data, 'Hello from VTT');

      // Second
      expect(subtitles[1].index, 2);
      expect(subtitles[1].start.toString(), '0:00:02.000000');
      expect(subtitles[1].end.toString(), '0:00:03.500000');
      expect(subtitles[1].data, 'This is a test \nfor VTT format');

      // Third
      expect(subtitles[2].index, 3);
      expect(subtitles[2].start.toString(), '0:00:04.000000');
      expect(subtitles[2].end.toString(), '0:00:05.000000');
      expect(subtitles[2].data, 'Goodbye!');
    });
  });
}
