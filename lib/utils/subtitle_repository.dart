library subtitle.util;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../core/exceptions.dart';

/// The base class of any subtitle repository. Deals with the platform directly
/// to get or download the required data and submit it to the provider. You can
/// create your custom by inherited this base class.
abstract class ISubtitleRepository {
  const ISubtitleRepository();

  /// Help to fetch subtitle file data from internet.
  Future<String> fetchFromNetwork(Uri url);

  /// Help to fetch subtitle file data from a specific file.
  Future<String> fetchFromFile(File file);
}

/// Created to load the subtitles as a string from with value need to use futrue.
/// Deals with the platform directly to get or download the required data and submit
/// it to the provider.
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
