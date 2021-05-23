import 'dart:async';

import 'package:path/path.dart' show extension;
import 'package:universal_io/io.dart';

import '../core/exceptions.dart';
import '../utils/types.dart';
import 'subtitle_repository.dart';

/// Base class of subtitle providers. It was created to
/// simplify fetching subtitle file data from multiple sources.
abstract class SubtitleProvider {
  /// Store the supported subtitle file format extensions.
  static const List<String> supported_extensions = [
    '.vtt',
    '.srt',
    '.sbv',
    '.ssa',
    '.ass',
    '.ttml',
    '.dfxp',
    '.xml',
  ];

  const SubtitleProvider();

  /// ## Network subtitles
  /// A class that deals with subtitle files from the **Internet**, you can provide a download
  /// link of subtitle in the constructor function for the purpose of completing its processing.
  /// You can call it by [NetworkSubtitle] class or by factory constructor in [SubtitleProvider.fromNetwork].
  ///
  /// ```dart
  ///
  ///   // Using  [NetworkSubtitle] class.
  ///   NetworkSubtitle netSub = new NetworkSubtitle(Uri.parse('<YOUR SUBTITLE PATH URL>'));
  ///
  ///   // Using factory constructor.
  ///   SubtitleProvider netSub = SubtitleProvider.fromNetwork(Uri.parse('<YOUR SUBTITLE PATH URL>'));
  ///
  /// ```
  factory SubtitleProvider.fromNetwork(
    Uri url, {
    SubtitleType? type,
  }) =>
      NetworkSubtitle(url, type: type);

  /// ## File subtitles
  /// A class that deals with local files subtitle on the device. You can provide the file
  ///  in the constructor function for the purpose of completing its processing.
  /// You can call it by [FileSubtitle] class or by factory constructor in [SubtitleProvider.fromFile].
  ///
  /// ```dart
  ///
  ///   // Using  [FileSubtitle] class.
  ///   FileSubtitle fileSub = new FileSubtitle(myFile);
  ///
  ///   // Using factory constructor.
  ///   SubtitleProvider fileSub = SubtitleProvider.fromFile(myFile);
  ///
  /// ```
  factory SubtitleProvider.fromFile(
    File file, {
    SubtitleType? type,
  }) =>
      FileSubtitle(file, type: type);

  /// Use this provider for string to generate a subtitles. You should provide the **current format**
  /// type of this subtitle. for example:
  /// ```dart
  ///
  /// String subtitleData = """
  ///   WEBVTT
  ///
  ///   00:01.000 --> 00:04.000
  ///   - Never drink liquid nitrogen.
  ///
  ///   00:05.000 --> 00:09.000
  ///   - It will perforate your stomach.
  ///   - You could die.
  ///""";
  ///
  ///
  ///   // Using  [StringSubtitle] class.
  ///   StringSubtitle fileSub = new StringSubtitle(
  ///     data: subtitleData,
  ///     type: SubtitleType.vtt,
  ///   );
  ///
  ///   // Using factory constructor.
  ///   SubtitleProvider fileSub = SubtitleProvider.fromString(
  ///     data: subtitleData,
  ///     type: SubtitleType.vtt,
  ///    );
  ///
  /// ```
  factory SubtitleProvider.fromString({
    required String data,
    required SubtitleType type,
  }) =>
      StringSubtitle(
        data: data,
        type: type,
      );

  /// Abstract method return an instance of [SubtitleObject].
  Future<SubtitleObject> getSubtitle();

  /// Return the current [SubtitleType] depended on file extension.
  SubtitleType getSubtitleType(String ext) {
    switch (ext) {
      case '.vtt':
        return SubtitleType.vtt;
      case '.srt':
        return SubtitleType.srt;
      case '.sbv':
        return SubtitleType.sbv;
      case '.ssa':
      case '.ass':
        return SubtitleType.ssa;
      case '.ttml':
      case '.xml':
        return SubtitleType.ttml;
      case 'dfxp':
        return SubtitleType.dfxp;
      default:
        throw UnsupportedSubtitleFormat();
    }
  }
}

/// ## Network subtitles
/// A class that deals with subtitle files from the **Internet**, you can provide a download
/// link of subtitle in the constructor function for the purpose of completing its processing.
/// You can call it by [NetworkSubtitle] class or by factory constructor in [SubtitleProvider.fromNetwork].
///
/// ```dart
///
///   // Using  [NetworkSubtitle] class.
///   NetworkSubtitle netSub = new NetworkSubtitle(Uri.parse('<YOUR SUBTITLE PATH URL>'));
///
///   // Using factory constructor.
///   SubtitleProvider netSub = SubtitleProvider.fromNetwork(Uri.parse('<YOUR SUBTITLE PATH URL>'));
///
/// ```
class NetworkSubtitle extends SubtitleProvider {
  /// The url of subtitle file on the internet.
  final Uri url;
  final SubtitleType? type;

  const NetworkSubtitle(
    this.url, {
    this.type,
  });

  @override
  Future<SubtitleObject> getSubtitle() async {
    // Preparing subtitle file data.
    final _repository = SubtitleRepository.inctance;
    final data = await _repository.fetchFromNetwork(url);

    // Find the current format type of subtitle.
    final ext = extension(url.path);
    final type = this.type ?? getSubtitleType(ext);

    return SubtitleObject(data: data, type: type);
  }
}

/// ## File subtitles
/// A class that deals with local files subtitle on the device. You can provide the file
///  in the constructor function for the purpose of completing its processing.
/// You can call it by [FileSubtitle] class or by factory constructor in [SubtitleProvider.fromFile].
///
/// ```dart
///
///   // Using  [FileSubtitle] class.
///   FileSubtitle fileSub = new FileSubtitle(myFile);
///
///   // Using factory constructor.
///   SubtitleProvider fileSub = SubtitleProvider.fromFile(myFile);
///
/// ```
class FileSubtitle extends SubtitleProvider {
  /// The current file that having subtitle data.
  final File file;
  final SubtitleType? type;

  const FileSubtitle(
    this.file, {
    this.type,
  });

  @override
  Future<SubtitleObject> getSubtitle() async {
    // Preparing subtitle file data.
    final _repository = SubtitleRepository.inctance;
    final data = await _repository.fetchFromFile(file);

    // Find the current format type of subtitle.
    final ext = extension(file.path);
    final type = this.type ?? getSubtitleType(ext);

    return SubtitleObject(data: data, type: type);
  }
}

/// Use this provider for string to generate a subtitles. You should provide the **current format**
/// type of this subtitle. for example:
/// ```dart
///
/// String subtitleData = """
///   WEBVTT
///
///   00:01.000 --> 00:04.000
///   - Never drink liquid nitrogen.
///
///   00:05.000 --> 00:09.000
///   - It will perforate your stomach.
///   - You could die.
///""";
///
///
///   // Using  [StringSubtitle] class.
///   StringSubtitle fileSub = new StringSubtitle(
///     data: subtitleData,
///     type: SubtitleType.vtt,
///   );
///
///   // Using factory constructor.
///   SubtitleProvider fileSub = SubtitleProvider.fromString(
///     data: subtitleData,
///     type: SubtitleType.vtt,
///    );
///
/// ```
class StringSubtitle extends SubtitleProvider {
  final String data;
  final SubtitleType type;

  const StringSubtitle({
    required this.data,
    required this.type,
  });

  @override
  Future<SubtitleObject> getSubtitle() async =>
      SubtitleObject(data: data, type: type);
}
