import '../api/api_client.dart';
import '../models/my_credit.dart';
import '../models/my_user.dart';

abstract class MyRepository {
  Future<MyUser> getUser();
  Future<MyCredit> getCredit();
  Future<int> deleteAccount();
}

class ApiMyRepository implements MyRepository {
  ApiMyRepository(this.client);
  final ApiClient client;

  @override
  Future<MyUser> getUser() async =>
      MyUser((await client.getJson('/users/me')) as Map<String, dynamic>);
  @override
  Future<MyCredit> getCredit() async =>
      MyCredit((await client.getJson('/me/credit')) as Map<String, dynamic>);
  @override
  Future<int> deleteAccount() async {
    final json = (await client.deleteJson('/users/me')) as Map<String, dynamic>;
    return json['forfeitedCredit'] as int;
  }
}

/// API 모양의 목 응답. 서버 연결 시 ApiMyRepository를 주입합니다.
class MockMyRepository implements MyRepository {
  MockMyRepository({this.user = mockStudent, this.credit = mockCredit});
  final MyUser user;
  final MyCredit credit;
  @override
  Future<MyUser> getUser() async => user;
  @override
  Future<MyCredit> getCredit() async => credit;
  @override
  Future<int> deleteAccount() async {
    if (credit.pendingChargeAmount > 0) {
      throw const ApiException(
        statusCode: 409,
        code: 'PENDING_CHARGE',
        message: '처리 중인 충전이 있어 계정을 삭제할 수 없어요.',
      );
    }
    return credit.balance;
  }
}
