import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

enum CreditAmountType { tile, frame, body, caption }

enum CreditAmountTone {
  normal(Color(0xFF191F28)),
  secondary(Color(0xFF4E5968)),
  muted(Color(0xFF8B95A1)),
  charge(Color(0xFF0171CE)),
  danger(Color(0xFFF42939));

  const CreditAmountTone(this.color);
  final Color color;
}

class CreditAmount extends StatelessWidget {
  const CreditAmount({
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

  String get formattedAmount {
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

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: formattedAmount),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(left: spacing),
              child: SizedBox.square(
                dimension: iconSize,
                child:
                    coin ??
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9D00),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'C',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontSize: iconSize * 0.7,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
      semanticsLabel: '$formattedAmount \uD06C\uB808\uB527',
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: size,
        fontWeight: type == CreditAmountType.caption
            ? FontWeight.w400
            : FontWeight.w700,
        color: color ?? tone.color,
        letterSpacing: type == CreditAmountType.tile
            ? -size * 0.02
            : type == CreditAmountType.frame
            ? -size * 0.01
            : 0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
