# aun_api_logger

A standalone Flutter package designed to silently capture API traffic in debug mode and store it in a local SQLite database. It provides an out-of-the-box UI to visualize, filter by date, copy, and export your API requests and responses.

## Features

- **Local SQLite Storage**: Fast, persistent storage without external dependencies.
- **Dio Integration**: Plug-and-play `ApiLoggerInterceptor` for your Dio client.
- **Built-in UI**: Inspect logs grouped by day, view structured request/response blocks with pretty-printed JSON.
- **Export & Share**: Download your entire history or just a specific day's logs. Copy individual JSON payloads easily.

## Installation

Add the package to your project. If it's stored locally alongside your apps, use:

```yaml
dependencies:
  aun_api_logger:
    path: ../aun_api_logger
```

Or from GitHub, pin to an immutable ref (tag or commit SHA):

```yaml
dependencies:
  aun_api_logger:
    git:
      url: https://github.com/maulik1626/aun_api_logger.git
      ref: 19760d0d109863cf0d99e4d567eb3ad0fd88095c
```

Do not use moving refs like `main`. Whenever the pinned `ref` changes in any app `pubspec.yaml`, update the README code block in the same change.

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

Attach the `ApiLoggerInterceptor` to your Dio instance:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:aun_api_logger/aun_api_logger.dart';

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
