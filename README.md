# SDHS-BAZAAR-2026-App

서울디지텍고등학교 2026 디지텍 바자회 · 학생 앱 (Flutter, iOS + Android).
종이 토큰 대신 크레딧으로 충전하고 부스에서 QR로 결제합니다.

## 준비

- Flutter **3.47.1** (stable) / Dart 3.13.1 — `flutter --version` 으로 확인
- 패키지 설치: `flutter pub get`

## 실행

```bash
flutter run
```

서버 주소는 기본 `http://localhost:3000` 입니다. 바꾸려면:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

> Android 에뮬레이터에서 내 PC 의 서버에 붙을 때는 `http://10.0.2.2:3000` 을 씁니다.

## 검사 · 테스트 (PR 올리기 전에 모두 통과해야 합니다)

```bash
dart format .        # 코드 모양 맞추기 (CI 는 바뀌는 게 있으면 실패)
flutter analyze      # 정적 분석
flutter test         # 위젯 · 단위 테스트
```

## 빌드

```bash
flutter build apk --dart-define=API_BASE_URL=<서버 주소>   # Android
flutter build ipa --dart-define=API_BASE_URL=<서버 주소>   # iOS (Mac + Xcode 필요)
```

## 폴더 구조

```
lib/
  main.dart            앱 시작점 (runApp 만)
  app.dart             MaterialApp.router + 테마 연결
  core/
    theme/             디자인 토큰: 컬러 · 타입 · 간격/라디우스 · ThemeData
    router/            go_router 설정 (app_router.dart), 경로 상수 (routes.dart)
    constants/         앱 전체 고정 값
    utils/             작은 도우미 함수
  data/
    api/               ApiClient (http, 서버 주소 · JSON · 에러 처리)
    models/            서버 데이터 클래스 (fromJson / toJson)
    repositories/      ApiClient → model 로 바꿔 주는 저장소
  state/               provider 의 ChangeNotifier 상태
  ui/
    components/
      buttons/         AppButton · BottomCTA (buttons.dart 하나만 import)
    pages/             화면 1개 = 폴더 1개
      onboarding/      온보딩 1페이지 (+ widgets/page_indicator.dart)
      login/           로그인 (임시)
      shell/           하단 탭 5개 틀 (MainShell)
      home/ booths/ pay/ map/ my/   탭 화면 (임시)
      dev/             버튼 카탈로그 (디버그 빌드에서만 /dev/buttons)
test/                  lib/ 와 같은 구조로 테스트를 둡니다
assets/fonts/          Pretendard 폰트 + 라이선스 (OFL.txt)
```

화면 색 · 글자 · 여백은 `core/theme` 의 토큰(`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`)만 씁니다.
`Color(0xFF...)` 를 화면 코드에 직접 쓰지 마세요.

## 화면 이동 · 버튼

- 경로는 `core/router/routes.dart` 의 상수로만 씁니다: `context.go(Routes.login)`
- 앱은 `/onboarding` 에서 시작 → `/login` → 하단 탭(`/home` `/booths` `/pay` `/map` `/my`)
- 버튼은 직접 만들지 말고 `AppButton` 을 씁니다.

```dart
AppButton('결제하기', onPressed: () { ... })
AppButton('취소', size: AppButtonSize.medium, variant: AppButtonVariant.light, onPressed: ...)
AppButton('충전하기', loading: isLoading, expand: true, onPressed: ...)
```

## 브랜치 · PR 규칙

1. 항상 최신 `main` 에서 브랜치를 만듭니다. `main` 에 직접 push 하지 않습니다.
2. 브랜치 이름: `feat/…` (기능), `fix/…` (버그), `chore/…` (설정 · 정리) — 예: `feat/onboarding-page2`
3. 커밋 메시지: [Conventional Commits](https://www.conventionalcommits.org/ko/) — 예: `feat: 온보딩 2페이지 추가`
4. PR 템플릿(무엇을 · 왜 · 확인한 것 · 스크린샷)을 채워서 올립니다.
5. CI 통과 + 리뷰 승인 → **Squash merge**.
