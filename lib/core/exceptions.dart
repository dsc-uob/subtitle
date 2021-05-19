library subtitle.core;

class ErrorInternetFetchingSubtitle implements Exception {
  final int? code;
  final String? message;

  const ErrorInternetFetchingSubtitle(this.code, this.message);
}

class UnsupportedSubtitleFormat implements Exception {}
