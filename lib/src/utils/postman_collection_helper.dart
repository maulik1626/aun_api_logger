import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api_log_model.dart';

/// Builds a Postman Collection v2.1 document from a single [ApiLogModel] for
/// Import → Collection in Postman.
class PostmanCollectionHelper {
  PostmanCollectionHelper._();

  static const _schema =
      'https://schema.getpostman.com/json/collection/v2.1.0/collection.json';

  /// Produces the collection object (suitable for JSON encoding).
  static Map<String, dynamic> buildCollectionMap(
    ApiLogModel log, {
    required String displayEndpoint,
  }) {
    final method = log.method.toUpperCase();
    final itemName = _itemName(method, displayEndpoint);
    final headers = _parseHeadersToPostmanList(log.requestHeaders);
    final headerKeyLower = <String, String>{
      for (final h in headers)
        (h['key']! as String).toLowerCase(): h['value']! as String,
    };

    final request = <String, dynamic>{
      'method': method,
      'header': headers,
      'url': _buildUrlObject(log.url, log.endpoint),
    };

    final body = log.requestBody;
    if (_methodMayHaveBody(method) && body != null && body.trim().isNotEmpty) {
      request['body'] = <String, dynamic>{
        'mode': 'raw',
        'raw': body,
        'options': <String, dynamic>{
          'raw': <String, dynamic>{
            'language': _rawBodyLanguage(headerKeyLower, body),
          },
        },
      };
    }

    return <String, dynamic>{
      'info': <String, dynamic>{
        'name': 'AUN API Log — $itemName',
        'schema': _schema,
        '_exporter_id': 'aun_api_logger',
      },
      'item': <Map<String, dynamic>>[
        <String, dynamic>{'name': itemName, 'request': request},
      ],
    };
  }

  /// Writes a formatted JSON collection file under the app temp directory.
  static Future<File> writeShareCollectionJsonFile({
    required ApiLogModel log,
    required String displayEndpoint,
  }) async {
    final map = buildCollectionMap(log, displayEndpoint: displayEndpoint);
    final jsonString = const JsonEncoder.withIndent('  ').convert(map);

    final timeStr = DateFormat(
      'hh-mm-ss_a',
    ).format(DateTime.fromMillisecondsSinceEpoch(log.requestTime));
    final endpointSlug = displayEndpoint
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fileName = '${log.method}_postman_${endpointSlug}_$timeStr.json';

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);
    return file;
  }

  static String _itemName(String method, String displayEndpoint) {
    final trimmed = displayEndpoint.trim();
    final base = trimmed.isEmpty ? 'request' : trimmed;
    final combined = '$method $base';
    if (combined.length <= 120) {
      return combined;
    }
    return '${combined.substring(0, 117)}...';
  }

  static bool _methodMayHaveBody(String method) {
    switch (method) {
      case 'POST':
      case 'PUT':
      case 'PATCH':
      case 'DELETE':
        return true;
      default:
        return false;
    }
  }

  static String _rawBodyLanguage(
    Map<String, String> headerKeyLower,
    String body,
  ) {
    final ct = headerKeyLower['content-type'] ?? '';
    if (ct.contains('json')) {
      return 'json';
    }
    if (ct.contains('xml')) {
      return 'xml';
    }
    if (ct.contains('html')) {
      return 'html';
    }
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return 'json';
    }
    return 'text';
  }

  static List<Map<String, dynamic>> _parseHeadersToPostmanList(
    String? requestHeadersJson,
  ) {
    if (requestHeadersJson == null || requestHeadersJson.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(requestHeadersJson);
      if (decoded is! Map) {
        return <Map<String, dynamic>>[];
      }
      final out = <Map<String, dynamic>>[];
      decoded.forEach((dynamic key, dynamic value) {
        if (key == null) {
          return;
        }
        out.add(<String, dynamic>{
          'key': key.toString(),
          'value': _stringifyHeaderValue(value),
          'type': 'text',
        });
      });
      return out;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static String _stringifyHeaderValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').join(', ');
    }
    return value.toString();
  }

  static Map<String, dynamic> _buildUrlObject(
    String urlString,
    String endpointFallback,
  ) {
    var trimmed = urlString.trim();
    if (trimmed.isEmpty) {
      trimmed = endpointFallback.trim();
    }
    if (trimmed.isEmpty) {
      return <String, dynamic>{'raw': ''};
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return <String, dynamic>{'raw': trimmed};
    }

    final hostParts = uri.host.split('.');
    final pathSegments = uri.pathSegments;
    final query = uri.queryParameters.entries
        .map(
          (MapEntry<String, String> e) => <String, dynamic>{
            'key': e.key,
            'value': e.value,
          },
        )
        .toList();

    final map = <String, dynamic>{
      'raw': uri.toString(),
      'protocol': uri.scheme,
      'host': hostParts,
      if (pathSegments.isNotEmpty) 'path': pathSegments,
      if (query.isNotEmpty) 'query': query,
    };

    final defaultPort = uri.scheme == 'https' ? 443 : 80;
    if (uri.hasPort && uri.port != defaultPort) {
      map['port'] = uri.port.toString();
    }
    return map;
  }
}
