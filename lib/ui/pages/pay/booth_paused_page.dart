import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/seoul_time.dart';
import '../../../data/models/booth.dart';
import '../../../data/models/payment_exception.dart';
import '../../components/buttons/buttons.dart';
import '../../components/feedback/feedback.dart';
import 'widgets/pay_parts.dart';

/// 주문을 받지 않는 부스 안내에 필요한 값 (409 `ORDERING_PAUSED` · `BOOTH_CLOSED`).
class BoothPauseNotice {
  const BoothPauseNotice({
    required this.closed,
    required this.message,
    this.boothId,
    this.boothName,
    this.pausedAt,
    this.fromPayment = false,
  });

  /// [error] 가 이 화면으로 보낼 에러인지 (`ORDERING_PAUSED` · `BOOTH_CLOSED`)
  static bool handles(PaymentException error) =>
      error.code == PaymentErrorCode.orderingPaused ||
      error.code == PaymentErrorCode.boothClosed;

  /// 서버 에러에서 만듭니다. 응답에 부스가 없으면 [booth] (이미 읽은 QR 정보)를 씁니다.
  factory BoothPauseNotice.fromError(
    PaymentException error, {
    Booth? booth,
    bool fromPayment = false,
  }) {
    final paused = error.orderingPaused;
    return BoothPauseNotice(
      closed: error.code == PaymentErrorCode.boothClosed,
      message: error.message,
      boothId: paused?.booth?.id ?? booth?.id,
      boothName: paused?.booth?.name ?? booth?.name,
      pausedAt: paused?.pausedAt,
      fromPayment: fromPayment,
    );
  }

  /// true 면 운영 시간 밖 · 마감 (`BOOTH_CLOSED`), false 면 주문 정지 (`ORDERING_PAUSED`)
  final bool closed;

  /// 서버 안내 문구 (운영 시간 밖일 때 그대로 보여 줌)
  final String message;
  final int? boothId;
  final String? boothName;
  final DateTime? pausedAt;

  /// 결제하기를 누른 뒤에 왔으면 "크레딧은 빠져나가지 않았어요" 를 함께 보여 줍니다.
  final bool fromPayment;

  /// `14:05부터 주문을 멈췄어요` 또는 서버 문구
  String get description {
    if (!closed && pausedAt != null) {
      return '${seoulHourMinute(pausedAt!)}부터 주문을 멈췄어요';
    }
    return message;
  }
}

/// APP-63 주문을 멈춘 · 운영 시간이 아닌 부스 안내.
///
/// QR 을 읽을 때(`GET /pay/qr`)나 결제할 때(`POST /payments`) 409 를 받으면 옵니다.
/// 캔버스가 없어 결제 실패 화면(QRFail)과 같은 부품으로 만들었습니다.
class BoothPausedPage extends StatelessWidget {
  const BoothPausedPage({super.key, required this.notice});

  final BoothPauseNotice notice;

  void _rescan(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.pay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boothId = notice.boothId;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
              child: IconButton(
                tooltip: '닫기',
                color: AppColors.foreground,
                icon: const Icon(Icons.close),
                onPressed: () => context.go(Routes.home),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  children: [
                    PayResultHeading(
                      title: notice.boothName ?? '주문할 수 없는 부스예요',
                      description: notice.description,
                      icon: notice.closed
                          ? Icons.schedule_rounded
                          : Icons.pause_rounded,
                      tone: PayResultTone.neutral,
                    ),
                    if (notice.fromPayment)
                      const AppNotice(
                        '크레딧은 빠져나가지 않았어요',
                        icon: Icons.check_circle,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomCTA(
        buttons: [
          AppButton(
            '다시 스캔',
            variant: AppButtonVariant.light,
            onPressed: () => _rescan(context),
          ),
          if (boothId != null)
            AppButton(
              '부스 보기',
              onPressed: () => context.push(Routes.boothDetail('$boothId')),
            ),
        ],
      ),
    );
  }
}
