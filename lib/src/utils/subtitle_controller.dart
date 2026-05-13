import 'dart:async';

import 'package:meta/meta.dart';

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

  /// `_prefixMaxEndMs[i]` = max end (ms) across `subtitles[0..i]`. Used by
  /// [multiDurationSearch] to terminate its backward walk early without
  /// scanning all cues.
  List<int> _prefixMaxEndMs = const [];

  //! Later and Nullable fields
  /// The parser class, maybe still null if you are not initial the controller.
  ISubtitleParser? _parser;

  // For detect if controller disposed.
  late bool _isDisposed;

  ISubtitleController({
    required SubtitleProvider provider,
  })  : _provider = provider,
        subtitles = List.empty(growable: true) {
    _isDisposed = false;
  }

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
  @mustCallSuper
  Future<void> initial() async {
    if (_isDisposed) {
      throw ControllerDisposedException();
    }
    if (initialized) return;
    final providerObject = await _provider.getSubtitle();
    _parser = SubtitleParser(providerObject);
    subtitles.addAll(_parser!.parsing());
    sort();
    _cleanupDuplicates();
    _buildPrefixMaxEnd();
  }

  @mustCallSuper
  Future<void> dispose() async {
    subtitles.clear();
    _prefixMaxEndMs = const [];
    _parser = null;
    _isDisposed = true;
  }

  /// Sort all subtitles object from smaller duration to larger duration.
  void sort() => subtitles.sort((s1, s2) => s1.compareTo(s2));

  /// Collapses pathological cue patterns produced by karaoke-style VTTs
  /// where every word is emitted as a separate cue sharing the same
  /// `(start, end)` as the full-sentence cue.
  ///
  /// Two passes:
  ///   1. Within a run of cues sharing identical `(start, end)`, keep only
  ///      the cue with the longest text.
  ///   2. Coalesce consecutive cues with identical text whose gap is ≤ 50 ms.
  ///
  /// Legitimate, non-overlapping cues with distinct text are untouched.
  void _cleanupDuplicates() {
    if (subtitles.length < 2) return;

    final originalCount = subtitles.length;

    // Pass 1: same start+end → keep the cue with the longest text.
    final dedupedByRange = <Subtitle>[];
    var i = 0;
    while (i < subtitles.length) {
      var bestIdx = i;
      var bestLen = subtitles[i].data.length;
      var j = i + 1;
      while (j < subtitles.length &&
          subtitles[j].start == subtitles[i].start &&
          subtitles[j].end == subtitles[i].end) {
        if (subtitles[j].data.length > bestLen) {
          bestLen = subtitles[j].data.length;
          bestIdx = j;
        }
        j++;
      }
      dedupedByRange.add(subtitles[bestIdx]);
      i = j;
    }

    // Pass 2: merge contiguous cues with identical text (gap ≤ 50 ms).
    const mergeGap = Duration(milliseconds: 50);
    final merged = <Subtitle>[];
    for (final cue in dedupedByRange) {
      if (merged.isNotEmpty &&
          merged.last.data == cue.data &&
          cue.start - merged.last.end <= mergeGap) {
        final prev = merged.last;
        merged[merged.length - 1] = prev.copyWith(
          end: cue.end > prev.end ? cue.end : prev.end,
        );
      } else {
        merged.add(cue);
      }
    }

    if (merged.length < originalCount) {
      subtitles
        ..clear()
        ..addAll(merged);
    }
  }

  /// Builds the prefix max-end array used by [multiDurationSearch] to
  /// terminate its backward walk early.
  void _buildPrefixMaxEnd() {
    final n = subtitles.length;
    if (n == 0) {
      _prefixMaxEndMs = const [];
      return;
    }
    final arr = List<int>.filled(n, 0);
    var running = 0;
    for (var i = 0; i < n; i++) {
      final endMs = subtitles[i].end.inMilliseconds;
      if (endMs > running) running = endMs;
      arr[i] = running;
    }
    _prefixMaxEndMs = arr;
  }

  /// Get all subtitles as a single string, you can separate between subtitles
  /// using `separator`, the default is `, `.
  String getAll([String separator = ', ']) => subtitles.join(separator);
}

/// The default class to controller subtitles, you can use it or extends
/// [ISubtitleController] to create your custom.
class SubtitleController extends ISubtitleController {
  SubtitleController({
    required super.provider,
  });

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

  /// Returns every cue active at [duration] in O(log n + k) time, where k is
  /// the number of matches.
  ///
  /// Strategy:
  ///   1. Use an upper-bound binary search to locate the first cue whose
  ///      `start` is strictly greater than [duration].  All cues at or before
  ///      that index are candidates (their start ≤ duration).
  ///   2. Walk backwards from that index collecting cues where `inRange` is
  ///      true.  The precomputed `_prefixMaxEndMs` array lets us stop as soon
  ///      as the maximum end time seen so far is before [duration], meaning
  ///      no remaining cue can possibly be active.
  @override
  List<Subtitle> multiDurationSearch(Duration duration) {
    if (subtitles.isEmpty) return const [];

    final durationMs = duration.inMilliseconds;

    // Upper-bound binary search: find the first index where start > duration.
    var lo = 0;
    var hi = subtitles.length; // exclusive upper bound
    while (lo < hi) {
      final mid = lo + (hi - lo) ~/ 2;
      if (subtitles[mid].start <= duration) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // All cues in [0, lo) have start ≤ duration; start from lo-1.
    var idx = lo - 1;

    final result = <Subtitle>[];
    while (idx >= 0) {
      // Early termination: if the max end time in [0..idx] is before duration,
      // no cue in this prefix can be active.
      if (_prefixMaxEndMs[idx] < durationMs) break;

      if (subtitles[idx].inRange(duration)) {
        result.add(subtitles[idx]);
      }
      idx--;
    }

    // Reverse so results are in chronological order.
    return result.reversed.toList();
  }
}
