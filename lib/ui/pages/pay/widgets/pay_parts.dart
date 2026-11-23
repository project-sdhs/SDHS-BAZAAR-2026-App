import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/booth.dart';
import '../../../components/credit_amount/credit_amounts.dart';

// QR 결제 화면들이 함께 쓰는 조각 (결과 제목 · 부스 줄 · 금액 줄 · 회색 카드).

/// 결과 화면 맨 위의 동그란 아이콘 + 제목 + 설명 (QRDone · QRFail 캔버스).
class PayResultHeading extends StatelessWidget {
  const PayResultHeading({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.check,
    this.tone = PayResultTone.success,
  });

  final String title;
  final String description;
  final IconData icon;
  final PayResultTone tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s24),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.background,
            ),
            child: Icon(icon, color: tone.foreground, size: 32),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(
              fontSize: 26,
              height: 39 / 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.body),
          ),
        ],
      ),
    ),
  );
}

enum PayResultTone {
  success(background: AppColors.primary, foreground: AppColors.onPrimary),
  danger(background: AppColors.dangerWeak, foreground: AppColors.danger),
  neutral(background: AppColors.surface, foreground: AppColors.body);

  const PayResultTone({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// 부스 사진(없으면 가게 아이콘) + 이름 + `2학년 3반 · 신관 2층 복도`.
class PayBoothHeader extends StatelessWidget {
  const PayBoothHeader({
    super.key,
    required this.name,
    this.caption,
    this.imageUrl,
  });

  /// [Booth] 의 반 이름 · 위치로 만듭니다.
  factory PayBoothHeader.of(Booth booth, {String? imageUrl}) => PayBoothHeader(
    name: booth.name,
    caption: [booth.boothClass?.name, booth.locationLabel].nonNulls.join(' · '),
    imageUrl: imageUrl,
  );

  final String name;
  final String? caption;

  /// 전체 주소. null 이면 아이콘을 보여 줍니다.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = _IconTile();
    final caption = this.caption;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 44,
            child: imageUrl == null
                ? fallback
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => fallback,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.body.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (caption != null && caption.isNotEmpty)
                Text(
                  caption,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.weakBackground,
    child: Center(
      child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
    ),
  );
}

/// 왼쪽 이름 · 오른쪽 크레딧 금액 한 줄 (영수증 · 결제 요약).
class PayAmountRow extends StatelessWidget {
  const PayAmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.bold = false,
    this.tone = CreditAmountTone.secondary,
  });

  final String label;
  final int amount;
  final bool bold;
  final CreditAmountTone tone;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: tone.color,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.s8),
      Flexible(
        child: Align(
          alignment: Alignment.centerRight,
          child: AppCreditAmount(
            amount: amount,
            type: CreditAmountType.body,
            tone: tone,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

/// 회색 둥근 카드 (padding 20, radius 20).
class PayCard extends StatelessWidget {
  const PayCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}
