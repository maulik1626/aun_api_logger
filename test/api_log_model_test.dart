import 'package:flutter_test/flutter_test.dart';
import 'package:aun_api_logger/src/core/api_log_model.dart'; // Adjust import if needed based on package exports

void main() {
  group('ApiLogModel Tests', () {
    test('toMap and fromMap should retain all data accurately', () {
      final original = ApiLogModel(
        id: 1,
        method: 'POST',
        url: 'https://api.example.com/v1/auth',
        endpoint: '/v1/auth',
        statusCode: 200,
        requestHeaders: '{"Content-Type": "application/json"}',
        requestBody: '{"username": "test"}',
        responseHeaders: '{"Server": "nginx"}',
        responseBody: '{"token": "xyz"}',
        requestTime: 1711200000000,
        durationMs: 154,
      );

      final map = original.toMap();
      final cloned = ApiLogModel.fromMap(map);

      expect(cloned.id, 1);
      expect(cloned.method, 'POST');
      expect(cloned.endpoint, '/v1/auth');
      expect(cloned.statusCode, 200);
      expect(cloned.requestTime, 1711200000000);
      expect(cloned.durationMs, 154);
    });

    test('fromMap gracefully handles null optionals', () {
      final map = <String, dynamic>{
        'method': 'GET',
        'url': 'https://api.example.com/ping',
        'endpoint': '/ping',
        'requestTime': 1711200000000,
        'durationMs': 12,
      };

      final parsed = ApiLogModel.fromMap(map);

      expect(parsed.id, isNull);
      expect(parsed.method, 'GET');
      expect(parsed.statusCode, isNull);
      expect(parsed.requestBody, isNull);
    });
  });
}
