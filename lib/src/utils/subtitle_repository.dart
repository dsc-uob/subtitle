import 'dart:async';
import 'dart:convert';

import 'package:universal_io/io.dart';

import '../core/exceptions.dart';

/// A response class of HTTP request.
class Response {
  /// The status code of response.
  final int statusCode;

  /// Response body as a string.
  final String body;

  /// Response body as a list of bytes.
  final List<int> bodyBytes;

  const Response({
    required this.statusCode,
    required this.body,
    required this.bodyBytes,
  });
}

/// The base class of any subtitle repository. Deals with the platform directly
/// to get or download the required data and submit it to the provider. You can
/// create your custom by inherited this base class.
abstract class ISubtitleRepository {
  const ISubtitleRepository();

  /// Help to fetch subtitle file data from internet.
  Future<String> fetchFromNetwork(Uri url);

  /// Help to fetch subtitle file data from a specific file.
  Future<String> fetchFromFile(File file);

  /// Simple method enable you to create a http GET request.
  Future<Response> get(
    Uri url, {
    Duration? connectionTimeout,
    Map<String, String>? headers,
    bool Function(X509Certificate cert, String host, int port)?
        badCertificateCallback,
  }) async {
    // Create a new HTTP client instance
    final client = HttpClient();

    // Set the options of this HTTP client
    client.connectionTimeout = connectionTimeout;
    client.badCertificateCallback = badCertificateCallback;
    final request = await client.getUrl(url);
    if (headers != null) {
      headers.forEach((name, value) {
        request.headers.add(name, value);
      });
    }

    // Start the HTTP request
    final response = await request.close();

    // Decode the body
    final responseBody = await response.transform(utf8.decoder).join();

    // Close the client
    client.close(force: true);

    // Return a resutl
    return Response(
      statusCode: response.statusCode,
      body: responseBody,
      bodyBytes: responseBody.codeUnits,
    );
  }
}

/// Created to load the subtitles as a string from with value need to use futrue.
/// Deals with the platform directly to get or download the required data and submit
/// it to the provider.
///
/// It will throw an [ErrorInternetFetchingSubtitle] if failed to fetch subtitle or the [successHttpStatus] not matched.
class SubtitleRepository extends ISubtitleRepository {
  const SubtitleRepository._();

  static const SubtitleRepository inctance = SubtitleRepository._();

  /// Load the subtitles from network by provide the file url.
  @override
  Future<String> fetchFromNetwork(
    Uri url, {
    Duration? connectionTimeout,
    Map<String, String>? headers,
    bool Function(X509Certificate cert, String host, int port)?
        badCertificateCallback,
    int successHttpStatus = HttpStatus.ok,
  }) async {
    final response = await get(
      url,
      headers: headers,
      connectionTimeout: connectionTimeout,
      badCertificateCallback: badCertificateCallback,
    );

    if (response.statusCode == successHttpStatus) {
      return response.body;
    }

    throw ErrorInternetFetchingSubtitle(response.statusCode, response.body);
  }

  /// Load the subtitles from specific file.
  @override
  Future<String> fetchFromFile(File file) {
    return file.readAsString();
  }
}
