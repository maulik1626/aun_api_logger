import 'package:flutter/cupertino.dart';

class LogColorHelper {
  static Color getStatusColor(int? statusCode) {
    if (statusCode == null) return CupertinoColors.systemGrey;
    if (statusCode >= 200 && statusCode < 300) {
      return CupertinoColors.activeGreen;
    }
    if (statusCode >= 300 && statusCode < 400) {
      return CupertinoColors.systemBlue;
    }
    if (statusCode >= 400 && statusCode < 500) {
      return CupertinoColors.systemOrange;
    }
    return CupertinoColors.systemRed;
  }

  static Color getMethodColor(String? method) {
    if (method == null) return CupertinoColors.systemGrey;
    final m = method.toUpperCase();
    switch (m) {
      case 'GET':
        return CupertinoColors.systemBlue;
      case 'POST':
        return CupertinoColors.activeGreen;
      case 'PUT':
      case 'PATCH':
        return CupertinoColors.systemOrange;
      case 'DELETE':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
