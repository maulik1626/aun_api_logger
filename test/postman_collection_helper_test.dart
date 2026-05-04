import 'dart:convert';
import 'dart:io';

import 'package:aun_api_logger/src/core/api_log_model.dart';
import 'package:aun_api_logger/src/utils/postman_collection_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

Map<String, dynamic> _firstRequest(Map<String, dynamic> collection) {
  final item =
      (collection['item']! as List<dynamic>).first as Map<String, dynamic>;
  return item['request']! as Map<String, dynamic>;
}

void main() {
  const v21Schema =
      'https://schema.getpostman.com/json/collection/v2.1.0/collection.json';

  group('PostmanCollectionHelper.buildCollectionMap', () {
    test('produces v2.1 schema and a single request item', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://api.example.com/v1/ping',
        endpoint: '/v1/ping',
        requestTime: 1_700_000_000_000,
        durationMs: 12,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'v1/ping',
      );

      expect(map['info'], isA<Map<String, dynamic>>());
      final info = map['info']! as Map<String, dynamic>;
      expect(info['schema'], v21Schema);
      expect(info['name'], isA<String>());

      final items = map['item']! as List<dynamic>;
      expect(items, hasLength(1));
      final item = items.first as Map<String, dynamic>;
      expect(item['name'], 'GET v1/ping');

      final request = item['request']! as Map<String, dynamic>;
      expect(request['method'], 'GET');
      expect(request['header'], isEmpty);

      final url = request['url']! as Map<String, dynamic>;
      expect(url['raw'], 'https://api.example.com/v1/ping');
      expect(url['protocol'], 'https');
      expect(url['host'], ['api', 'example', 'com']);
      expect(url['path'], ['v1', 'ping']);
    });

    test('parses headers including list values (Dio-style)', () {
      final log = ApiLogModel(
        method: 'POST',
        url: 'https://x.test/a',
        endpoint: '/a',
        requestHeaders: jsonEncode(<String, dynamic>{
          'Authorization': 'Bearer t',
          'Accept': <String>['application/json', 'text/plain'],
        }),
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/a',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      final headers = requestMap['header']! as List<dynamic>;

      expect(headers, hasLength(2));
      final h0 = headers[0] as Map<String, dynamic>;
      expect(h0['key'], 'Authorization');
      expect(h0['value'], 'Bearer t');
      final h1 = headers[1] as Map<String, dynamic>;
      expect(h1['key'], 'Accept');
      expect(h1['value'], 'application/json, text/plain');
    });

    test('POST JSON body uses raw mode with json language', () {
      final log = ApiLogModel(
        method: 'post',
        url: 'https://api.example.com/login',
        endpoint: '/login',
        requestHeaders: jsonEncode({'Content-Type': 'application/json'}),
        requestBody: '{"user":"a"}',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'login',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      final body = requestMap['body']! as Map<String, dynamic>;

      expect(body['mode'], 'raw');
      expect(body['raw'], '{"user":"a"}');
      final options = body['options']! as Map<String, dynamic>;
      final rawOpts = options['raw']! as Map<String, dynamic>;
      expect(rawOpts['language'], 'json');
    });

    test('GET omits body even when requestBody is set', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://a.b/',
        endpoint: '/',
        requestBody: '{"ignored":true}',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      expect(requestMap.containsKey('body'), isFalse);
    });

    test('URL includes non-default port', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'http://localhost:8080/api',
        endpoint: '/api',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'api',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      final url = requestMap['url']! as Map<String, dynamic>;
      expect(url['port'], '8080');
    });

    test('query parameters appear in url object', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://host.test/path?q=1&z=two',
        endpoint: '/path',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'path',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      final url = requestMap['url']! as Map<String, dynamic>;
      final query = url['query']! as List<dynamic>;
      expect(query, hasLength(2));
      final keys = query
          .map((dynamic e) => (e as Map<String, dynamic>)['key'] as String)
          .toSet();
      expect(keys, {'q', 'z'});
    });

    test('invalid requestHeaders JSON yields empty header list', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://a.b/',
        endpoint: '/',
        requestHeaders: 'not-json',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      expect(requestMap['header'], isEmpty);
    });

    test('uses endpoint when url is empty', () {
      final log = ApiLogModel(
        method: 'GET',
        url: '',
        endpoint: '/relative/path',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'relative/path',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      final url = requestMap['url']! as Map<String, dynamic>;
      expect(url['raw'], '/relative/path');
    });

    test('PATCH includes body', () {
      final log = ApiLogModel(
        method: 'patch',
        url: 'https://a.b/c',
        endpoint: '/c',
        requestBody: '{"x":1}',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'c',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      expect(requestMap['method'], 'PATCH');
      expect((requestMap['body']! as Map<String, dynamic>)['raw'], '{"x":1}');
    });

    test('DELETE with body includes raw body', () {
      final log = ApiLogModel(
        method: 'DELETE',
        url: 'https://a.b/items/1',
        endpoint: '/items/1',
        requestBody: '{"reason":"cleanup"}',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'items/1',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final requestMap = request['request']! as Map<String, dynamic>;
      final body = requestMap['body']! as Map<String, dynamic>;
      expect(body['mode'], 'raw');
      expect(body['raw'], '{"reason":"cleanup"}');
    });

    test('truncates long item name at 120 characters', () {
      final longSeg = List.filled(130, 'a').join();
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://a.b/',
        endpoint: '/',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: longSeg,
      );
      final item =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final name = item['name']! as String;
      expect(name.length, 120);
      expect(name.endsWith('...'), isTrue);
      final info = map['info']! as Map<String, dynamic>;
      expect((info['name']! as String).length, greaterThan(100));
    });

    test('raw body language xml from Content-Type', () {
      final log = ApiLogModel(
        method: 'POST',
        url: 'https://a.b/',
        endpoint: '/',
        requestHeaders: jsonEncode({
          'Content-Type': 'application/xml; charset=utf-8',
        }),
        requestBody: '<r/>',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final body =
          (request['request']! as Map<String, dynamic>)['body']!
              as Map<String, dynamic>;
      final lang =
          ((body['options'] as Map<String, dynamic>)['raw']
                  as Map<String, dynamic>)['language']
              as String;
      expect(lang, 'xml');
    });

    test('raw body language html from Content-Type', () {
      final log = ApiLogModel(
        method: 'POST',
        url: 'https://a.b/',
        endpoint: '/',
        requestHeaders: jsonEncode({'Content-Type': 'text/html'}),
        requestBody: '<p>x</p>',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final body =
          (request['request']! as Map<String, dynamic>)['body']!
              as Map<String, dynamic>;
      final lang =
          ((body['options'] as Map<String, dynamic>)['raw']
                  as Map<String, dynamic>)['language']
              as String;
      expect(lang, 'html');
    });

    test('plain text body without JSON Content-Type uses text language', () {
      final log = ApiLogModel(
        method: 'POST',
        url: 'https://a.b/',
        endpoint: '/',
        requestHeaders: jsonEncode({'Content-Type': 'text/plain'}),
        requestBody: 'plain payload',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final body =
          (request['request']! as Map<String, dynamic>)['body']!
              as Map<String, dynamic>;
      final lang =
          ((body['options'] as Map<String, dynamic>)['raw']
                  as Map<String, dynamic>)['language']
              as String;
      expect(lang, 'text');
    });

    test('URL without scheme yields raw-only url object', () {
      final log = ApiLogModel(
        method: 'GET',
        url: '/api/v2/only-path',
        endpoint: '/api/v2/only-path',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'api/v2/only-path',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final url =
          (request['request']! as Map<String, dynamic>)['url']!
              as Map<String, dynamic>;
      expect(url.keys.toSet(), {'raw'});
      expect(url['raw'], '/api/v2/only-path');
    });

    test('headers JSON array root yields empty headers', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://a.b/',
        endpoint: '/',
        requestHeaders: jsonEncode(<dynamic>['a', 'b']),
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      expect((request['request']! as Map<String, dynamic>)['header'], isEmpty);
    });

    test('empty displayEndpoint uses request as item base name', () {
      final log = ApiLogModel(
        method: 'PUT',
        url: 'https://a.b/',
        endpoint: '/',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '   ',
      );
      final item =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      expect(item['name'], 'PUT request');
    });

    test('HTTPS default port omits port key', () {
      final log = ApiLogModel(
        method: 'GET',
        url: 'https://example.com/path',
        endpoint: '/path',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'path',
      );
      final request =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      final url =
          (request['request']! as Map<String, dynamic>)['url']!
              as Map<String, dynamic>;
      expect(url.containsKey('port'), isFalse);
    });

    test('info block includes exporter id and schema', () {
      final log = ApiLogModel(
        method: 'HEAD',
        url: 'https://z.z/',
        endpoint: '/',
        requestTime: 1,
      );

      final map = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: '/',
      );
      final info = map['info']! as Map<String, dynamic>;
      expect(info['_exporter_id'], 'aun_api_logger');
      expect(info['schema'], v21Schema);
      final item =
          (map['item']! as List<dynamic>).first as Map<String, dynamic>;
      expect((item['request']! as Map<String, dynamic>)['method'], 'HEAD');
    });

    group('edge cases', () {
      test('both url and endpoint empty yields empty raw url', () {
        final log = ApiLogModel(
          method: 'GET',
          url: '',
          endpoint: '',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'x',
        );
        final url = _firstRequest(map)['url']! as Map<String, dynamic>;
        expect(url['raw'], '');
      });

      test('POST with whitespace-only requestBody omits body', () {
        final log = ApiLogModel(
          method: 'POST',
          url: 'https://a.b/',
          endpoint: '/',
          requestBody: '  \n\t  ',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        expect(_firstRequest(map).containsKey('body'), isFalse);
      });

      test('POST with null requestBody omits body', () {
        final log = ApiLogModel(
          method: 'POST',
          url: 'https://a.b/',
          endpoint: '/',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        expect(_firstRequest(map).containsKey('body'), isFalse);
      });

      test('header value null decodes to empty string', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://a.b/',
          endpoint: '/',
          requestHeaders: jsonEncode(<String, dynamic>{'X-Null': null}),
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final headers = _firstRequest(map)['header']! as List<dynamic>;
        expect(headers, hasLength(1));
        expect((headers.first as Map<String, dynamic>)['value'], '');
      });

      test('header value number and bool stringify', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://a.b/',
          endpoint: '/',
          requestHeaders: jsonEncode(<String, dynamic>{
            'X-Num': 42,
            'X-Bool': false,
          }),
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final headers = _firstRequest(map)['header']! as List<dynamic>;
        final byKey = <String, String>{};
        for (final dynamic h in headers) {
          final m = h as Map<String, dynamic>;
          byKey[m['key']! as String] = m['value']! as String;
        }
        expect(byKey['X-Num'], '42');
        expect(byKey['X-Bool'], 'false');
      });

      test('header empty list value stringifies to empty string', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://a.b/',
          endpoint: '/',
          requestHeaders: jsonEncode(<String, dynamic>{'X': <dynamic>[]}),
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final headers = _firstRequest(map)['header']! as List<dynamic>;
        expect((headers.first as Map<String, dynamic>)['value'], '');
      });

      test('Content-Type detection is case-insensitive on header name', () {
        final log = ApiLogModel(
          method: 'POST',
          url: 'https://a.b/',
          endpoint: '/',
          requestHeaders: jsonEncode({'CONTENT-TYPE': 'application/json'}),
          requestBody: '{}',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final bodyMap = _firstRequest(map)['body']! as Map<String, dynamic>;
        final options = bodyMap['options']! as Map<String, dynamic>;
        final rawOpts = options['raw']! as Map<String, dynamic>;
        expect(rawOpts['language'], 'json');
      });

      test('body starting with whitespace before brace uses json language', () {
        final log = ApiLogModel(
          method: 'POST',
          url: 'https://a.b/',
          endpoint: '/',
          requestBody: '\n  {"a":1}',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final bodyMap = _firstRequest(map)['body']! as Map<String, dynamic>;
        final options = bodyMap['options']! as Map<String, dynamic>;
        final rawOpts = options['raw']! as Map<String, dynamic>;
        expect(rawOpts['language'], 'json');
      });

      test('JSON array body without Content-Type infers json language', () {
        final log = ApiLogModel(
          method: 'POST',
          url: 'https://a.b/',
          endpoint: '/',
          requestBody: '[1,2]',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final bodyMap = _firstRequest(map)['body']! as Map<String, dynamic>;
        final options = bodyMap['options']! as Map<String, dynamic>;
        final rawOpts = options['raw']! as Map<String, dynamic>;
        expect(rawOpts['language'], 'json');
      });

      test('OPTIONS with requestBody still omits body block', () {
        final log = ApiLogModel(
          method: 'options',
          url: 'https://a.b/r',
          endpoint: '/r',
          requestBody: '{"nope":true}',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'r',
        );
        final req = _firstRequest(map);
        expect(req['method'], 'OPTIONS');
        expect(req.containsKey('body'), isFalse);
      });

      test('host-only HTTPS URL omits path key when path is empty', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://example.com',
          endpoint: '',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'example.com',
        );
        final url = _firstRequest(map)['url']! as Map<String, dynamic>;
        expect(url.containsKey('path'), isFalse);
        expect(url['host'], ['example', 'com']);
        expect(url['raw'], 'https://example.com');
      });

      test('HTTP explicit port 80 omits port key', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'http://example.com:80/p',
          endpoint: '/p',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'p',
        );
        final url = _firstRequest(map)['url']! as Map<String, dynamic>;
        expect(url.containsKey('port'), isFalse);
      });

      test('URL with userInfo and query is preserved in raw', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://user:p%40ss@host.test/api?q=1',
          endpoint: '/api',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'api',
        );
        final url = _firstRequest(map)['url']! as Map<String, dynamic>;
        expect((url['raw']! as String).contains('user:'), isTrue);
        expect(url['query'], isNotNull);
      });

      test('IPv6 bracket host parses into host segments', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://[::1]:8443/v1',
          endpoint: '/v1',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'v1',
        );
        final url = _firstRequest(map)['url']! as Map<String, dynamic>;
        expect(url['port'], '8443');
        expect(url['host'], isNotEmpty);
        expect(url['path'], ['v1']);
      });

      test('query parameter with empty value appears in query list', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://h.test/x?empty=&k=v',
          endpoint: '/x',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'x',
        );
        final query =
            (_firstRequest(map)['url']! as Map<String, dynamic>)['query']!
                as List<dynamic>;
        final emptyEntry = query.cast<Map<String, dynamic>>().firstWhere(
          (Map<String, dynamic> e) => e['key'] == 'empty',
        );
        expect(emptyEntry['value'], '');
      });

      test('headers JSON includes empty string key when present', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://a.b/',
          endpoint: '/',
          requestHeaders: '{"":"no-key","Valid":"1"}',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final headers = _firstRequest(map)['header']! as List<dynamic>;
        expect(headers, hasLength(2));
        final keys = headers
            .map((dynamic h) => (h as Map<String, dynamic>)['key']! as String)
            .toSet();
        expect(keys, contains(''));
        expect(keys, contains('Valid'));
      });

      test('nested map header value uses toString', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://a.b/',
          endpoint: '/',
          requestHeaders: jsonEncode(<String, dynamic>{
            'X-Obj': <String, dynamic>{'nested': true},
          }),
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        final headers = _firstRequest(map)['header']! as List<dynamic>;
        final value =
            (headers.first as Map<String, dynamic>)['value']! as String;
        expect(value, contains('nested'));
      });

      test('non-standard method name is uppercased', () {
        final log = ApiLogModel(
          method: 'custom',
          url: 'https://a.b/',
          endpoint: '/',
          requestTime: 1,
        );

        final collection = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: '/',
        );
        expect(_firstRequest(collection)['method'], 'CUSTOM');
      });

      test('URL with fragment keeps fragment in raw string', () {
        final log = ApiLogModel(
          method: 'GET',
          url: 'https://ex.test/data#section',
          endpoint: '/data',
          requestTime: 1,
        );

        final map = PostmanCollectionHelper.buildCollectionMap(
          log,
          displayEndpoint: 'data',
        );
        final raw =
            (_firstRequest(map)['url']! as Map<String, dynamic>)['raw']!
                as String;
        expect(raw, contains('#section'));
      });
    });
  });

  group('PostmanCollectionHelper.writeShareCollectionJsonFile', () {
    late PathProviderPlatform savedPathProvider;

    setUpAll(() {
      savedPathProvider = PathProviderPlatform.instance;
    });

    tearDown(() {
      PathProviderPlatform.instance = savedPathProvider;
    });

    test('writes valid JSON collection file', () async {
      final dir = Directory.systemTemp.createTempSync('aun_pm_test_');
      PathProviderPlatform.instance = _FakePathProvider(dir.path);

      final log = ApiLogModel(
        method: 'DELETE',
        url: 'https://api.example.com/r/1',
        endpoint: '/r/1',
        requestHeaders: jsonEncode({'X-Test': '1'}),
        requestTime: 1_711_200_000_000,
      );

      final file = await PostmanCollectionHelper.writeShareCollectionJsonFile(
        log: log,
        displayEndpoint: 'r/1',
      );

      expect(file.path.endsWith('.json'), isTrue);
      expect(file.path.contains('DELETE'), isTrue);
      expect(file.path.contains('postman'), isTrue);

      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded['info'], isNotNull);
      expect((decoded['info']! as Map<String, dynamic>)['schema'], v21Schema);
    });

    test('file JSON matches buildCollectionMap output', () async {
      final dir = Directory.systemTemp.createTempSync('aun_pm_test2_');
      PathProviderPlatform.instance = _FakePathProvider(dir.path);

      final log = ApiLogModel(
        method: 'PUT',
        url: 'https://api.example.com/x',
        endpoint: '/x',
        requestBody: '{}',
        requestTime: 1_700_000_000_000,
      );

      final file = await PostmanCollectionHelper.writeShareCollectionJsonFile(
        log: log,
        displayEndpoint: 'x',
      );

      final fromDisk =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final expected = PostmanCollectionHelper.buildCollectionMap(
        log,
        displayEndpoint: 'x',
      );
      expect(fromDisk, expected);
    });

    test(
      'displayEndpoint of only punctuation still writes a .json file',
      () async {
        final dir = Directory.systemTemp.createTempSync('aun_pm_test3_');
        PathProviderPlatform.instance = _FakePathProvider(dir.path);

        final log = ApiLogModel(
          method: 'GET',
          url: 'https://a.b/',
          endpoint: '/',
          requestTime: 1_711_200_000_000,
        );

        final file = await PostmanCollectionHelper.writeShareCollectionJsonFile(
          log: log,
          displayEndpoint: '!!!',
        );

        expect(file.path.endsWith('.json'), isTrue);
        expect(await file.exists(), isTrue);
        expect(file.path.contains('GET_postman'), isTrue);
      },
    );
  });
}

final class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._tempPath);

  final String _tempPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;
}
