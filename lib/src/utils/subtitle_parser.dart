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
    final cleanedData =
        object.data.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    if (object.type == SubtitleType.vtt || object.type == SubtitleType.srt) {
      return _parseLineBased(cleanedData, shouldNormalizeText);
    }

    final matches = RegExp(regexObject.pattern).allMatches(cleanedData);
    return _decodeSubtitleFormat(matches, regexObject.type, shouldNormalizeText);
  }

  // Matches a VTT/SRT timing line: optional hours, minutes, seconds, ms on both sides.
  static final _timingRegex = RegExp(
    r'(?:(\d+):)?(\d{2}):(\d{2})[.,](\d{1,3})\s*-->\s*(?:(\d+):)?(\d{2}):(\d{2})[.,](\d{1,3})',
  );

  /// Line-based parser for VTT and SRT formats.
  ///
  /// Splits on blank lines, locates each `-->` timing line, and reads the
  /// cue text from the lines that follow it. This avoids the catastrophic
  /// backtracking that the full-block regex can trigger on large files.
  /// It also handles VTT cue identifiers (both numeric and named) by
  /// treating whatever appears before the timing line as the cue label and
  /// using it as the numeric index only when it parses as an integer.
  List<Subtitle> _parseLineBased(String data, bool shouldNormalizeText) {
    final subtitles = <Subtitle>[];
    final blocks = data.split(RegExp(r'\n{2,}'));
    var autoIndex = 1;

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      // Skip VTT header and metadata blocks.
      if (trimmed.startsWith('WEBVTT') ||
          trimmed.startsWith('NOTE') ||
          trimmed.startsWith('STYLE') ||
          trimmed.startsWith('REGION')) {
        continue;
      }

      final lines = trimmed.split('\n');

      int timingIdx = -1;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timingIdx = i;
          break;
        }
      }
      if (timingIdx < 0) continue;

      final timingMatch = _timingRegex.firstMatch(lines[timingIdx]);
      if (timingMatch == null) continue;

      // Use a numeric cue identifier when present; otherwise auto-increment.
      int index = autoIndex++;
      if (timingIdx > 0) {
        final parsed = int.tryParse(lines[timingIdx - 1].trim());
        if (parsed != null) index = parsed;
      }

      final text = lines.sublist(timingIdx + 1).join('\n').trim();
      if (text.isEmpty) continue;

      subtitles.add(Subtitle(
        index: index,
        start: _parseDuration(timingMatch.group(1), timingMatch.group(2),
            timingMatch.group(3), timingMatch.group(4)),
        end: _parseDuration(timingMatch.group(5), timingMatch.group(6),
            timingMatch.group(7), timingMatch.group(8)),
        data: shouldNormalizeText ? normalize(text) : text,
      ));
    }

    return subtitles;
  }

  Duration _parseDuration(
      String? hours, String? minutes, String? seconds, String? ms) {
    return Duration(
      hours: int.parse(hours ?? '0'),
      minutes: int.parse(minutes ?? '0'),
      seconds: int.parse(seconds ?? '0'),
      milliseconds: int.parse(ms ?? '0'),
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

      String nonNormalizedText = '';
      if ([SubtitleType.ttml, SubtitleType.dfxp].contains(type)) {
        nonNormalizedText = matcher.group(9)?.trim() ?? '';
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

  Duration _getStartDuration(RegExpMatch matcher, SubtitleType type) {
    return Duration(
      hours: int.parse(matcher.group(1) ?? '0'),
      minutes: int.parse(matcher.group(2) ?? '0'),
      seconds: int.parse(matcher.group(3) ?? '0'),
      milliseconds: int.parse(matcher.group(4) ?? '0'),
    );
  }

  Duration _getEndDuration(RegExpMatch matcher, SubtitleType type) {
    return Duration(
      hours: int.parse(matcher.group(5) ?? '0'),
      minutes: int.parse(matcher.group(6) ?? '0'),
      seconds: int.parse(matcher.group(7) ?? '0'),
      milliseconds: int.parse(matcher.group(8) ?? '0'),
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
