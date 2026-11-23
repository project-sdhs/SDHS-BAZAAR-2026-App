import 'package:bazaar_app/data/api/api_client.dart';

import 'package:http/http.dart';

Future<int> fetchOpenBoothCount() async {
  final client = ApiClient();

  try {
    final data = await client.getJson('/booths/open-count');

    if (data is! Map<String, dynamic>) {
      throw const FormatException('응답 형식이 올바르지 않습니다.');
    }

    final count = data['count'];

    if (count is! int || count < 0) {
      throw const FormatException('부스 개수가 올바르지 않습니다.');
    }

    return count;
  } finally {
    client.close();
  }
}
