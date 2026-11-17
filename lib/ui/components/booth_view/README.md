# booth_view

부스 카드 위젯 (APP-11). `booth_views.dart` 하나만 import 하면 됩니다.

- `BoothView`: 썸네일 위에 흐린 어두운 정보 띠(이름 · 최소 가격 · 분류 · 위치 · 주문 수)를 올립니다.
- `size` 로 자리별 크기를 고릅니다.
  - `BoothViewSize.home` 264×180 — 홈 가로 스크롤
  - `BoothViewSize.map` 264×176 — 지도 바텀시트 가로 스크롤
  - `BoothViewSize.list` 가득×176 — 부스 목록 (기본값)
- `rank` 를 주면 왼쪽 위에 원형 순위 배지가 나타납니다. 주지 않으면 숨깁니다.
- `thumbnail` 이 없거나 불러오지 못하면 `fallbackColor` 로 배경을 채웁니다.
- `orderCount` 가 null 이면 `주문 N` 을 숨깁니다.

```dart
import 'package:bazaar_app/ui/components/booth_view/booth_views.dart';

BoothView(
  name: '3-1 로제떡볶이',
  category: '분식',
  locationLabel: '본관 1층 로비',
  minPrice: 1500,
  orderCount: 128,
  rank: 1,
  size: BoothViewSize.home,
  thumbnail: NetworkImage(imageUrl),
  onTap: openDetail,
)
```

디버그 빌드에서는 `/dev/booth-view` 카탈로그로 세 가지 크기를 볼 수 있습니다.
