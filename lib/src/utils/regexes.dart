import 'subtitle_parser.dart';
import 'types.dart';

/// Class responsible for providing the necessary expression for the purpose of decoding
/// the content of subtitle files for the purpose of using them in the converted class
/// [SubtitleParser] to provide proper subtitle objects, and then using them in the controller
/// to display the required content within the required time.
///
/// - Supported Regex:
///   - ### VTT
///   - ### SRT
///   - ### TTML
///   - ### DFXP
///   - ### Custom
///
/// - Unsupported formats:
///   - ### SBV
///   - ### SSA
///
abstract class SubtitleRegexObject {
  /// The regex class
  final String pattern;
  final SubtitleType type;
  final int? cueIndexOffset;
  final int textIndexOffset;
  final int startTimeIndexOffset;
  final int endTimeIndexOffset;

  const SubtitleRegexObject({
    required this.pattern,
    required this.type,
    required this.startTimeIndexOffset,
    required this.endTimeIndexOffset,
    required this.textIndexOffset,
    this.cueIndexOffset,
  });

  /// # WebVTT Regex
  ///
  /// This is the web vtt regex. Used in [SubtitleParser] to parsing this subtitle format to
  /// dart code.
  factory SubtitleRegexObject.vtt() => const VttRegex();

  /// # SubRip Regex
  ///
  /// This is the subrip regex. Used in [SubtitleParser] to parsing this subtitle format to
  /// dart code.
  factory SubtitleRegexObject.srt() => const SrtRegex();

  /// # Timed Text Markup Language
  ///
  /// This is the **ttml** or **dfxp** regex. Used in [SubtitleParser] to parsing this subtitle format to
  /// dart code.
  factory SubtitleRegexObject.ttml() => const TtmlRegex();

  /// # Custom (User defin type)
  ///
  /// This is the user define regex. Used in [SubtitleParser] to parsing this subtitle format to
  /// dart code.
  factory SubtitleRegexObject.custom(String pattern, int startTimeIndexOffset,
          int endTimeIndexOffset, int textIndexOffset, {int? cueIndexOffset}) =>
      CustomRegex(
          pattern, startTimeIndexOffset, endTimeIndexOffset, textIndexOffset,
          cueIndexOffset: cueIndexOffset);

  @override
  bool operator ==(Object other) {
    if (other is SubtitleObject) {
      for (var i = 0; i < props.length; i++) {
        if (props[i] != other.props[i]) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  @override
  int get hashCode => props.hashCode;

  List<Object> get props => [pattern, type];
}

/// # WebVTT Regex
///
/// This is the web vtt regex. Used in [SubtitleParser] to parsing this subtitle format to
/// dart code.
class VttRegex extends SubtitleRegexObject {
  const VttRegex()
      : super(
          pattern:
              r'(\d+)?\n(\d{1,}:)?(\d{1,2}:)?(\d{1,2}).(\d+)\s?-->\s?(\d{1,}:)?(\d{1,2}:)?(\d{1,2}).(\d+)(.*(?:\r?(?!\r?).*)*)\n(.*(?:\r?\n(?!\r?\n).*)*)',
          type: SubtitleType.vtt,
          cueIndexOffset: 1,
          startTimeIndexOffset: 2,
          endTimeIndexOffset: 6,
          textIndexOffset: 11,
        );
}

/// # SubRip Regex
///
/// This is the subrip regex. Used in [SubtitleParser] to parsing this subtitle format to
/// dart code.
class SrtRegex extends SubtitleRegexObject {
  const SrtRegex()
      : super(
          pattern:
              r'(\d+)?\n(\d{1,}:)?(\d{1,2}:)?(\d{1,2}).(\d+)\s?-->\s?(\d{1,}:)?(\d{1,2}:)?(\d{1,2}).(\d+)(.*(?:\r?(?!\r?).*)*)\n(.*(?:\r?\n(?!\r?\n).*)*)',
          type: SubtitleType.srt,
          cueIndexOffset: 1,
          startTimeIndexOffset: 2,
          endTimeIndexOffset: 6,
          textIndexOffset: 11,
        );
}

/// # Timed Text Markup Language
///
/// This is the **ttml** or **dfxp** regex. Used in [SubtitleParser] to parsing this subtitle format to
/// dart code.
class TtmlRegex extends SubtitleRegexObject {
  const TtmlRegex()
      : super(
          pattern:
              r'<p ([\w:]+="\w+".*)?begin="(\d{1,}:)?(\d{1,}:)?(\d{1,}).(\d{1,})s?" end="(\d{1,}:)?(\d{1,}:)?(\d{1,}).(\d{1,})s?"(\s\w+="\w+".*)?>(\D+)<\/p>',
          type: SubtitleType.ttml,
          startTimeIndexOffset: 2,
          endTimeIndexOffset: 6,
          textIndexOffset: 11,
        );
}

/// # Custom (User defin type)
///
/// This is the user define regex. Used in [SubtitleParser] to parsing this subtitle format to
/// dart code.
class CustomRegex extends SubtitleRegexObject {
  const CustomRegex(String pattern, int startTimeIndexOffset,
      int endTimeIndexOffset, textIndexOffset,
      {int? cueIndexOffset})
      : super(
          pattern: pattern,
          type: SubtitleType.custom,
          cueIndexOffset: cueIndexOffset,
          startTimeIndexOffset: startTimeIndexOffset,
          endTimeIndexOffset: endTimeIndexOffset,
          textIndexOffset: textIndexOffset,
        );
}
