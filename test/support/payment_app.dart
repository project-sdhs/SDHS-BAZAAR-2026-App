import 'package:bazaar_app/app_providers.dart';
import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/state/credit_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_payment_repository.dart';
import 'payment_fixtures.dart';

/// 실제 라우터로 [initialLocation] 부터 앱을 띄웁니다. 서버 대신 [repository] 를 쓰고,
/// 날짜 계산이 흔들리지 않도록 시계를 [now] (기본: 바자회 첫날)로 고정한 CreditStore 를 씁니다.
Future<CreditStore> pumpPaymentApp(
  WidgetTester tester, {
  required String initialLocation,
  FakePaymentRepository? repository,
  DateTime? now,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repo = repository ?? FakePaymentRepository();
  final store = CreditStore(repo, clock: () => now ?? eventDay)..load();
  addTearDown(store.dispose);
  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    AppProviders(
      paymentRepository: repo,
      // AppProviders 가 만드는 CreditStore 대신 시계를 고정한 것을 씁니다.
      child: ChangeNotifierProvider<CreditStore>.value(
        value: store,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return store;
}
