# inputs

값을 입력받는 공통 위젯 (APP-09).

- `AppTextField`: box, line, big, hero 유형과 오류·비활성 상태
- `AppSearchField`: 검색 입력, 입력 지우기
- `inputs.dart` 하나만 import 하면 됩니다.

```dart
import 'package:bazaar_app/ui/components/inputs/inputs.dart';

AppTextField(
  hintText: '이름을 입력하세요',
  errorText: errorMessage,
  onChanged: handleChanged,
)

AppSearchField(
  hintText: '반 · 부스 · 메뉴 검색',
  onChanged: search,
)
```
