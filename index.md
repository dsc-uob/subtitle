# Subtitle
A library that makes it easy to work with multiple translation file formats, written with highly efficient code, 
highly customizable (90%), supports **Sound Null Safety**.

### Currently supported formats:
- WebVTT
- SRT (SubRip)
- TTML (Timed Text Markup Language)
- DFXP (Distribution Format Exchange Profile)
- Custom Subtitle Format

Created by Muhammad Hasan Alasady under a [MIT LICENSE](https://github.com/dsc-uob/subtitle/blob/master/LICENCE).

## Usage
You have a lot of way to use this package, with internet, local file, assets file(In flutter),
and from string. In this section you will learn how to use each of this:

1. ### Internet Subtitles
You have two ways to use subtitles on the internet, firstly using `SubtitleController` and it's the
easly way, secondly by using `SubtitleProvider` and `SubtitleParser`, this is both of ways:

- #### By `SubtitleController`:
Firstly provide the link of subtitle (should be an object of [Uri](https://api.dart.dev/stable/2.13.1/dart-core/Uri-class.html)), 
after that you can use `SubtitleProvider.fromNetwork(url)` or `NetworkSubtitle(url)`:

```dart
var url = Uri.parse(
    'https://brenopolanski.github.io/html5-video-webvtt-example/MIB2-subtitles-pt-BR.vtt');
var controller = SubtitleController(
  provider: SubtitleProvider.fromNetwork(url),
);
```

Or

```dart
var url = Uri.parse(
    'https://brenopolanski.github.io/html5-video-webvtt-example/MIB2-subtitles-pt-BR.vtt');
var controller = SubtitleController(
  provider: NetworkSubtitle(url),
);
```

- #### By `SubtitleProvider` and `SubtitleParser`:
Like the last one, provide the link and provider, after that create a new object of `SubtitleObject` and `await` it to preparing 
the subtitle data, in the last you can use `SubtitleParser` to parsing the subtitles:

```dart
var url = Uri.parse(
    'https://brenopolanski.github.io/html5-video-webvtt-example/MIB2-subtitles-pt-BR.vtt');

SubtitleProvider provider = NetworkSubtitle(url);
SubtitleObject object = await provider.getSubtitle();
SubtitleParser parser = SubtitleParser(object);     
```

After creating the controller you have to initialize it by call `controller.initial()`, it's `async` function, so you have to `await` it.

```dart
await controller.initial();
```

When you intialize it, you can use this methods to dealing with subtitles:

1. **controller.subtitles:** The List of subtitles. 
2. **controller.durationSearch(\<Your Duration\>):** Provide a duration to fetch the first subtitle in range of this duration. 
3. **controller.multiDurationSearch(\<Your Duration\>):** Provide a duration to fetch a list of subtitles in range of this duration. 
4. **controller.getAll(\<separator `optional`\>)**: Return all subtitles as a single string with custom separator (default is `', '`).

Check the [API Reference](https://pub.dev/documentation/subtitle/latest/) or [GitHub Wiki](https://github.com/dsc-uob/subtitle/wiki) for more

2. ### File Subtitles
Like the last one, you have same two ways, just prepare your file, and replace the `SubtitleProvider` in all places to be `SubtitleProvider.fromFile(file)` or `FileSubtitle(file)`

- #### By `SubtitleController`:

```dart
var file = File('example/data.vtt');
var controller = SubtitleController(
  provider: SubtitleProvider.fromNetwork(file),
);
```

Or

```dart
var file = File('example/data.vtt');
var controller = SubtitleController(
  provider: FileSubtitle(file),
);
```

- #### By `SubtitleProvider` and `SubtitleParser`:

```dart
var file = File('example/data.vtt');

SubtitleProvider provider = FileSubtitle(file);
SubtitleObject object = await provider.getSubtitle();
SubtitleParser parser = SubtitleParser(object);
```

3. ### String Subtitles
Same others just replace providers to be instance of `StringSubtitle` or `SubtitleProvider.fromString()`.

4. ### Flutter Asset
In flutter asset case you have to create you class (called it like `AssetSubtitle`), by extends `SubtitleProvider`, and use `rootBundle` to load the string of asset file, after created it, do like first example, just replace providers to be instance of your new class, like:

```dart
class AssetSubtitle extends SubtitleProvider {
  /// The subtitle path in your assets.
  final String path;
  final SubtitleType? type;

  const AssetSubtitle(
    this.path, {
    this.type,
  });

  @override
  Future<SubtitleObject> getSubtitle() async {
    // Preparing subtitle file data by reading the file.
    final data = await rootBundle.loadString(path);

    // Find the current format type of subtitle.
    final ext = extension(path);
    final type = this.type ?? getSubtitleType(ext);

    return SubtitleObject(data: data, type: type);
  }
}
```

When you need to use it:
```dart
var path = 'files/subtitles/1.vtt';
var controller = SubtitleController(
  provider: AssetSubtitle(path),
);
```


## Components
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
- **SubtitleController:** Controller subtitles, preparing it, decoding, sorting, and search.


## Example
```dart
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
```
