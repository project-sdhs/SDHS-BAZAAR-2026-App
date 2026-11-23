import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/payment_models.dart';
import '../../../state/credit_store.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';

class PayPage extends StatefulWidget {
  const PayPage({super.key});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final _frameKey = GlobalKey();
  final _cameraKey = GlobalKey();
  Rect? _scanWindow;

  void _updateScanWindow() {
    final frame = _frameKey.currentContext?.findRenderObject();
    final camera = _cameraKey.currentContext?.findRenderObject();
    if (frame is! RenderBox || camera is! RenderBox || !mounted) return;
    final origin = camera.globalToLocal(frame.localToGlobal(Offset.zero));
    final window = origin & frame.size;
    if (_scanWindow != window) setState(() => _scanWindow = window);
  }

  bool _cameraEnabled = false;
  bool _opening = false;
  String? _error;

  Future<void> _openQr(String value) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _cameraEnabled = false;
      _error = null;
    });
    try {
      final booth = await context.read<CreditStore>().resolveQr(value);
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      await context.push(Routes.checkout, extra: booth);
    } on PaymentException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'QR 정보를 불러오지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final active = TickerMode.valuesOf(context).enabled;
    if (_cameraEnabled && active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScanWindow());
    }
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      body: Stack(
        children: [
          if (_cameraEnabled && active)
            Positioned.fill(
              child: _QrCamera(
                key: _cameraKey,
                scanWindow: _scanWindow,
                onDetect: _openQr,
                onError: (message) => setState(() {
                  _cameraEnabled = false;
                  _error = message;
                }),
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
                                        onPressed: _opening
                                            ? null
                                            : () => setState(() {
                                                _cameraEnabled = true;
                                                _error = null;
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
                          if (_error case final error?) ...[
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  AppCreditAmount(
                                    amount: store.balance,
                                    type: CreditAmountType.frame,
                                  ),
                                ],
                              ),
                            ),
                            AppButton(
                              '충전하기',
                              size: AppButtonSize.medium,
                              variant: AppButtonVariant.weakPrimary,
                              onPressed: () {
                                setState(() => _cameraEnabled = false);
                                context.push(Routes.credit);
                              },
                            ),
                          ],
                        ),
                        if (store.isPreview) ...[
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            '디자인 미리보기 · 예시 데이터',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          AppButton(
                            '예시 QR로 화면 보기',
                            key: const Key('previewQr'),
                            expand: true,
                            variant: AppButtonVariant.light,
                            onPressed: _opening
                                ? null
                                : () => _openQr('K7Q2M9X4TB'),
                          ),
                        ],
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

class _QrCamera extends StatefulWidget {
  const _QrCamera({
    super.key,
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

class _QrCameraState extends State<_QrCamera> {
  bool _errorReported = false;
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);

  @override
  void dispose() {
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
