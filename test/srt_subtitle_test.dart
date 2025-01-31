import 'dart:io';
import 'package:test/test.dart';
import 'package:subtitle/subtitle.dart';

void main() {
  group('SRT Subtitle Parsing', () {
    test('Test parsing of SRT format from file', () async {
      // Read the SRT subtitle content from the file
      final subtitleFile = File('test/srt_subtitle');
      final data = await subtitleFile.readAsString();

      // Parse the subtitle string with the correct type
      var controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: data,
          type: SubtitleType.srt,
        ),
      );
      await controller.initial();
      final subtitles = controller.subtitles;

      // Basic checks
      expect(subtitles.length, 3);

      // First subtitle line
      expect(subtitles[0].index, 1);
      expect(subtitles[0].start.toString(), '0:00:00.000000');
      expect(subtitles[0].end.toString(), '0:00:01.000000');
      expect(subtitles[0].data, 'Hello world!');

      // Second subtitle line
      expect(subtitles[1].index, 2);
      expect(subtitles[1].start.toString(), '0:00:01.001000');
      expect(subtitles[1].end.toString(), '0:00:03.500000');
      expect(subtitles[1].data, 'This is a test for SRT subtitle format.');

      // Third subtitle line
      expect(subtitles[2].index, 3);
      expect(subtitles[2].start.toString(), '0:00:03.600000');
      expect(subtitles[2].end.toString(), '0:00:05.000000');
      expect(subtitles[2].data, 'Subtitle parsing is fun!');
    });
  });
}
