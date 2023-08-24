import 'package:subtitle/subtitle.dart';
import 'package:universal_io/io.dart';

void main(List<String> args) async {
  //! By using controller - it's easly way
  var file = File('subtitles.srt');
  var controller = SubtitleController(
      provider: SubtitleProvider.fromFile(
    file,
    type: SubtitleType.vtt,
  ));

  await controller.initial();
  printResult(controller.subtitles);
}

void printResult(List<Subtitle> subtitles) {
  subtitles.sort((s1, s2) => s1.compareTo(s2));
  for (var result in subtitles) {
    print(
        '(${result.index}) Start: ${result.start}, end: ${result.end} [${result.data}]');
  }
}
