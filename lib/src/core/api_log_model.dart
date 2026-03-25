class ApiLogModel {
  int? id;
  final String method;
  final String url;
  final String endpoint;
  int? statusCode;
  String? requestHeaders;
  String? requestBody;
  String? responseHeaders;
  String? responseBody;
  final int requestTime; // stored in epoch milliseconds
  int durationMs;

  ApiLogModel({
    this.id,
    required this.method,
    required this.url,
    required this.endpoint,
    this.statusCode,
    this.requestHeaders,
    this.requestBody,
    this.responseHeaders,
    this.responseBody,
    required this.requestTime,
    this.durationMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'endpoint': endpoint,
      'statusCode': statusCode,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
      'requestTime': requestTime,
      'durationMs': durationMs,
    };
  }

  factory ApiLogModel.fromMap(Map<String, dynamic> map) {
    return ApiLogModel(
      id: map['id'],
      method: map['method'] ?? '',
      url: map['url'] ?? '',
      endpoint: map['endpoint'] ?? '',
      statusCode: map['statusCode'],
      requestHeaders: map['requestHeaders'],
      requestBody: map['requestBody'],
      responseHeaders: map['responseHeaders'],
      responseBody: map['responseBody'],
      requestTime: map['requestTime'] ?? 0,
      durationMs: map['durationMs'] ?? 0,
    );
  }
}
