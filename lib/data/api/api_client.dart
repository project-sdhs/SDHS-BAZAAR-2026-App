import 'dart:async';
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
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.timeout = defaultTimeout,
  }) : _http = httpClient ?? http.Client(),
       baseUrl = _trimTrailingSlash(baseUrl ?? defaultBaseUrl);

  /// `--dart-define=API_BASE_URL=...` 로 넘긴 값 (없으면 localhost)
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// 응답을 기다리는 최대 시간. 넘으면 [ApiTimeoutException] 을 던집니다.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final http.Client _http;
  final String baseUrl;
  final Duration timeout;

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
  ///
  /// [headers] 는 기본 헤더에 덧붙입니다 (같은 이름이면 덮어씀).
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async => (await getResponse(path, query: query, headers: headers)).body;

  /// POST 요청을 보내고 JSON 응답을 돌려줍니다.
  ///
  /// [headers] 는 기본 헤더에 덧붙입니다. 예: `{'Idempotency-Key': key}`
  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async => (await postResponse(path, body: body, headers: headers)).body;

  /// [getJson] 과 같지만 상태 코드도 함께 돌려줍니다.
  Future<ApiResponse> getResponse(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _send(() => _http.get(uri(path, query), headers: _headers(headers)));

  /// [postJson] 과 같지만 상태 코드도 함께 돌려줍니다 (예: 201 새로 만듦 / 200 이미 있음).
  Future<ApiResponse> postResponse(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send(
    () => _http.post(
      uri(path),
      headers: _headers(headers),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  void close() => _http.close();

  Map<String, String> _headers(Map<String, String>? extra) => {
    ..._jsonHeaders,
    // TODO(auth): 로그인을 붙이면 여기서 `Authorization: Bearer <Access 토큰>` 을 넣습니다.
    ...?extra,
  };

  Future<ApiResponse> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw ApiTimeoutException(timeout);
    } on http.ClientException catch (error) {
      // 연결 실패 · 끊김. 서버가 요청을 받았는지는 알 수 없습니다.
      throw ApiNetworkException(error.message);
    }
    return ApiResponse(response.statusCode, _decode(response));
  }

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
        retryAfter: _retryAfter(response),
      );
    }

    if (ok) return json;

    // 서버 에러 형식: { "code": "...", "message": "...", "fields"?: {...}, ...추가 필드 }
    final error = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    final fields = error['fields'];
    throw ApiException(
      statusCode: response.statusCode,
      code: error['code'] as String? ?? 'UNKNOWN',
      message: error['message'] as String? ?? '요청에 실패했어요.',
      fields: fields is Map
          ? {
              for (final MapEntry(:key, :value) in fields.entries)
                '$key': '$value',
            }
          : const {},
      details: error,
      retryAfter: _retryAfter(response),
    );
  }

  /// `Retry-After: <초>` 헤더 (429). 없거나 숫자가 아니면 null.
  static Duration? _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}

/// 상태 코드와 JSON 본문.
class ApiResponse {
  const ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final Object? body;
}

/// 서버가 2xx 가 아닌 응답을 줬을 때 던지는 예외.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fields = const {},
    this.details = const {},
    this.retryAfter,
  });

  final int statusCode;
  final String code;
  final String message;

  /// 필드별 이유 (주로 `VALIDATION_FAILED`). 예: `{'amount': '1,000 이상이어야 해요'}`
  final Map<String, String> fields;

  /// 에러 본문 전체. 일부 409 의 추가 필드(`balance`, `pausedAt` …)를 여기서 읽습니다.
  final Map<String, Object?> details;

  /// `Retry-After` 헤더 (429 `RATE_LIMITED`)
  final Duration? retryAfter;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// 서버 응답을 받지 못했을 때 (연결 실패 · 끊김 · 시간 초과).
///
/// 서버가 요청을 처리했는지 알 수 없으므로, 돈이 오가는 요청은 같은 `Idempotency-Key` 로 다시 보냅니다.
class ApiNetworkException implements Exception {
  const ApiNetworkException([this.message = '서버에 연결하지 못했어요.']);

  final String message;

  @override
  String toString() => 'ApiNetworkException: $message';
}

/// [ApiClient.timeout] 안에 응답이 오지 않았을 때.
class ApiTimeoutException extends ApiNetworkException {
  const ApiTimeoutException(this.timeout) : super('서버 응답이 늦어요.');

  final Duration timeout;

  @override
  String toString() => 'ApiTimeoutException(${timeout.inSeconds}s)';
}
