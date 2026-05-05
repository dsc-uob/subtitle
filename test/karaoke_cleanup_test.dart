import 'package:subtitle/subtitle.dart';
import 'package:test/test.dart';

/// Builds a synthetic VTT that mirrors the pathological pattern seen in
/// the wild on `kaa.mx` karaoke tracks: each line is repeated as the
/// full sentence plus one cue per word, all sharing identical timings.
String _karaokeVtt({
  required int linesPerSentence,
  required int sentenceCount,
}) {
  final buf = StringBuffer('WEBVTT\n\n');
  for (var s = 0; s < sentenceCount; s++) {
    final startMs = s * 200;
    final endMs = startMs + 100;
    String fmt(int ms) {
      final total = ms;
      final hours = total ~/ 3600000;
      final mins = (total % 3600000) ~/ 60000;
      final secs = (total % 60000) ~/ 1000;
      final mss = total % 1000;
      String two(int n) => n.toString().padLeft(2, '0');
      String three(int n) => n.toString().padLeft(3, '0');
      return '${two(hours)}:${two(mins)}:${two(secs)}.${three(mss)}';
    }

    final timing = '${fmt(startMs)} --> ${fmt(endMs)}';
    buf.writeln(timing);
    buf.writeln('full sentence number $s');
    buf.writeln();
    for (var w = 0; w < linesPerSentence; w++) {
      buf.writeln(timing);
      buf.writeln('word $w');
      buf.writeln();
    }
  }
  return buf.toString();
}

void main() {
  test('cleanup collapses identical-time word fragments to the longest cue',
      () async {
    final data = _karaokeVtt(linesPerSentence: 5, sentenceCount: 200);
    final ctl = SubtitleController(
      provider: StringSubtitle(data: data, type: SubtitleType.vtt),
    );
    final sw = Stopwatch()..start();
    await ctl.initial();
    sw.stop();

    // 200 sentences × (1 full + 5 word fragments) = 1200 raw cues.
    // After cleanup, each (start, end) group collapses to the longest
    // text → 200 cues.
    expect(ctl.subtitles.length, 200,
        reason: 'expected one cue per sentence after dedup');
    expect(ctl.subtitles.first.data, startsWith('full sentence'));

    // Sanity: parse stays well under a second on the synthetic input.
    expect(sw.elapsedMilliseconds, lessThan(1000));
  });

  test('multiDurationSearch returns hits via binary search (O(log n + k))',
      () async {
    final data = _karaokeVtt(linesPerSentence: 0, sentenceCount: 5000);
    final ctl = SubtitleController(
      provider: StringSubtitle(data: data, type: SubtitleType.vtt),
    );
    await ctl.initial();
    expect(ctl.subtitles.length, 5000);

    final sw = Stopwatch()..start();
    for (var i = 0; i < 5000; i++) {
      ctl.multiDurationSearch(Duration(milliseconds: i * 200 + 50));
    }
    sw.stop();
    // Linear scan would be ~25M comparisons; binary path stays under a
    // second comfortably.
    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
