import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'data/repositories/recent_search_store.dart';
import 'state/recent_search_state.dart';

/// 앱 전체에서 한 번만 만들어 여러 화면이 함께 쓰는 상태.
///
/// 화면 안에서 만들면 화면을 닫을 때마다 사라지므로 여기서 만듭니다.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child, this.recentSearchStore});

  final Widget child;

  /// 최근 검색어를 저장할 곳. 없으면 앱을 끄면 사라지는 메모리 저장소를 씁니다.
  final RecentSearchStore? recentSearchStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
