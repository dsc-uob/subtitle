import 'dart:async';
import 'dart:developer' as dev;

import 'package:meta/meta.dart';

import '../core/exceptions.dart';
import '../core/models.dart';
import 'subtitle_parser.dart';
import 'subtitle_provider.dart';

void _log(String msg, {int level = 800}) {
  dev.log(msg, name: 'subtitle', level: level);
}

/// The base class of all subtitles controller object.
abstract class ISubtitleController {
  //! Final fields
  /// Store the subtitle provider.
  final SubtitleProvider _provider;

  /// Store the subtitles objects after decoded.
  final List<Subtitle> subtitles;

  /// `_prefixMaxEndMs[i]` = max end (ms) across `subtitles[0..i]`. Lets
  /// `multiDurationSearch` cut its backward walk short — without it,
  /// one long banner cue forces a full O(n) scan even with binary
  /// search to find the rightmost candidate.
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

  /// Collapses pathological cue patterns that some upstream subtitle
  /// services produce — most notably karaoke-style word-by-word VTTs
  /// where every line is repeated as the full sentence plus one cue
  /// per word, all sharing the same `start`/`end`. Left as-is, those
  /// files balloon to 10k+ cues and force every position-tick search
  /// to do a long linear scan, which then shows up as UI jank during
  /// playback.
  ///
  /// Two passes:
  ///
  ///   1. Within a run of cues sharing identical `(start, end)`, keep
  ///      only the cue with the longest text. The full sentence wins
  ///      over its word fragments and the joined-text rendering stops
  ///      duplicating itself across overlapping cues.
  ///   2. Coalesce consecutive cues that carry the same text and are
  ///      contiguous (or near-contiguous, ≤50ms gap). Karaoke files
  ///      tend to repeat the same sentence across dozens of tiny
  ///      slices; the merged cue is functionally identical for any
  ///      consumer that just reads `data` at the current position.
  ///
  /// Both passes are conservative: legitimate non-overlapping cues
  /// with distinct text are untouched.
  void _cleanupDuplicates() {
    final n = subtitles.length;
    if (n < 2) return;

    final originalCount = n;

    // Pass 1: same start+end → keep longest text only.
    final dedupedByRange = <Subtitle>[];
    var i = 0;
    while (i < subtitles.length) {
      var j = i;
      var bestIdx = i;
      var bestLen = subtitles[i].data.length;
      while (j + 1 < subtitles.length &&
          subtitles[j + 1].start == subtitles[i].start &&
          subtitles[j + 1].end == subtitles[i].end) {
        j++;
        if (subtitles[j].data.length > bestLen) {
          bestLen = subtitles[j].data.length;
          bestIdx = j;
        }
      }
      dedupedByRange.add(subtitles[bestIdx]);
      i = j + 1;
    }

    // Pass 2: merge contiguous identical-text cues.
    const mergeGap = Duration(milliseconds: 50);
    final merged = <Subtitle>[];
    for (final cue in dedupedByRange) {
      if (merged.isNotEmpty &&
          merged.last.data == cue.data &&
          cue.start - merged.last.end <= mergeGap) {
        final prev = merged.last;
        merged[merged.length - 1] = Subtitle(
          index: prev.index,
          start: prev.start,
          end: cue.end > prev.end ? cue.end : prev.end,
          data: prev.data,
        );
      } else {
        merged.add(cue);
      }
    }

    if (merged.length < originalCount) {
      subtitles
        ..clear()
        ..addAll(merged);
      _log('cleanup: $originalCount -> ${merged.length} cues '
          '(${originalCount - merged.length} removed)');
    }
  }

  /// Builds the prefix max-end array used by [multiDurationSearch] to
  /// terminate its backward walk safely.
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

  /// Returns every cue whose `[start, end]` range covers `duration`.
  ///
  /// Implementation: bisects to the rightmost cue whose `start <=
  /// duration` (cues are sorted by start in [ISubtitleController.sort])
  /// and walks backward, collecting any cue still in range. The walk
  /// stops as soon as `_prefixMaxEndMs[i] < duration` — once no cue in
  /// the prefix can still be active, no earlier cue can match either.
  ///
  /// O(log n + k) where k is the number of cues actually overlapping
  /// the query time. The previous implementation scanned every cue on
  /// every call, which became a UI-thread bottleneck on large karaoke
  /// VTTs (10k+ cues, position events firing several times per second).
  @override
  List<Subtitle> multiDurationSearch(Duration duration) {
    final n = subtitles.length;
    if (n == 0) return const [];
    final tMs = duration.inMilliseconds;

    // upper_bound by start: rightmost index where start <= tMs.
    var lo = 0;
    var hi = n;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (subtitles[mid].start.inMilliseconds <= tMs) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final rightmost = lo - 1;
    if (rightmost < 0) return const [];

    final hits = <Subtitle>[];
    for (var i = rightmost; i >= 0; i--) {
      if (_prefixMaxEndMs[i] < tMs) break;
      final cue = subtitles[i];
      if (cue.start.inMilliseconds <= tMs && cue.end.inMilliseconds >= tMs) {
        hits.add(cue);
      }
    }
    if (hits.length > 1) {
      return hits.reversed.toList(growable: false);
    }
    return hits;
  }
}
