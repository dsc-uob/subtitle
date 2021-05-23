import 'package:subtitle/subtitle.dart';

void main(List<String> args) async {
  //! By using controller - it's easly way
  var url = Uri.parse(
      'https://brenopolanski.github.io/html5-video-webvtt-example/MIB2-subtitles-pt-BR.vtt');
  var controller = SubtitleController(
      provider: SubtitleProvider.fromNetwork(
    url,
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
