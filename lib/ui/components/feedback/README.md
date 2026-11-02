# feedback

사용자에게 상태를 알려 주는 공통 위젯 (APP-09).

- `AppEmptyState`: 결과가 없거나 표시할 항목이 없는 상태
- `AppToast.show`: 성공·오류 토스트
- `AppDialog.show`: 확인·취소 다이얼로그
- `AppBottomSheet.show`: 공통 모양의 모달 바텀시트
- `feedback.dart` 하나만 import 하면 됩니다.
- 각 `show` 메서드의 이름 있는 파라미터가 메시지, 버튼 문구, 상태, 표시 시간을 지정합니다.
- 오류 토스트는 `AppToastType.error`로 선택하며 연한 빨강 배경과 빨간 글자·아이콘을 사용합니다.

```dart
import 'package:bazaar_app/ui/components/feedback/feedback.dart';

AppToast.show(context, message: '저장됐어요');
final confirmed = await AppDialog.show(
  context,
  title: '권한을 줄까요?',
  message: '학생이 결제를 받을 수 있게 돼요.',
);
```
