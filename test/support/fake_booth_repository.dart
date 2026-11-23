import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/popular_booth.dart';
import 'package:bazaar_app/data/repositories/booth_repository.dart';

/// 서버 대신 정해 둔 값(또는 오류)을 돌려주는 부스 저장소 (테스트용).
class FakeBoothRepository extends BoothRepository {
  FakeBoothRepository({Future<List<PopularBooth>> Function()? popular})
    : _popular = popular ?? (() async => const []),
      super(ApiClient());

  final Future<List<PopularBooth>> Function() _popular;

  @override
  Future<List<PopularBooth>> popularBooths() => _popular();
}
