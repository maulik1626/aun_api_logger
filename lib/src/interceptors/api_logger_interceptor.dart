import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/api_log_model.dart';
import '../storage/local_storage_service.dart';

class ApiLoggerInterceptor extends Interceptor {
  // We use extra map to pass the generated log ID between Request, Response, Error.
  static const String _logIdKey = 'aun_api_log_id';
  static const String _startTimeKey = 'aun_api_start_time';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requestTime = DateTime.now().millisecondsSinceEpoch;
    options.extra[_startTimeKey] = requestTime;

    final log = ApiLogModel(
      method: options.method,
      url: options.uri.toString(),
      endpoint: options.uri.path,
      requestHeaders: _tryEncode(options.headers),
      requestBody: _tryEncode(options.data),
      requestTime: requestTime,
    );

    try {
      final id = await LocalStorageService.instance.insertLog(log);
      options.extra[_logIdKey] = id;
    } catch (e) {
      // Ignore db errors to ensure requests still go through
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final logId = response.requestOptions.extra[_logIdKey] as int?;
    final startTime = response.requestOptions.extra[_startTimeKey] as int?;

    if (logId != null && startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;

      final log = ApiLogModel(
        id: logId,
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        endpoint: response.requestOptions.uri.path,
        requestHeaders: _tryEncode(response.requestOptions.headers),
        requestBody: _tryEncode(response.requestOptions.data),
        statusCode: response.statusCode,
        responseHeaders: _tryEncode(response.headers.map),
        responseBody: _tryEncode(response.data),
        requestTime: startTime,
        durationMs: duration,
      );

      try {
        await LocalStorageService.instance.updateLog(log);
      } catch (e) {
        // Ignore
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final logId = err.requestOptions.extra[_logIdKey] as int?;
    final startTime = err.requestOptions.extra[_startTimeKey] as int?;

    if (logId != null && startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;

      final log = ApiLogModel(
        id: logId,
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        endpoint: err.requestOptions.uri.path,
        requestHeaders: _tryEncode(err.requestOptions.headers),
        requestBody: _tryEncode(err.requestOptions.data),
        statusCode: err.response?.statusCode ?? 0,
        responseHeaders: _tryEncode(err.response?.headers.map),
        responseBody: _tryEncode(err.response?.data ?? err.message),
        requestTime: startTime,
        durationMs: duration,
      );

      try {
        await LocalStorageService.instance.updateLog(log);
      } catch (e) {
        // Ignore
      }
    }

    super.onError(err, handler);
  }

  String _tryEncode(dynamic data) {
    if (data == null) return '';
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
