import 'dart:convert';

/// Safely encodes [data] to a pretty-printed JSON string.
///
/// Returns an empty string when [data] is null.
/// Returns [data] as-is when it is already a [String].
/// Falls back to [data.toString()] if JSON encoding fails.
String tryEncodeJson(dynamic data) {
  if (data == null) return '';
  try {
    if (data is String) return data;
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}
