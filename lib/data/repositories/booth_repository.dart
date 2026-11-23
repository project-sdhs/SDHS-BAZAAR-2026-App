import '../api/api_client.dart';
import '../models/booth.dart';
import '../models/popular_booth.dart';

/// 부스 관련 서버 호출.
class BoothRepository {
  BoothRepository(this._api);

  final ApiClient _api;

  /// 부스 목록 (`GET /booths?sort=grade|popular&q=`). 서버가 준 순서 그대로입니다.
  ///
  /// [query] 를 주면 서버가 부스 이름 · 반 이름 · 메뉴 이름에서 부분 일치로 찾습니다
  /// (공백 무시, 앞뒤 공백을 뺀 1~30자. 넘으면 400).
  /// 응답 모양이 다르면 [FormatException] 을 던집니다.
  Future<List<Booth>> booths({String sort = 'grade', String? query}) async {
    final q = query?.trim();
    final items = _items(
      await _api.getJson(
        '/booths',
        query: {'sort': sort, if (q != null && q.isNotEmpty) 'q': q},
      ),
      '부스 목록',
    );
    return items.map((item) => Booth.fromJson(item)).toList();
  }

  /// 앱이 끝날 때 HTTP 연결을 닫습니다.
  void close() => _api.close();

  /// 실시간 인기 부스. 순위 순서로 돌려줍니다.
  ///
  /// 응답 모양이 다르면 [FormatException] 을 던집니다.
  Future<List<PopularBooth>> popularBooths() async {
    final items = _items(await _api.getJson('/booths/popular'), '인기 부스');
    final booths = items.map((item) => PopularBooth.fromJson(item)).toList();
    booths.sort((a, b) => a.rank.compareTo(b.rank));
    return booths;
  }

  /// 서버가 준 상대 경로를 앱이 쓰는 서버 주소와 합친 이미지 주소.
  String? imageUrl(String? path) =>
      path == null ? null : '${_api.baseUrl}$path';

  List<Map<String, Object?>> _items(Object? body, String what) {
    if (body is! Map<String, Object?> || body['items'] is! List) {
      throw FormatException('$what 응답에 items 가 없어요');
    }
    return (body['items']! as List).cast<Map<String, Object?>>();
  }
}
