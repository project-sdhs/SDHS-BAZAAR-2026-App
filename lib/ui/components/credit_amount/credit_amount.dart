import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum CreditAmountType { tile, frame, body, caption }

enum CreditAmountTone {
  normal(AppColors.foreground),
  secondary(AppColors.body),
  muted(AppColors.muted),
  charge(AppColors.primary),
  danger(AppColors.danger);

  const CreditAmountTone(this.color);
  final Color color;
}

class AppCreditAmount extends StatelessWidget {
  const AppCreditAmount({
    super.key,
    required this.amount,
    this.type = CreditAmountType.body,
    this.tone = CreditAmountTone.normal,
    this.fontSize,
    this.coinSize,
    this.gap,
    this.showPlus = false,
    this.color,
    this.coin,
    this.fontWeight,
    this.prefix = '',
    this.suffix = '',
    this.showCoin = true,
    this.soldOut = false,
  }) : assert(fontSize == null || fontSize > 0),
       assert(coinSize == null || coinSize > 0),
       assert(gap == null || gap >= 0);

  final int amount;
  final CreditAmountType type;
  final CreditAmountTone tone;
  final double? fontSize;
  final double? coinSize;
  final double? gap;
  final bool showPlus;
  final Color? color;
  final Widget? coin;

  final FontWeight? fontWeight;
  final String prefix;
  final String suffix;
  final bool showCoin;

  /// 품절 상태일 때만 코인을 40%로 흐리게 표시합니다.
  final bool soldOut;

  String get formattedAmount => format(amount, showPlus: showPlus);

  static String format(int amount, {bool showPlus = false}) {
    final digits = amount.abs().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final sign = amount < 0
        ? '\u2212'
        : showPlus && amount > 0
        ? '+'
        : '';
    return '$sign$digits';
  }

  @override
  Widget build(BuildContext context) {
    final size =
        fontSize ??
        switch (type) {
          CreditAmountType.tile => 34.0,
          CreditAmountType.frame => 24.0,
          CreditAmountType.body => 15.0,
          CreditAmountType.caption => 14.0,
        };

    final iconSize =
        coinSize ??
        switch (type) {
          CreditAmountType.tile => 24.0,
          CreditAmountType.frame => 18.0,
          CreditAmountType.body => size * 0.62,
          CreditAmountType.caption => size * 0.82,
        };

    final spacing =
        gap ??
        switch (type) {
          CreditAmountType.tile => 10.0,
          CreditAmountType.frame => 8.0,
          CreditAmountType.body => size * 0.16,
          CreditAmountType.caption => size * 0.14,
        };

    final amountStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight:
          fontWeight ??
          (type == CreditAmountType.caption
              ? FontWeight.w400
              : FontWeight.w700),
      color: color ?? tone.color,
      letterSpacing: switch (type) {
        CreditAmountType.tile => -size * 0.02,
        CreditAmountType.frame => -size * 0.01,
        _ => 0,
      },
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final formatted = formattedAmount;
    return Semantics(
      label: '$prefix$formatted 크레딧$suffix',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: amountStyle,
          children: [
            if (prefix.isNotEmpty) TextSpan(text: prefix),
            TextSpan(text: formatted),
            if (showCoin)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: spacing,
                    right: suffix.isEmpty ? 0 : size * 0.1,
                  ),
                  child: SizedBox.square(
                    dimension: iconSize,
                    child: Opacity(
                      opacity: soldOut ? 0.4 : 1,
                      child:
                          coin ?? Image.asset('assets/images/credit_coin.png'),
                    ),
                  ),
                ),
              ),
            if (suffix.isNotEmpty) TextSpan(text: suffix),
          ],
        ),
      ),
    );
  }
}
