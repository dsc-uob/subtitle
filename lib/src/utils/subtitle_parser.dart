import '../core/exceptions.dart';
import '../core/models.dart';
import 'regexes.dart';
import 'types.dart';

/// It is used to analyze and convert subtitle files into software objects that are
/// viewable and usable. The base class of [SubtitleParser], you can create your
/// custom by extends from this base class.
abstract class ISubtitleParser {
  /// The subtitle object that contain subtitle info (file data and format type).
  final SubtitleObject object;

  const ISubtitleParser(this.object);

  /// Getter method to return the current [SubtitleRegexObject] of this [object].
  SubtitleRegexObject get regexObject;

  /// Abstract method parsing the data from any format and return it as a list of
  /// subtitles.
  List<Subtitle> parsing();

  /// Normalize the text data of subtitle, remove unnecessary characters.
  String normalize(String txt) {
    return txt
        .replaceAll(RegExp(r'<\/?[\w.]+\/?>|\n| {2,}'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }
}

/// Usable class to parsing subtitle file. It is used to analyze and convert subtitle
/// files into software objects that are viewable and usable.
class SubtitleParser extends ISubtitleParser {
  const SubtitleParser(SubtitleObject object) : super(object);

  @override
  SubtitleRegexObject get regexObject {
    switch (object.type) {
      case SubtitleType.vtt:
        return SubtitleRegexObject.vtt();
      case SubtitleType.srt:
        return SubtitleRegexObject.srt();
      case SubtitleType.ttml:
      case SubtitleType.dfxp:
        return SubtitleRegexObject.ttml();
      default:
        throw UnsupportedSubtitleFormat();
    }
  }

  @override
  List<Subtitle> parsing({
    bool shouldNormalizeText = true,
  }) {
    /// Stored variable for subtitles.
    final pattern = regexObject.pattern;

    var regExp = RegExp(pattern);
    var matches = regExp.allMatches(object.data);

    return _decodeSubtitleFormat(
      matches,
      regexObject.type,
      shouldNormalizeText,
    );
  }

  /// Parsing subtitle formats to subtitle and store it in [_subtitles] field.
  List<Subtitle> _decodeSubtitleFormat(
    Iterable<RegExpMatch> matches,
    SubtitleType type,
    bool shouldNormalizeText,
  ) {
    var subtitles = List<Subtitle>.empty(growable: true);

    for (var i = 0; i < matches.length; i++) {
      var matcher = matches.elementAt(i);

      var index = i + 1;
      if (regexObject.cueIndexOffset != null) {
        index =
            int.parse(matcher.group(regexObject.cueIndexOffset!) ?? '$index');
      }

      final data = shouldNormalizeText
          ? normalize(matcher.group(regexObject.textIndexOffset)?.trim() ?? '')
          : matcher.group(regexObject.textIndexOffset)?.trim() ?? '';

      subtitles.add(Subtitle(
        start: _getDuration(matcher, regexObject.startTimeIndexOffset),
        end: _getDuration(matcher, regexObject.endTimeIndexOffset),
        data: data,
        index: index,
      ));
    }

    return subtitles;
  }

  /// Fetch the duration of subtitle by decoding the group inside [matcher].
  Duration _getDuration(RegExpMatch matcher, int indexOffset) => Duration(
        hours:
            int.parse(matcher.group(indexOffset)?.replaceAll(':', '') ?? '0'),
        minutes: int.parse(
            matcher.group(indexOffset + 1)?.replaceAll(':', '') ?? '0'),
        seconds: int.parse(
            matcher.group(indexOffset + 2)?.replaceAll(':', '') ?? '0'),
        milliseconds: int.parse(
            matcher.group(indexOffset + 3)?.replaceAll(':', '').padRight(3, '0') ?? '0'),
      );
}

/// Used in [CustomSubtitleParser] to comstmize parsing of subtitles.
typedef OnParsingSubtitle = List<Subtitle> Function(
    Iterable<RegExpMatch> matchers);

/// Customizable subtitle parser, for custom regexes. You can provide your
/// regex in [pattern], and custom decode in [onParsing].
class CustomSubtitleParser extends ISubtitleParser {
  /// Store the custom regexp of subtitle.
  final String pattern;
  final int? cueIndexOffset;
  final int startTimeIndexOffset;
  final int endTimeIndexOffset;
  final int textIndexOffset;

  /// Decoding the subtitles and return a list from result.
  final OnParsingSubtitle onParsing;

  const CustomSubtitleParser({
    required SubtitleObject object,
    required this.pattern,
    required this.onParsing,
    required this.startTimeIndexOffset,
    required this.endTimeIndexOffset,
    required this.textIndexOffset,
    this.cueIndexOffset,
  }) : super(object);

  @override
  List<Subtitle> parsing() {
    var regExp = RegExp(regexObject.pattern);
    var matches = regExp.allMatches(object.data);
    return onParsing(matches);
  }

  @override
  SubtitleRegexObject get regexObject => SubtitleRegexObject.custom(
      pattern, startTimeIndexOffset, endTimeIndexOffset, textIndexOffset,
      cueIndexOffset: cueIndexOffset);
}
