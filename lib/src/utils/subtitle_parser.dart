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
        .replaceAll(RegExp(r'<\/?[\w.]+\/?>| {2,}'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        // Remove multiple new lines
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
  }
}

/// Usable class to parsing subtitle file. It is used to analyze and convert subtitle
/// files into software objects that are viewable and usable.
class SubtitleParser extends ISubtitleParser {
  const SubtitleParser(super.object);

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
    var cleanedData = object.data.replaceAll('\r', '').replaceAll('\r\n', '\n');

    var matches = regExp.allMatches(cleanedData);

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
      final matcher = matches.elementAt(i);
      var index = i + 1;

      if (type == SubtitleType.vtt || type == SubtitleType.srt) {
        index = int.parse(matcher.group(1) ?? '${i + 1}');
      }

      String nonNormalizedText = '';
      if ([SubtitleType.ttml, SubtitleType.dfxp].contains(type)) {
        nonNormalizedText = matcher.group(9)?.trim() ?? '';
      } else {
        nonNormalizedText = matcher.group(10)?.trim() ?? '';
        if (nonNormalizedText == '') {
          nonNormalizedText = matcher.group(11)?.trim() ?? '';
        }
      }

      final normalizedText = shouldNormalizeText
          ? normalize(nonNormalizedText)
          : nonNormalizedText;

      subtitles.add(Subtitle(
        start: _getStartDuration(matcher, type),
        end: _getEndDuration(matcher, type),
        data: normalizedText,
        index: index,
      ));
    }

    return subtitles;
  }

  /// Fetch the start duration of subtitle by decoding the group inside [matcher].
  Duration _getStartDuration(RegExpMatch matcher, SubtitleType type) {
    int hours = 0, minutes = 0, seconds = 0, milliseconds = 0;

    if ([SubtitleType.ttml, SubtitleType.dfxp].contains(type)) {
      hours = int.parse(matcher.group(1) ?? '0');
      minutes = int.parse(matcher.group(2) ?? '0');
      seconds = int.parse(matcher.group(3) ?? '0');
      milliseconds = int.parse(matcher.group(4) ?? '0');
    } else {
      if (matcher.group(3) == null && matcher.group(2) != null) {
        minutes = int.parse(matcher.group(2)?.replaceAll(':', '') ?? '0');
      } else {
        minutes = int.parse(matcher.group(3)?.replaceAll(':', '') ?? '0');
        hours = int.parse(matcher.group(2)?.replaceAll(':', '') ?? '0');
      }
      seconds = int.parse(matcher.group(4)?.replaceAll(':', '') ?? '0');
      milliseconds = int.parse(matcher.group(5) ?? '0');
    }

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  /// Fetch the end duration of subtitle by decoding the group inside [matcher].
  Duration _getEndDuration(RegExpMatch matcher, SubtitleType type) {
    int hours = 0, minutes = 0, seconds = 0, milliseconds = 0;

    if ([SubtitleType.ttml, SubtitleType.dfxp].contains(type)) {
      hours = int.parse(matcher.group(5) ?? '0');
      minutes = int.parse(matcher.group(6) ?? '0');
      seconds = int.parse(matcher.group(7) ?? '0');
      milliseconds = int.parse(matcher.group(8) ?? '0');
    } else {
      if (matcher.group(7) == null && matcher.group(6) != null) {
        minutes = int.parse(matcher.group(6)?.replaceAll(':', '') ?? '0');
      } else {
        minutes = int.parse(matcher.group(7)?.replaceAll(':', '') ?? '0');
        hours = int.parse(matcher.group(6)?.replaceAll(':', '') ?? '0');
      }
      seconds = int.parse(matcher.group(8)?.replaceAll(':', '') ?? '0');
      milliseconds = int.parse(matcher.group(9) ?? '0');
    }

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}

/// Used in [CustomSubtitleParser] to comstmize parsing of subtitles.
typedef OnParsingSubtitle = List<Subtitle> Function(
    Iterable<RegExpMatch> matchers);

/// Customizable subtitle parser, for custom regexes. You can provide your
/// regex in [pattern], and custom decode in [onParsing].
class CustomSubtitleParser extends ISubtitleParser {
  /// Store the custom regexp of subtitle.
  final String pattern;

  /// Decoding the subtitles and return a list from result.
  final OnParsingSubtitle onParsing;

  const CustomSubtitleParser({
    required SubtitleObject object,
    required this.pattern,
    required this.onParsing,
  }) : super(object);

  @override
  List<Subtitle> parsing() {
    var regExp = RegExp(regexObject.pattern);
    var matches = regExp.allMatches(object.data);
    return onParsing(matches);
  }

  @override
  SubtitleRegexObject get regexObject => SubtitleRegexObject.custom(pattern);
}
