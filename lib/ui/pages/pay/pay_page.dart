import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/payment_exception.dart';
import '../../../data/models/qr_pay.dart';
import '../../../state/credit_store.dart';
import '../../components/basic/basic.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';
import '../../components/feedback/feedback.dart';
import 'booth_paused_page.dart';

/// 카메라 대신 쓸 스캐너를 만드는 함수 (테스트용). 읽은 QR 값을 [onDetect] 로 넘깁니다.
typedef QrScannerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onDetect,
);

/// QR 결제 탭 (APP-58~59): 부스 QR 을 읽어 결제 화면(`Routes.checkout`)을 엽니다.
class PayPage extends StatefulWidget {
  const PayPage({super.key});

  /// 테스트에서 카메라 대신 쓸 스캐너. 테스트가 끝나면 null 로 되돌립니다.
  @visibleForTesting
  static QrScannerBuilder? debugScannerOverride;

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  /// 같은 QR 을 이 시간 안에 다시 읽으면 무시합니다 (카메라는 초당 여러 번 읽음).
  static const _sameQrWindow = Duration(seconds: 3);

  final _frameKey = GlobalKey();
  final _cameraKey = GlobalKey();
  Rect? _scanWindow;

  /// 사용자가 카메라를 켰는지. 결제 화면이 위를 덮으면 카메라만 잠깐 내려가고, 돌아오면 다시 켜집니다.
  bool _cameraEnabled = false;
  bool _opening = false;
  String? _cameraError;
  String? _lastRaw;
  DateTime? _lastRawAt;

  void _updateScanWindow() {
    final frame = _frameKey.currentContext?.findRenderObject();
    final camera = _cameraKey.currentContext?.findRenderObject();
    if (frame is! RenderBox || camera is! RenderBox || !mounted) return;
    final origin = camera.globalToLocal(frame.localToGlobal(Offset.zero));
    final window = origin & frame.size;
    if (_scanWindow != window) setState(() => _scanWindow = window);
  }

  void _onDetect(String raw) {
    final now = DateTime.now();
    if (raw == _lastRaw &&
        _lastRawAt != null &&
        now.difference(_lastRawAt!) < _sameQrWindow) {
      return;
    }
    _lastRaw = raw;
    _lastRawAt = now;
    unawaited(_openQr(raw));
  }

  Future<void> _openQr(String raw) async {
    if (_opening) return;
    final payload = QrPayload.tryParse(raw);
    if (payload == null) {
      _toast('바자회 부스 QR이 아니에요. 부스에 붙은 QR을 비춰 주세요');
      return;
    }
    setState(() => _opening = true);
    try {
      final info = await context.read<CreditStore>().qrPayInfo(payload);
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      // 결제 화면이 덮는 동안 카메라는 내려가고, 돌아오면(다시 스캔 · 뒤로) 다시 켜집니다.
      unawaited(context.push(Routes.checkout, extra: info));
    } on PaymentException catch (error) {
      if (!mounted) return;
      if (BoothPauseNotice.handles(error)) {
        unawaited(
          context.push(
            Routes.payPaused,
            extra: BoothPauseNotice.fromError(error),
          ),
        );
      } else if (error.code == PaymentErrorCode.rateLimited) {
        final seconds = error.retryAfter?.inSeconds;
        _toast(
          seconds == null
              ? '요청이 많아요. 잠시 뒤 다시 비춰 주세요'
              : '요청이 많아요. $seconds초 뒤 다시 비춰 주세요',
        );
      } else {
        // QR_INVALID 등: 안내만 하고 계속 스캔합니다.
        _toast(error.message);
      }
    } on ApiNetworkException {
      _toast('QR 정보를 불러오지 못했어요. 인터넷 연결을 확인해 주세요');
    } catch (_) {
      _toast('QR 정보를 불러오지 못했어요. 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    AppToast.show(context, message: message, type: AppToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final active = TickerMode.valuesOf(context).enabled;
    final showCamera = _cameraEnabled && active;
    if (showCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScanWindow());
    }
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      body: Stack(
        children: [
          if (showCamera)
            Positioned.fill(
              child: KeyedSubtree(
                key: _cameraKey,
                child:
                    PayPage.debugScannerOverride?.call(context, _onDetect) ??
                    _QrCamera(
                      scanWindow: _scanWindow,
                      onDetect: _onDetect,
                      onError: (message) => setState(() {
                        _cameraEnabled = false;
                        _cameraError = message;
                      }),
                    ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: '결제 화면 닫기',
                    color: AppColors.onPrimary,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _cameraEnabled = false);
                      context.go(Routes.home);
                    },
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s24),
                      child: Column(
                        children: [
                          Container(
                            key: _frameKey,
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.onPrimary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.r16,
                              ),
                            ),
                            child: _cameraEnabled
                                ? null
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 72,
                                        color: AppColors.onPrimary,
                                      ),
                                      const SizedBox(height: AppSpacing.s24),
                                      AppButton(
                                        '카메라 켜기',
                                        onPressed: () => setState(() {
                                          _cameraEnabled = true;
                                          _cameraError = null;
                                        }),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.s32),
                          Text(
                            '부스 QR을 네모 안에 맞춰주세요',
                            textAlign: TextAlign.center,
                            style: AppTypography.h4.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            '인식되면 바로 결제 화면이 열려요',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                          if (_opening) ...[
                            const SizedBox(height: AppSpacing.s24),
                            const CircularProgressIndicator(
                              color: AppColors.onPrimary,
                            ),
                          ],
                          if (_cameraError case final error?) ...[
                            const SizedBox(height: AppSpacing.s16),
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '보유 크레딧',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s4),
                              _Balance(store: store),
                            ],
                          ),
                        ),
                        AppButton(
                          '충전하기',
                          size: AppButtonSize.medium,
                          variant: AppButtonVariant.weakPrimary,
                          onPressed: () => context.push(Routes.credit),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 보유 크레딧: 읽는 중이면 자리 표시, 못 읽었으면 다시 시도 버튼.
class _Balance extends StatelessWidget {
  const _Balance({required this.store});

  final CreditStore store;

  @override
  Widget build(BuildContext context) {
    if (store.hasBalance) {
      return AppCreditAmount(
        amount: store.balance,
        type: CreditAmountType.frame,
      );
    }
    if (store.isLoading) {
      return const AppSkeleton(width: 120, height: 30, radius: 8);
    }
    return Row(
      children: [
        Flexible(
          child: Text(
            '잔액을 불러오지 못했어요',
            style: AppTypography.bodySmall.copyWith(color: AppColors.body),
          ),
        ),
        IconButton(
          tooltip: '잔액 다시 불러오기',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppColors.muted,
          onPressed: store.refresh,
        ),
      ],
    );
  }
}

class _QrCamera extends StatefulWidget {
  const _QrCamera({
    required this.onDetect,
    required this.onError,
    this.scanWindow,
  });
  final Rect? scanWindow;
  final ValueChanged<String> onDetect;
  final ValueChanged<String> onError;

  @override
  State<_QrCamera> createState() => _QrCameraState();
}

/// 앱이 뒤로 가면 카메라를 멈추고, 돌아오면 (권한이 있을 때만) 다시 켭니다.
class _QrCameraState extends State<_QrCamera> with WidgetsBindingObserver {
  bool _errorReported = false;
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 권한 창이 떠도 inactive 가 오므로, 권한이 없으면 건드리지 않습니다.
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(_run(_controller.stop));
      case AppLifecycleState.resumed:
        unawaited(_run(_controller.start));
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on MobileScannerException {
      // 이미 멈춤 · 켜짐이거나 해제된 카메라면 다음 상태에서 다시 맞춥니다.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      MobileScanner(
        controller: _controller,
        scanWindow: widget.scanWindow,
        onDetect: (capture) {
          final value = capture.barcodes.firstOrNull?.rawValue;
          if (value != null) widget.onDetect(value);
        },
        errorBuilder: (context, error) {
          if (!_errorReported) {
            _errorReported = true;
            final message =
                error.errorCode == MobileScannerErrorCode.permissionDenied
                ? '카메라 권한을 허용해 주세요. 기기 설정에서 권한을 바꾼 뒤 카메라를 다시 켤 수 있어요.'
                : '카메라를 사용할 수 없어요. 카메라 연결을 확인한 뒤 다시 켜 주세요.';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onError(message);
            });
          }
          return const SizedBox.shrink();
        },
      ),
      SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) => IconButton(
              tooltip: state.torchState == TorchState.on ? '손전등 끄기' : '손전등 켜기',
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flashlight_on
                    : Icons.flashlight_off,
              ),
              color: AppColors.onPrimary,
              onPressed: state.torchState == TorchState.unavailable
                  ? null
                  : () async {
                      try {
                        await _controller.toggleTorch();
                      } on MobileScannerException {
                        // 사용 중 카메라가 해제되면 컨트롤러의 다음 상태에 반영됩니다.
                      }
                    },
            ),
          ),
        ),
      ),
    ],
  );
}
