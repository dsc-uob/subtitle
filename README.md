# Subtitle
## Overview
A library that makes it easy to work with multiple translation file formats, written with highly efficient code, highly customizable (90%), supports Null Safety.

### Currently supported formats:
- WebVTT
- SRT (SubRip)
- TTML (Timed Text Markup Language)
- DFXP (Distribution Format Exchange Profile)
- Custom Subtitle Format

Created from templates made available by Muhammad Hasan Alasady under a [MIT LICENSE](https://github.com/dsc-uob/subtitle/blob/master/LICENCE).

## Features
- **SubtitleProvider:** Simplifies fetching subtitle file data from multiple sources.
- **SubtitleRepository:** Deals with the platform directly to get or download the required data and submit it to the provider.
- **SubtitleParser:** Used to analyze and convert subtitle files into software objects that are viewable and usable.
- **CustomSubtitleParser:** Customizable subtitle parser, for custom regexes.
- **SubtitleRegexObject:** Responsible for providing the necessary expression for the purpose of decoding the content of subtitle files, has 4 children:
    - **VttRegex:** WebVTT regexp.
    - **SrtRegex:** SubRip regexp.
    - **TtmlRegex:** TTML or DFXP regex
    - **CustomRegex:** User define regexp.
- **SubtitleObject:** Store the subtitle file data and its format type.

## Example
```dart
import 'package:subtitle/core/models.dart';
import 'package:subtitle/utils/subtitle_parser.dart';
import 'package:subtitle/utils/types.dart';

/// WebVTT parsing
SubtitleObject vttObject = SubtitleObject(
  type: SubtitleType.vtt,
  data: '''
WEBVTT

00:01.000 --> 00:04.000
- Never drink liquid nitrogen.

00:05.000 --> 00:09.000
- It will perforate your stomach.
- You could die.
''',
);
SubtitleParser vttParser = SubtitleParser(vttObject);

/// SRT parsing
SubtitleObject srtObject = SubtitleObject(
  type: SubtitleType.srt,
  data: '''
1
00:00:00,000 --> 00:00:01,500
For www.forom.com

2
00:00:01,500 --> 00:00:02,500
<i>Tonight's the night.</i>

3
00:00:03,000 --> 00:00:15,000
<i>And it's going to happen
again and again --</i>
''',
);
SubtitleParser srtParser = SubtitleParser(srtObject);

/// TTML and DFXP parsing
SubtitleObject ttmlORdfxpObject = SubtitleObject(
  type: SubtitleType.ttml,
  data: '''
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
      <p xml:id="subtitle3" begin="10.0s" end="16.0s" style="s2">
        It is puzzling, why is it<br/>
        we do not see things upside-down?
      </p>
      <p xml:id="subtitle4" begin="17.2s" end="23.0s">
        You have never heard the Theory,<br/>
        then, that the Brain also is inverted?
      </p>
      <p xml:id="subtitle5" begin="23.0s" end="27.0s" style="s2">
        No indeed! What a beautiful fact!
      </p>
    </div>
  </body>
</tt>
''',
);
SubtitleParser ttmlORdfxpParser = SubtitleParser(ttmlORdfxpObject);

void main() {
  // Print VTT
  print('========== WebVTT ==========');
  printResult(vttParser.parsing());

  print('========== SRT ==========');
  // Print SRT
  printResult(srtParser.parsing());

  print('========== TTML|DFXP ==========');
  // Print TTML or DFXP
  printResult(ttmlORdfxpParser.parsing());
}

void printResult(List<Subtitle> subtitles) {
  for (var result in subtitles) {
    print(
        '(${result.index}) Start: ${result.start}, end: ${result.end} [${result.data}]');
  }
}
```