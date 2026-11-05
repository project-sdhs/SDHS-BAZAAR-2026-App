# inputs

값을 입력받는 공통 위젯 (APP-09).

- `AppTextField`: `variant`로 기본(box), 밑줄(line), 여백 확장(big), 강조 금액(hero) 모양을 선택합니다.
- `label`, `hintText`, `errorText`, `enabled`가 라벨·안내·오류·비활성 상태를 지정합니다.
- `borderRadius`는 둥근 필드 모서리를 지정하며, 기본값은 14px입니다.
- `AppSearchField`: `AppTextField`를 재사용하는 검색 입력입니다. 검색 아이콘·16px 모서리·원형 지우기 버튼을 제공합니다.
- `inputs.dart` 하나만 import 하면 됩니다.

```dart
import 'package:bazaar_app/ui/components/inputs/inputs.dart';

AppTextField(
  label: '학번',
  hintText: '이름을 입력하세요',
  variant: AppTextFieldVariant.box,
  errorText: errorMessage,
  onChanged: handleChanged,
)

AppSearchField(
  label: '부스 검색',
  hintText: '반 · 부스 · 메뉴 검색',
  onChanged: search,
)
```
