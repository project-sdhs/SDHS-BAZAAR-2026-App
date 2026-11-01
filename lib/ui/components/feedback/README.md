# feedback

사용자에게 상태를 알려 주는 공통 위젯 (APP-09).

- `AppEmptyState`: 결과가 없거나 표시할 항목이 없는 상태
- `AppToast.show`: 성공·오류 토스트
- `AppDialog.show`: 확인·취소 다이얼로그
- `AppBottomSheet.show`: 공통 모양의 모달 바텀시트
- `feedback.dart` 하나만 import 하면 됩니다.

```dart
import 'package:bazaar_app/ui/components/feedback/feedback.dart';

AppToast.show(context, message: '저장됐어요');
final confirmed = await AppDialog.show(
  context,
  title: '권한을 줄까요?',
  message: '학생이 결제를 받을 수 있게 돼요.',
);
```
