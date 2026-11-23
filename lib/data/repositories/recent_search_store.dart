/// 최근 검색어를 기기에 보관하는 곳.
///
/// 지금은 앱을 끄면 사라지는 [MemoryRecentSearchStore] 만 있습니다.
/// 기기에 영구 저장하려면 이 인터페이스를 구현한 저장소를 추가합니다.
abstract interface class RecentSearchStore {
  Future<List<String>> load();
  Future<void> save(List<String> keywords);
}

class MemoryRecentSearchStore implements RecentSearchStore {
  MemoryRecentSearchStore([List<String> initial = const []])
    : _keywords = [...initial];

  List<String> _keywords;

  @override
  Future<List<String>> load() async => [..._keywords];

  @override
  Future<void> save(List<String> keywords) async => _keywords = [...keywords];
}
