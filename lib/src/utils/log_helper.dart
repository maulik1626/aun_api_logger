import 'dart:convert';

class LogHelper {
  static String getRequestBodyType(String? requestHeaders) {
    try {
      if (requestHeaders == null || requestHeaders.isEmpty) {
        return '';
      }
      final headers = jsonDecode(requestHeaders) as Map<String, dynamic>;

      String contentType = '';
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'content-type') {
          contentType = value.toString().toLowerCase();
        }
      });

      if (contentType.contains('multipart/form-data')) {
        return ' (FormData)';
      } else if (contentType.contains('application/json')) {
        return ' (JSON)';
      } else if (contentType.contains('application/x-www-form-urlencoded')) {
        return ' (FormURLEncoded)';
      }
    } catch (_) {}
    return '';
  }
}
