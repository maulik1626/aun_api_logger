import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/api_log_model.dart';
import '../storage/local_storage_service.dart';
import '../utils/encode_helper.dart';

/// A drop-in replacement for [http.Client] that logs every request and
/// response into the aun_api_logger SQLite database.
///
/// Usage:
/// ```dart
/// final client = ApiLoggerHttpClient(); // uses http.Client() internally
/// // or wrap your own client:
/// final client = ApiLoggerHttpClient(innerClient: myExistingClient);
///
/// final response = await client.get(Uri.parse('https://example.com/api'));
/// ```
class ApiLoggerHttpClient extends http.BaseClient {
  /// Creates a logging HTTP client.
  ///
  /// [innerClient] defaults to a standard [http.Client] when not provided.
  ApiLoggerHttpClient({http.Client? innerClient})
      : _inner = innerClient ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestTime = DateTime.now().millisecondsSinceEpoch;

    // Capture the request body before sending (BaseRequest is consumed once).
    String requestBody = '';
    if (request is http.Request) {
      requestBody = request.body;
    } else if (request is http.MultipartRequest) {
      requestBody = _encodeMultipart(request);
    }

    // Insert a pending log entry.
    int? logId;
    try {
      final log = ApiLogModel(
        method: request.method,
        url: request.url.toString(),
        endpoint: request.url.path,
        requestHeaders: tryEncodeJson(request.headers),
        requestBody: requestBody,
        requestTime: requestTime,
      );
      logId = await LocalStorageService.instance.insertLog(log);
    } catch (_) {
      // Never block the actual request if logging fails.
    }

    try {
      final streamedResponse = await _inner.send(request);

      // Read the streamed response so we can log the body,
      // then re-wrap it into a new StreamedResponse for the caller.
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = _tryDecodeBytes(responseBytes);

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - requestTime;

      if (logId != null) {
        try {
          final log = ApiLogModel(
            id: logId,
            method: request.method,
            url: request.url.toString(),
            endpoint: request.url.path,
            requestHeaders: tryEncodeJson(request.headers),
            requestBody: requestBody,
            statusCode: streamedResponse.statusCode,
            responseHeaders: tryEncodeJson(streamedResponse.headers),
            responseBody: responseBody,
            requestTime: requestTime,
            durationMs: duration,
          );
          await LocalStorageService.instance.updateLog(log);
        } catch (_) {
          // Ignore logging errors.
        }
      }

      // Return a new StreamedResponse with the already-consumed bytes.
      return http.StreamedResponse(
        http.ByteStream.fromBytes(responseBytes),
        streamedResponse.statusCode,
        contentLength: streamedResponse.contentLength,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (error) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - requestTime;

      if (logId != null) {
        try {
          final log = ApiLogModel(
            id: logId,
            method: request.method,
            url: request.url.toString(),
            endpoint: request.url.path,
            requestHeaders: tryEncodeJson(request.headers),
            requestBody: requestBody,
            statusCode: 0,
            responseBody: error.toString(),
            requestTime: requestTime,
            durationMs: duration,
          );
          await LocalStorageService.instance.updateLog(log);
        } catch (_) {
          // Ignore logging errors.
        }
      }
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  /// Encodes multipart request fields and file metadata into a readable string.
  String _encodeMultipart(http.MultipartRequest request) {
    final map = <String, dynamic>{};
    if (request.fields.isNotEmpty) {
      map['fields'] = request.fields;
    }
    if (request.files.isNotEmpty) {
      map['files'] = request.files
          .map(
            (f) =>
                '${f.field}: File(${f.filename}, ${f.contentType}, ${f.length} bytes)',
          )
          .toList();
    }
    return tryEncodeJson(map);
  }

  /// Attempts to decode raw bytes into a UTF-8 string.
  String _tryDecodeBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return '<binary response: ${bytes.length} bytes>';
    }
  }
}
