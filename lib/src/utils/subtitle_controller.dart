import 'dart:async';

import '../core/exceptions.dart';
import '../core/models.dart';
import 'subtitle_parser.dart';
import 'subtitle_provider.dart';

/// The base class of all subtitles controller object.
abstract class ISubtitleController {
  //! Final fields
  /// Store the subtitle provider.
  final SubtitleProvider _provider;

  /// Store the subtitles objects after decoded.
  final List<Subtitle> subtitles;

  //! Later and Nullable fields
  /// The parser class, maybe still null if you are not initial the controller.
  ISubtitleParser? _parser;

  ISubtitleController({
    required SubtitleProvider provider,
  })  : _provider = provider,
        subtitles = List.empty(growable: true);

  //! Getters

  /// Get the parser class
  ISubtitleParser get parser {
    if (initialized) return _parser!;
    throw NotInitializedException();
  }

  /// Return the current subtitle provider
  SubtitleProvider get provider => _provider;

  /// Check it the controller is initial or not.
  bool get initialized => _parser != null;

  //! Abstract methods
  /// Use this method to customize your search algorithm.
  Subtitle? durationSearch(Duration duration);

  /// To get one or more subtitles in same duration range.
  List<Subtitle> multiDurationSearch(Duration duration);

  //! Virual methods
  Future<void> initial() async {
    if (initialized) return;
    final providerObject = await _provider.getSubtitle();
    _parser = SubtitleParser(providerObject);
    subtitles.addAll(_parser!.parsing());
    sort();
  }

  /// Sort all subtitles object from smaller duration to larger duration.
  void sort() => subtitles.sort((s1, s2) => s1.compareTo(s2));

  /// Get all subtitles as a single string, you can separate between subtitles
  /// using `separator`, the default is `, `.
  String getAll([String separator = ', ']) => subtitles.join(separator);
}

/// The default class to controller subtitles, you can use it or extends
/// [ISubtitleController] to create your custom.
class SubtitleController extends ISubtitleController {
  SubtitleController({
    required SubtitleProvider provider,
  }) : super(provider: provider);

  /// Fetch your current single subtitle value by providing the duration.
  @override
  Subtitle? durationSearch(Duration duration) {
    if (!initialized) throw NotInitializedException();

    final l = 0;
    final r = subtitles.length - 1;

    var index = _binarySearch(l, r, duration);

    if (index > -1) {
      return subtitles[index];
    }

    return null;
  }

  /// Perform binary search when search about subtitle by duration.
  int _binarySearch(int l, int r, Duration duration) {
    if (r >= l) {
      var mid = l + (r - l) ~/ 2;

      if (subtitles[mid].inRange(duration)) return mid;

      // If element is smaller than mid, then
      // it can only be present in left subarray
      if (subtitles[mid].isLarg(duration)) {
        return _binarySearch(mid + 1, r, duration);
      }

      // Else the element can only be present
      // in right subarray
      return _binarySearch(l, mid - 1, duration);
    }

    // We reach here when element is not present
    // in array
    return -1;
  }

  @override
  List<Subtitle> multiDurationSearch(Duration duration) {
    var correctSubtitles = List<Subtitle>.empty(growable: true);

    for (var value in subtitles) {
      if (value.inRange(duration)) correctSubtitles.add(value);
    }

    return correctSubtitles;
  }
}
