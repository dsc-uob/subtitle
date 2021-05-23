import 'package:subtitle/subtitle.dart';

const vttData = '''WEBVTT FILE

5
00:00:19.000 --> 00:00:24.000
Which is why we are bringing TV, internet and phone together in <c.highlight>one</c> super package

3
00:00:11.000 --> 00:00:14.000 A:end
Phone conversations where people truly <c.highlight>connect</c>

1
00:00:03.500 --> 00:00:05.000 D:vertical A:start
Everyone wants the most from life

2
00:00:06.000 --> 00:00:09.000 A:start
Like internet experiences that are rich <b>and</b> entertaining


4
00:00:14.500 --> 00:00:18.000
Your favourite TV programmes ready to watch at the touch of a button

6
00:00:24.500 --> 00:00:26.000
<c.highlight>One</c> simple way to get everything

7
00:00:26.500 --> 00:00:27.500 L:12%
UPC

8
00:00:28.000 --> 00:00:30.000 L:75%
Simply for <u>everyone</u>''';

void main(List<String> args) async {
  //! By using controller
  var controller = SubtitleController(
      provider: SubtitleProvider.fromString(
    data: vttData,
    type: SubtitleType.vtt,
  ));

  await controller.initial();
  printResult(controller.subtitles);

  //! By using objects
  var object = SubtitleObject(
    data: vttData,
    type: SubtitleType.vtt,
  );
  var parser = SubtitleParser(object);
  printResult(parser.parsing());
}

void printResult(List<Subtitle> subtitles) {
  subtitles.sort((s1, s2) => s1.compareTo(s2));
  for (var result in subtitles) {
    print(
        '(${result.index}) Start: ${result.start}, end: ${result.end} [${result.data}]');
  }
}
