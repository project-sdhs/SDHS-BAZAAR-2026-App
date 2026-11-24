import 'package:bazaar_app/app_providers.dart';
import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/data/models/qr_pay.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'preview_payment_repository.dart';

/// 충전 · 거래 내역 · QR 결제 미리보기 (서버 없이 예시 데이터).
/// flutter run -t tool/preview_payments.dart
///
/// 카메라가 없는 시뮬레이터에서도 결제 화면을 볼 수 있게 오른쪽 아래 "예시 QR" 버튼을 둡니다.
void main() => runApp(const _PreviewPaymentsApp());

class _PreviewPaymentsApp extends StatefulWidget {
  const _PreviewPaymentsApp();

  @override
  State<_PreviewPaymentsApp> createState() => _PreviewPaymentsAppState();
}

class _PreviewPaymentsAppState extends State<_PreviewPaymentsApp> {
  /// 부스에 붙는 QR 과 같은 모양의 예시 값
  static final _sampleQr = QrPayload.parse(
    'https://bazaar.example.com/q/${PreviewPaymentRepository.qrCode}?src=board',
  );

  final _repository = PreviewPaymentRepository();
  late final GoRouter _router = createAppRouter(initialLocation: Routes.my);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  Future<void> _openSampleQr() async {
    final info = await _repository.qrPayInfo(
      _sampleQr.code,
      source: _sampleQr.source,
    );
    await _router.push(Routes.checkout, extra: info);
  }

  @override
  Widget build(BuildContext context) => AppProviders(
    paymentRepository: _repository,
    child: MaterialApp.router(
      title: '디지텍 바자회 (미리보기)',
      theme: AppTheme.light,
      routerConfig: _router,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned(
            right: 16,
            bottom: 96,
            child: SafeArea(
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: _openSampleQr,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('예시 QR'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
