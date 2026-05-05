import 'dart:developer' as dev;

import '../core/exceptions.dart';
import '../core/models.dart';
import 'regexes.dart';
import 'types.dart';

void _log(String msg, {int level = 800}) {
  dev.log(msg, name: 'subtitle', level: level);
}

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
    // VTT/SRT use a line-oriented format that the cue-block parser
    // handles in O(n) time. The previous regex-backed implementation
    // had nested unbounded quantifiers and could backtrack for tens of
    // seconds on pathological inputs (e.g. 10k+ cue karaoke VTTs).
    if (object.type == SubtitleType.vtt || object.type == SubtitleType.srt) {
      return _parseCueBlocks(shouldNormalizeText);
    }

    /// Stored variable for subtitles.
    final pattern = regexObject.pattern;

    var regExp = RegExp(pattern);
    var cleanedData = object.data.replaceAll('\r', '').replaceAll('\r\n', '\n');

    var matches = regExp.allMatches(cleanedData);
    final matchCount = matches.length;
    if (matchCount == 0) {
      final head = cleanedData.length > 64
          ? cleanedData.substring(0, 64)
          : cleanedData;
      _log('parsing: 0 matches for type=${object.type}'
          ' bodyBytes=${cleanedData.length}'
          ' head="${head.replaceAll('\n', r'\n')}"',
          level: 1000);
    } else {
      _log('parsing: $matchCount matches for type=${object.type}');
    }

    return _decodeSubtitleFormat(
      matches,
      regexObject.type,
      shouldNormalizeText,
    );
  }

  /// Hand-rolled cue-block parser for VTT and SRT. Splits the file
  /// into blocks separated by blank lines, then for each block:
  ///
  ///   1. Locates the timing line (the line containing `-->`).
  ///   2. Pulls start/end timestamps from the front of that line.
  ///       Anything after the end timestamp on the timing line is VTT
  ///       positioning (`line:`, `align:`, `position:`, …) and is
  ///       ignored.
  ///   3. Joins every following non-blank line as the cue text.
  ///
  /// Compared to the regex path, this:
  ///   - Never backtracks. Big files parse in linear time.
  ///   - Handles VTT positioning directives without group-juggling.
  ///   - Skips orphan blocks (header, NOTE, STYLE, malformed cues)
  ///     instead of failing the whole parse.
  List<Subtitle> _parseCueBlocks(bool shouldNormalizeText) {
    final cleaned =
        object.data.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = cleaned.split('\n');

    final result = <Subtitle>[];
    var index = 1;
    var i = 0;

    while (i < lines.length) {
      // Skip blank lines between blocks.
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      if (i >= lines.length) break;

      // Collect the next non-blank block (up to the next blank line).
      final blockStart = i;
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        i++;
      }
      final block = lines.sublist(blockStart, i);

      // Find the timing line (first line containing `-->`).
      var arrowLine = -1;
      for (var k = 0; k < block.length; k++) {
        if (block[k].contains('-->')) {
          arrowLine = k;
          break;
        }
      }
      if (arrowLine < 0) {
        // Header (WEBVTT), NOTE, STYLE, or stray text — drop the block.
        continue;
      }

      final timing = _parseTimingLine(block[arrowLine]);
      if (timing == null) continue;

      final textParts = block.sublist(arrowLine + 1);
      var text = textParts.join('\n');
      if (shouldNormalizeText) text = normalize(text);

      result.add(Subtitle(
        start: timing.start,
        end: timing.end,
        data: text,
        index: index++,
      ));
    }

    if (result.isEmpty) {
      final head =
          cleaned.length > 64 ? cleaned.substring(0, 64) : cleaned;
      _log('parsing: 0 cues for type=${object.type}'
          ' bodyBytes=${cleaned.length}'
          ' head="${head.replaceAll('\n', r'\n')}"',
          level: 1000);
    } else {
      _log('parsing: ${result.length} cues for type=${object.type}');
    }
    return result;
  }

  /// Pulls `(start, end)` durations out of a VTT/SRT timing line.
  /// Accepts either `.` or `,` as the millisecond separator and an
  /// optional hour component. Returns null if the line doesn't match.
  static final RegExp _timingRegex = RegExp(
    r'((?:\d{1,3}:)?\d{1,2}:\d{2}[.,]\d{1,3})\s*-->\s*((?:\d{1,3}:)?\d{1,2}:\d{2}[.,]\d{1,3})',
  );

  _Timing? _parseTimingLine(String line) {
    final m = _timingRegex.firstMatch(line);
    if (m == null) return null;
    final start = _parseTimestamp(m.group(1)!);
    final end = _parseTimestamp(m.group(2)!);
    if (start == null || end == null) return null;
    return _Timing(start, end);
  }

  Duration? _parseTimestamp(String raw) {
    final t = raw.replaceAll(',', '.');
    final dotIdx = t.lastIndexOf('.');
    if (dotIdx < 0) return null;
    final ms = int.tryParse(t.substring(dotIdx + 1).padRight(3, '0'));
    final hms = t.substring(0, dotIdx).split(':');
    if (ms == null || hms.length < 2 || hms.length > 3) return null;
    int hours = 0, minutes = 0, seconds = 0;
    if (hms.length == 3) {
      hours = int.tryParse(hms[0]) ?? 0;
      minutes = int.tryParse(hms[1]) ?? 0;
      seconds = int.tryParse(hms[2]) ?? 0;
    } else {
      minutes = int.tryParse(hms[0]) ?? 0;
      seconds = int.tryParse(hms[1]) ?? 0;
    }
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: ms,
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
        var group10 = matcher.group(10)?.trim() ?? '';
        // For VTT format, group 10 may contain positioning/styling directives
        // If it contains VTT directives, skip it and use group 11 instead
        if (type == SubtitleType.vtt && group10.isNotEmpty &&
            RegExp(r'\s*(?:line|align|position|size|region|vertical):').hasMatch(group10)) {
          nonNormalizedText = matcher.group(11)?.trim() ?? '';
        } else {
          nonNormalizedText = group10;
          if (nonNormalizedText == '') {
            nonNormalizedText = matcher.group(11)?.trim() ?? '';
          }
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

class _Timing {
  final Duration start;
  final Duration end;
  const _Timing(this.start, this.end);
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
