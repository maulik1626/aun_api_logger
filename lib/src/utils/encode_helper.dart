import 'dart:convert';

/// Safely encodes [data] to a pretty-printed JSON string.
///
/// Returns an empty string when [data] is null.
/// If [data] is already a [String], attempts to decode it and re-encode with
/// indentation. If decoding fails (e.g. plain text or HTML), returns the
/// original string.
/// Falls back to [data.toString()] if JSON encoding fails for objects.
String tryEncodeJson(dynamic data) {
  if (data == null) return '';
  try {
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map || decoded is List) {
          return const JsonEncoder.withIndent('  ').convert(decoded);
        }
      } catch (_) {
        // Fall back to original string if not valid JSON
      }
      return data;
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}
