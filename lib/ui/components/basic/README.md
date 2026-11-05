# APP-08 공통 위젯

원본: [피그마 디자인 시스템](https://www.figma.com/design/UnwiPd7CEeOUAB27lTqpEu?node-id=0-1).
버튼과 컨트롤 / 내비게이션과 검색 / 카드·배지·피드백 보드를 참고합니다.
기존 AppColors와 Pretendard를 사용하고 그림자를 추가하지 않습니다.
카테고리 타일은 48px / radius 14px / icon 24px입니다.
원본의 모션 미정 안내에 따라 스켈레톤은 정적으로 표시합니다.

```dart
import 'package:bazaar_app/ui/components/basic/basic.dart';

AppChip('1학년', selected: grade == 1, onSelected: (_) => setState(() => grade = 1))
AppSegmentedControl<String>(items: const {'grade': '학년 순', 'popular': '인기 순'}, value: sort, onChanged: (v) => setState(() => sort = v))
const AppBadge('캐셔', variant: AppBadgeVariant.weak)
const AppAvatar(name: '이재원', highlighted: true)
const AppCategoryTile(icon: Icons.ramen_dining, label: '분식')
AppListRow(title: '거래 내역', subtitle: '충전 · 구매 기록', onTap: openHistory)
AppToggle(label: '주문 알림 받기', value: enabled, onChanged: updateEnabled)
const AppSkeletonList(itemCount: 3)
```

- 선택 값은 부모가 관리합니다. 콜백이 null이면 칩·세그먼트·스위치를 변경할 수 없습니다.
- AppBadge는 상태 표시이며 탭 동작이 없습니다.
- AppListRow의 trailing에는 금액, 배지, 스위치 등을 넣을 수 있습니다.
- AppAvatar는 사진을 받지 않으며 이름 첫 글자(유니코드 문자 단위)를 표시합니다.
- 개발용 `/dev/basics`에서 종류와 동작을 확인합니다. 실제 앱의 로그인·결제·서버 처리는 포함하지 않습니다.
