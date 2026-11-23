import 'package:flutter/foundation.dart';

import '../data/repositories/recent_search_store.dart';

/// 최근 검색어 목록 (최신이 맨 앞).
///
/// 같은 검색어는 한 번만 남기고 맨 앞으로 옮기며, [maxCount] 개까지만 보관합니다.
class RecentSearchState extends ChangeNotifier {
  RecentSearchState(this._store, {this.maxCount = 10});

  final RecentSearchStore _store;
  final int maxCount;

  List<String> _keywords = const [];
  bool _disposed = false;
  List<String> get keywords => _keywords;

  Future<void> load() async {
    final loaded = await _store.load();
    if (_disposed) return;
    _keywords = loaded;
    notifyListeners();
  }

  Future<void> add(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    await _update(
      [
        trimmed,
        ..._keywords.where((item) => item != trimmed),
      ].take(maxCount).toList(),
    );
  }

  Future<void> remove(String keyword) =>
      _update(_keywords.where((item) => item != keyword).toList());

  Future<void> clear() => _update(const []);

  Future<void> _update(List<String> next) async {
    await _store.save(next);
    // 저장하는 사이에 화면이 닫혔으면 알리지 않습니다.
    if (_disposed) return;
    _keywords = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
