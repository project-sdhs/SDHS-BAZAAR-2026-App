import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'data/api/api_client.dart';
import 'data/repositories/booth_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/recent_search_store.dart';
import 'state/credit_store.dart';
import 'state/recent_search_state.dart';

/// 앱 전체에서 한 번만 만들어 여러 화면이 함께 쓰는 상태.
///
/// 화면 안에서 만들면 화면을 닫을 때마다 사라지므로 여기서 만듭니다.
class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.child,
    this.recentSearchStore,
    this.boothRepository,
    this.paymentRepository,
  });

  final Widget child;

  /// 최근 검색어를 저장할 곳. 없으면 앱을 끄면 사라지는 메모리 저장소를 씁니다.
  final RecentSearchStore? recentSearchStore;

  /// 부스 서버 호출. 없으면 `ApiClient` 를 앱에서 하나만 만들어 씁니다(로그인 토큰도 여기 한 곳에 붙임).
  final BoothRepository? boothRepository;

  /// 크레딧 · 충전 · QR 결제 서버 호출. 없으면 서버(`ApiClient`)를 부릅니다.
  /// 테스트 · 미리보기에서만 가짜 저장소를 넘깁니다.
  final PaymentRepository? paymentRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (boothRepository case final repository?)
          Provider<BoothRepository>.value(value: repository)
        else
          Provider<BoothRepository>(
            create: (_) => BoothRepository(ApiClient()),
            dispose: (_, repository) => repository.close(),
          ),
        if (paymentRepository case final repository?)
          Provider<PaymentRepository>.value(value: repository)
        else
          Provider<PaymentRepository>(
            create: (_) => PaymentRepository(ApiClient()),
            dispose: (_, repository) => repository.close(),
          ),
        // 내 잔액 · 공개 설정. 처음 쓰는 화면이 열릴 때 서버에서 읽습니다.
        ChangeNotifierProvider<CreditStore>(
          create: (context) =>
              CreditStore(context.read<PaymentRepository>())..load(),
        ),
        ChangeNotifierProvider<RecentSearchState>(
          create: (_) =>
              RecentSearchState(recentSearchStore ?? MemoryRecentSearchStore())
                ..load(),
        ),
      ],
      child: child,
    );
  }
}
