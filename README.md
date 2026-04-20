# aun_api_logger

A standalone Flutter package designed to silently capture API traffic in debug mode and store it in a local SQLite database. It provides an out-of-the-box UI to visualize, filter by date, copy, and export your API requests and responses.

## Features

- **Local SQLite Storage**: Fast, persistent storage without external dependencies.
- **Multi-Client Support**: Works with `package:http`, `dart:io HttpClient`, and Dio.
- **Built-in UI**: Inspect logs grouped by day, view structured request/response blocks with pretty-printed JSON.
- **Export & Share**: Download your entire history or just a specific day's logs. Copy individual JSON payloads easily.

## Installation

Add the package to your project. If it's stored locally alongside your apps, use:

```yaml
dependencies:
  aun_api_logger:
    path: ../aun_api_logger
```

Or from GitHub, pin to an immutable ref (tag):

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: v2.0.1
```

Do not use moving refs like `main`.

This block must always display the latest released version tag. Whenever the pinned `ref` is changed, update this README block and the corresponding `CHANGELOG.md` dependency block in the same change.

## Usage

### 1. Initialize the internal DB

In your `main.dart`, before `runApp`:

```dart
import 'package:flutter/foundation.dart';
import 'package:aun_api_logger/aun_api_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize in Debug mode to avoid production overhead
  if (kDebugMode) {
    await AunApiLogger.instance.initialize();
  }
  
  runApp(const MyApp());
}
```

### 2. Plug into your Network Layer

Choose the adapter that matches your HTTP client:

#### Option A: `package:http` (Recommended)

```dart
import 'package:flutter/foundation.dart';
import 'package:aun_api_logger/aun_api_logger.dart';

// Use ApiLoggerHttpClient as a drop-in replacement for http.Client()
final client = kDebugMode ? ApiLoggerHttpClient() : http.Client();

// All requests are automatically logged:
final response = await client.get(Uri.parse('https://api.example.com/data'));
final response = await client.post(Uri.parse('https://api.example.com/data'), body: jsonEncode(payload));

// Or wrap an existing client:
final client = ApiLoggerHttpClient(innerClient: myExistingClient);
```

#### Option B: `dart:io HttpClient`

```dart
import 'package:flutter/foundation.dart';
import 'package:aun_api_logger/aun_api_logger.dart';

// Use ApiLoggerIoHttpClient as a drop-in replacement for HttpClient()
final client = kDebugMode ? ApiLoggerIoHttpClient() : HttpClient();

// All requests are automatically logged:
final request = await client.getUrl(Uri.parse('https://api.example.com/data'));
final response = await request.close();

// Or wrap an existing HttpClient:
final client = ApiLoggerIoHttpClient(innerClient: myExistingHttpClient);
```

#### Option C: Dio

> **Note:** Since v2.0.0, `dio` is no longer a direct dependency of this package. Add `dio` to your own `pubspec.yaml` and import the interceptor directly:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aun_api_logger/src/interceptors/api_logger_interceptor.dart';

final dio = Dio();

// Attach only if debugging
if (kDebugMode) {
  dio.interceptors.add(ApiLoggerInterceptor());
}
```

### 3. Display the UI

Expose the `LogDatesScreen` somewhere in your app (like a hidden QA menu or a debug icon in the App Bar):

```dart
import 'package:aun_api_logger/aun_api_logger.dart';

// Inside a widget or button onPressed:
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LogDatesScreen()),
);
```

## Migration from v1.x to v2.0.0

1. **Dio users**: Add `dio` to your own `pubspec.yaml` dependencies. Change the import from:
   ```dart
   import 'package:aun_api_logger/aun_api_logger.dart'; // ApiLoggerInterceptor was exported here
   ```
   to:
   ```dart
   import 'package:aun_api_logger/src/interceptors/api_logger_interceptor.dart';
   ```

2. **`package:http` users**: Simply use `ApiLoggerHttpClient()` as a drop-in replacement for `http.Client()`.

3. **`dart:io HttpClient` users**: Use `ApiLoggerIoHttpClient()` as a drop-in replacement for `HttpClient()`.
