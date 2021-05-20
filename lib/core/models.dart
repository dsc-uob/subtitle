library subtitle.core;

/// This model class store the subtitle data.
class Subtitle {
  /// Current index of this subtitle in its file.
  /// The **-1** value mean that is no index for this subtitle in its file.
  final int index;

  /// Store the current text for periode that started with [start] and
  /// end with [end].
  final String data;

  /// The start time of this text periode, comparited with video time.
  final Duration start;

  /// The end time of this text periode, comparited with video time.
  final Duration end;

  const Subtitle({
    required this.start,
    required this.end,
    required this.data,
    required this.index,
  });

  bool operator >(Subtitle other) => start > other.start;

  bool operator <(Subtitle other) => start < other.start;

  bool operator <=(Subtitle other) => start <= other.start;

  bool operator >=(Subtitle other) => start >= other.start;

  int compareTo(Subtitle other) =>
      start.inMilliseconds.compareTo(other.start.inMilliseconds);

  @override
  bool operator ==(Object other) {
    if (other is Subtitle) {
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

  List<Object> get props => [start, end, data, index];
}
