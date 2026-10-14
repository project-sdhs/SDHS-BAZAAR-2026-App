import 'dart:convert';

import 'package:http/http.dart' as http;

/// 서버와 통신하는 기본 클라이언트.
///
/// 서버 주소는 실행할 때 `--dart-define` 으로 바꿀 수 있습니다.
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
/// ```
/// 값을 안 주면 `http://localhost:3000` 을 씁니다.
///
/// 화면에서 직접 쓰지 말고 `data/repositories` 의 저장소 클래스에서 씁니다.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl = _trimTrailingSlash(baseUrl ?? defaultBaseUrl);

  /// `--dart-define=API_BASE_URL=...` 로 넘긴 값 (없으면 localhost)
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  final http.Client _http;
  final String baseUrl;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// `baseUrl` 뒤에 [path] 를 붙인 주소를 만듭니다. 예: `uri('/health')`
  Uri uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final result = Uri.parse('$baseUrl$normalizedPath');
    return query == null ? result : result.replace(queryParameters: query);
  }

  /// GET 요청을 보내고 JSON 응답을 돌려줍니다.
  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    final response = await _http.get(uri(path, query), headers: _jsonHeaders);
    return _decode(response);
  }

  /// POST 요청을 보내고 JSON 응답을 돌려줍니다.
  Future<Object?> postJson(String path, {Object? body}) async {
    final response = await _http.post(
      uri(path),
      headers: _jsonHeaders,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  void close() => _http.close();

  Object? _decode(http.Response response) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final text = utf8.decode(response.bodyBytes);

    Object? json;
    try {
      json = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      // JSON 이 아닌 응답 (예: 프록시의 HTML 에러 페이지)
      throw ApiException(
        statusCode: response.statusCode,
        code: ok ? 'INVALID_RESPONSE' : 'UNKNOWN',
        message: '서버 응답을 읽을 수 없어요.',
      );
    }

    if (ok) return json;

    // 서버 에러 형식: { "code": "...", "message": "..." }
    final error = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    throw ApiException(
      statusCode: response.statusCode,
      code: error['code'] as String? ?? 'UNKNOWN',
      message: error['message'] as String? ?? '요청에 실패했어요.',
    );
  }

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}

/// 서버가 2xx 가 아닌 응답을 줬을 때 던지는 예외.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
