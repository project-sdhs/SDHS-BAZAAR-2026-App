import '../api/api_client.dart';
import '../models/popular_booth.dart';

/// 부스 관련 서버 호출.
class BoothRepository {
  BoothRepository(this._api);

  final ApiClient _api;

  /// 실시간 인기 부스. 순위 순서로 돌려줍니다.
  ///
  /// 응답 모양이 다르면 [FormatException] 을 던집니다.
  Future<List<PopularBooth>> popularBooths() async {
    final items = _items(await _api.getJson('/booths/popular'), '인기 부스');
    final booths = items.map((item) => PopularBooth.fromJson(item)).toList();
    booths.sort((a, b) => a.rank.compareTo(b.rank));
    return booths;
  }

  List<Map<String, Object?>> _items(Object? body, String what) {
    if (body is! Map<String, Object?> || body['items'] is! List) {
      throw FormatException('$what 응답에 items 가 없어요');
    }
    return (body['items']! as List).cast<Map<String, Object?>>();
  }
}
