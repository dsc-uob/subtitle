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
}

/// Usable class to parsing subtitle file. It is used to analyze and convert subtitle
/// files into software objects that are viewable and usable.
class SubtitleParser extends ISubtitleParser {
  /// Stored variable for subtitles.
  final List<Subtitle> _subtitles;

  SubtitleParser(SubtitleObject object)
      : _subtitles = List<Subtitle>.empty(growable: true),
        super(object);

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
  List<Subtitle> parsing() {
    _subtitles.clear();
    final pattern = regexObject.pattern;

    var regExp = RegExp(pattern);
    var matches = regExp.allMatches(object.data);

    switch (regexObject.type) {
      case SubtitleType.vtt:
      case SubtitleType.srt:
        _getSubtitleFor_VTT_SRT_Format(matches);
        break;
      case SubtitleType.ttml:
      case SubtitleType.dfxp:
        _getSubtitleFor_TTML_DFXP_Format(matches);
        break;
      default:
    }

    return _subtitles;
  }

  /// Parsing WebVTT or SRT format to subtitle and store it in [_subtitles] field.
  void _getSubtitleFor_VTT_SRT_Format(Iterable<RegExpMatch> matches) {
    for (var i = 0; i < matches.length; i++) {
      var matcher = matches.elementAt(i);
      var start = Duration(
        seconds: int.parse(matcher.group(2)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(3)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(4) ?? '0'),
        milliseconds: int.parse(matcher.group(5) ?? '0'),
      );
      var end = Duration(
        seconds: int.parse(matcher.group(6)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(7)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(8) ?? '0'),
        milliseconds: int.parse(matcher.group(9) ?? '0'),
      );

      _subtitles.add(Subtitle(
        start: start,
        end: end,
        data: matcher.group(11)?.trim() ?? '',
        index: int.parse(matcher.group(1) ?? '${i + 1}'),
      ));
    }
  }

  /// Parsing TTML or DFXP format to subtitle and store it in [_subtitles] field.
  void _getSubtitleFor_TTML_DFXP_Format(Iterable<RegExpMatch> matches) {
    for (var i = 0; i < matches.length; i++) {
      var matcher = matches.elementAt(i);
      var start = Duration(
        seconds: int.parse(matcher.group(2)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(3)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(4) ?? '0'),
        milliseconds: int.parse(matcher.group(5) ?? '0'),
      );
      var end = Duration(
        seconds: int.parse(matcher.group(6)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(7)?.replaceAll(':', '') ?? '0') +
            int.parse(matcher.group(8) ?? '0'),
        milliseconds: int.parse(matcher.group(9) ?? '0'),
      );

      _subtitles.add(Subtitle(
        start: start,
        end: end,
        data: matcher.group(11)?.trim() ?? '',
        index: i + 1,
      ));
    }
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
