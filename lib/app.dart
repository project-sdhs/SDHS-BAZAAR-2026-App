import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 앱의 뿌리 위젯: 테마와 라우터를 연결합니다.
class BazaarApp extends StatefulWidget {
  const BazaarApp({super.key, this.initialLocation});

  /// 처음 보여줄 경로. 테스트에서 특정 화면부터 시작할 때만 넘깁니다.
  final String? initialLocation;

  @override
  State<BazaarApp> createState() => _BazaarAppState();
}

class _BazaarAppState extends State<BazaarApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '디지텍 바자회',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
