import '../api/api_client.dart';
import '../models/booth.dart';
import '../models/popular_booth.dart';

/// 부스 관련 서버 호출.
class BoothRepository {
  BoothRepository(this._api);

  final ApiClient _api;

  /// 부스 전체 목록 (`GET /booths`).
  ///
  /// 응답 모양이 다르면 [FormatException] 을 던집니다.
  Future<List<Booth>> booths() async {
    final items = _items(await _api.getJson('/booths'), '부스 목록');
    return items.map((item) => Booth.fromJson(item)).toList();
  }

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
