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

const ttmlText = '''
<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <head>
    <metadata xmlns:ttm="http://www.w3.org/ns/ttml#metadata">
      <ttm:title>Timed Text TTML Example</ttm:title>
      <ttm:copyright>The Authors (c) 2006</ttm:copyright>
    </metadata>
    <styling xmlns:tts="http://www.w3.org/ns/ttml#styling">
      <!-- s1 specifies default color, font, and text alignment -->
      <style xml:id="s1"
        tts:color="white"
        tts:fontFamily="proportionalSansSerif"
        tts:fontSize="22px"
        tts:textAlign="center"
      />
      <!-- alternative using yellow text but otherwise the same as style s1 -->
      <style xml:id="s2" style="s1" tts:color="yellow"/>
      <!-- a style based on s1 but justified to the right -->
      <style xml:id="s1Right" style="s1" tts:textAlign="end" />     
      <!-- a style based on s2 but justified to the left -->
      <style xml:id="s2Left" style="s2" tts:textAlign="start" />
    </styling>
    <layout xmlns:tts="http://www.w3.org/ns/ttml#styling">
      <region xml:id="subtitleArea"
        style="s1"
        tts:extent="560px 62px"
        tts:padding="5px 3px"
        tts:backgroundColor="black"
        tts:displayAlign="after"
      />
    </layout> 
  </head>
  <body region="subtitleArea">
    <div>
      <p xml:id="subtitle1" begin="0.76s" end="3.45s">
        It seems a paradox, does it not,
      </p>
      <p xml:id="subtitle2" begin="5.0s" end="10.0s">
        that the image formed on<br/>
        the Retina should be inverted?
      </p>
      <p xml:id="subtitle3" begin="10.0s" end="14.0s" style="s2">
        It is puzzling, why is it<br/>
        we do not see things upside-down?
      </p>
      <p xml:id="subtitle4" begin="14.5s" end="17.0s" style="s2">
        ===== This line should be merged into somewhere =====</p>
      <p xml:id="subtitle5" begin="17.2s" end="23.0s">
        You have never heard the Theory,<br/>then, that the Brain also is inverted?
      </p>
      <p xml:id="subtitle6" begin="24.5s" end="27.0s" style="s2">
        ##### No indeed! What a beautiful fact! #####
      </p>
    </div>
  </body>
</tt>
''';

void main(List<String> args) async {
  //! By using controller
  var vttController = SubtitleController(
      provider: SubtitleProvider.fromString(
    data: vttData,
    type: SubtitleType.vtt,
  ));

  await vttController.initial();
  print('======= subtitle vtt =======');
  printResult(vttController.subtitles);

  var ttmlController = SubtitleController(
      provider: SubtitleProvider.fromString(
    data: ttmlText,
    type: SubtitleType.ttml,
  ));
  await ttmlController.initial();

  print('\n\n======= subtitle ttml =======');
  printResult(ttmlController.subtitles);

  var mergedController =
      await SubtitleController.merge(vttController, ttmlController);
  print('\n\n======= after merged =======');
  printResult(mergedController.subtitles);
}

void printResult(List<Subtitle> subtitles) {
  subtitles.sort((s1, s2) => s1.compareTo(s2));
  for (var result in subtitles) {
    print(
        '(${result.index}) Start: ${result.start}, end: ${result.end} [${result.data}]');
  }
}
