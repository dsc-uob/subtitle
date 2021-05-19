import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../core/exceptions.dart';

abstract class ISubtitleRepository {
  const ISubtitleRepository();

  Future<String> fetchFromNetwork(Uri url);
  Future<String> fetchFromFile(File file);
}

///! The user have not to use this class.
/// Created to load the subtitles as a string from with value need to use futrue.
class SubtitleRepository extends ISubtitleRepository {
  const SubtitleRepository._();

  static const SubtitleRepository inctance = SubtitleRepository._();

  /// Load the subtitles from network by provide the file url.
  @override
  Future<String> fetchFromNetwork(Uri url) async {
    final response = await get(url);
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    }

    throw ErrorInternetFetchingSubtitle(response.statusCode, response.body);
  }

  /// Load the subtitles from specific file.
  @override
  Future<String> fetchFromFile(File file) {
    return file.readAsString();
  }
}
