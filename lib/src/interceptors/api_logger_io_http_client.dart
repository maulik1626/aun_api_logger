import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/api_log_model.dart';
import '../storage/local_storage_service.dart';
import '../utils/encode_helper.dart';

/// A wrapper around [HttpClient] (from `dart:io`) that logs every request
/// and response into the aun_api_logger SQLite database.
///
/// Usage:
/// ```dart
/// final client = ApiLoggerIoHttpClient(); // wraps a new HttpClient()
/// // or wrap your own:
/// final client = ApiLoggerIoHttpClient(innerClient: myHttpClient);
///
/// final request = await client.getUrl(Uri.parse('https://example.com/api'));
/// final response = await request.close();
/// ```
///
/// All [HttpClient] methods and properties are delegated to the inner client.
/// Only the request lifecycle is intercepted for logging.
class ApiLoggerIoHttpClient implements HttpClient {
  /// Creates a logging [HttpClient] wrapper.
  ///
  /// [innerClient] defaults to a new [HttpClient] when not provided.
  ApiLoggerIoHttpClient({HttpClient? innerClient})
      : _inner = innerClient ?? HttpClient();

  final HttpClient _inner;

  // ---------------------------------------------------------------------------
  // Core interception — all convenience methods eventually call openUrl.
  // ---------------------------------------------------------------------------

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return _LoggingRequest(request, method, url);
  }

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    return openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  }

  // ---------------------------------------------------------------------------
  // Convenience methods — delegate through openUrl for interception.
  // ---------------------------------------------------------------------------

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  // ---------------------------------------------------------------------------
  // Delegated properties
  // ---------------------------------------------------------------------------

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) =>
      _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) =>
      _inner.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(
      String host,
      int port,
      String scheme,
      String? realm,
    )? f,
  ) =>
      _inner.authenticateProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) =>
      _inner.badCertificateCallback = callback;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )? f,
  ) =>
      _inner.connectionFactory = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

// =============================================================================
// Private: Logging request wrapper
// =============================================================================

/// Wraps an [HttpClientRequest] to intercept [close] and log the full
/// request → response cycle.
class _LoggingRequest implements HttpClientRequest {
  _LoggingRequest(this._inner, this._method, this._url);

  final HttpClientRequest _inner;
  final String _method;
  final Uri _url;
  final List<List<int>> _bodyChunks = [];

  @override
  Future<HttpClientResponse> close() async {
    final requestTime = DateTime.now().millisecondsSinceEpoch;

    // Capture request headers.
    final reqHeaders = <String, String>{};
    _inner.headers.forEach((name, values) {
      reqHeaders[name] = values.join(', ');
    });

    final requestBody = _tryDecodeChunks(_bodyChunks);

    // Insert pending log.
    int? logId;
    try {
      final log = ApiLogModel(
        method: _method,
        url: _url.toString(),
        endpoint: _url.path,
        requestHeaders: tryEncodeJson(reqHeaders),
        requestBody: requestBody,
        requestTime: requestTime,
      );
      logId = await LocalStorageService.instance.insertLog(log);
    } catch (_) {
      // Never block the request.
    }

    try {
      final response = await _inner.close();

      // Read the response body.
      final responseBytes = await _collectResponseBytes(response);
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - requestTime;

      // Capture response headers.
      final resHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        resHeaders[name] = values.join(', ');
      });

      if (logId != null) {
        try {
          final log = ApiLogModel(
            id: logId,
            method: _method,
            url: _url.toString(),
            endpoint: _url.path,
            requestHeaders: tryEncodeJson(reqHeaders),
            requestBody: requestBody,
            statusCode: response.statusCode,
            responseHeaders: tryEncodeJson(resHeaders),
            responseBody: _tryDecodeBytes(responseBytes),
            requestTime: requestTime,
            durationMs: duration,
          );
          await LocalStorageService.instance.updateLog(log);
        } catch (_) {
          // Ignore.
        }
      }

      // Return a replay stream so the caller can still read the body.
      return _ReplayHttpClientResponse(response, responseBytes);
    } catch (error) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - requestTime;

      if (logId != null) {
        try {
          final log = ApiLogModel(
            id: logId,
            method: _method,
            url: _url.toString(),
            endpoint: _url.path,
            requestHeaders: tryEncodeJson(reqHeaders),
            requestBody: requestBody,
            statusCode: 0,
            responseBody: error.toString(),
            requestTime: requestTime,
            durationMs: duration,
          );
          await LocalStorageService.instance.updateLog(log);
        } catch (_) {
          // Ignore.
        }
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Body capture — intercept add/write to record the outgoing body.
  // ---------------------------------------------------------------------------

  @override
  void add(List<int> data) {
    _bodyChunks.add(data);
    _inner.add(data);
  }

  @override
  void write(Object? object) {
    final str = object.toString();
    _bodyChunks.add(utf8.encode(str));
    _inner.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    final str = objects.join(separator);
    _bodyChunks.add(utf8.encode(str));
    _inner.writeAll(objects, separator);
  }

  @override
  void writeln([Object? object = '']) {
    final str = '$object\n';
    _bodyChunks.add(utf8.encode(str));
    _inner.writeln(object);
  }

  @override
  void writeCharCode(int charCode) {
    _bodyChunks.add([charCode]);
    _inner.writeCharCode(charCode);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    // We must tee the stream to record body chunks.
    final controller = StreamController<List<int>>();
    stream.listen(
      (data) {
        _bodyChunks.add(data);
        controller.add(data);
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    return _inner.addStream(controller.stream);
  }

  // ---------------------------------------------------------------------------
  // Delegated members
  // ---------------------------------------------------------------------------

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Uri get uri => _inner.uri;

  @override
  String get method => _inner.method;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _inner.addError(error, stackTrace);
  }

  @override
  Future<HttpClientResponse> get done => _inner.done;

  @override
  Future flush() => _inner.flush();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _tryDecodeChunks(List<List<int>> chunks) {
    if (chunks.isEmpty) return '';
    try {
      final allBytes = chunks.expand((c) => c).toList();
      return utf8.decode(allBytes);
    } catch (_) {
      final totalBytes = chunks.fold<int>(0, (sum, c) => sum + c.length);
      return '<binary body: $totalBytes bytes>';
    }
  }

  static String _tryDecodeBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return '<binary response: ${bytes.length} bytes>';
    }
  }

  static Future<List<int>> _collectResponseBytes(
    HttpClientResponse response,
  ) async {
    final chunks = <List<int>>[];
    await for (final chunk in response) {
      chunks.add(chunk);
    }
    return chunks.expand((c) => c).toList();
  }
}

// =============================================================================
// Private: Replay response wrapper
// =============================================================================

/// Wraps an [HttpClientResponse] so the caller can still iterate over the
/// body bytes even though we already consumed the stream for logging.
class _ReplayHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ReplayHttpClientResponse(this._original, this._bytes);

  final HttpClientResponse _original;
  final List<int> _bytes;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // Delegate everything else to the original response.

  @override
  int get statusCode => _original.statusCode;

  @override
  String get reasonPhrase => _original.reasonPhrase;

  @override
  int get contentLength => _original.contentLength;

  @override
  HttpHeaders get headers => _original.headers;

  @override
  List<Cookie> get cookies => _original.cookies;

  @override
  X509Certificate? get certificate => _original.certificate;

  @override
  HttpConnectionInfo? get connectionInfo => _original.connectionInfo;

  @override
  bool get isRedirect => _original.isRedirect;

  @override
  bool get persistentConnection => _original.persistentConnection;

  @override
  List<RedirectInfo> get redirects => _original.redirects;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      _original.redirect(method, url, followLoops);

  @override
  Future<Socket> detachSocket() => _original.detachSocket();

  @override
  HttpClientResponseCompressionState get compressionState =>
      _original.compressionState;
}
