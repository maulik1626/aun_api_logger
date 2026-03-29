import 'dart:convert' show jsonEncode;

import 'package:aun_api_logger/src/core/api_log_model.dart';
import 'package:aun_api_logger/src/ui/widgets/shared_log_capture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the share card for a small log', (
    WidgetTester tester,
  ) async {
    final log = ApiLogModel(
      method: 'POST',
      url: 'https://api.example.com/v1/auth',
      endpoint: '/v1/auth',
      statusCode: 200,
      requestHeaders: '{"Content-Type": "application/json"}',
      requestBody: '{"username": "test"}',
      responseHeaders: '{"Server": "nginx"}',
      responseBody: '{"token": "xyz"}',
      requestTime: 1_711_200_000_000,
      durationMs: 154,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: SharedLogCaptureCard(
                log: log,
                displayEndpoint: '/v1/auth',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Request Headers'), findsOneWidget);
    expect(find.text('Response Body'), findsOneWidget);
    expect(find.text('/v1/auth'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders large response bodies in the share card', (
    WidgetTester tester,
  ) async {
    final big = jsonEncode({
      'items': List.generate(
        350,
        (i) => {
          'id': i,
          'doctor_name': 'Doctor $i',
          'slots': List.generate(
            8,
            (j) => {
              'start_time':
                  '2026-02-28T${(j + 8).toString().padLeft(2, '0')}:00:00.000Z',
              'end_time':
                  '2026-02-28T${(j + 9).toString().padLeft(2, '0')}:00:00.000Z',
              'is_available': j.isEven,
            },
          ),
        },
      ),
    });
    expect(big.length, greaterThan(100_000));

    final log = ApiLogModel(
      method: 'GET',
      url: 'https://example.com/api',
      endpoint: '/api',
      statusCode: 200,
      responseBody: big,
      requestTime: 1_711_200_000_000,
      durationMs: 42,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: SharedLogCaptureCard(log: log, displayEndpoint: '/api'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Response Body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
