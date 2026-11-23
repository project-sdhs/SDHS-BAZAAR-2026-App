import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/booth_detail.dart';
import '../../../components/basic/basic.dart';

class BoothOperatorSection extends StatelessWidget {
  const BoothOperatorSection({super.key, required this.operators});

  final List<BoothOperator> operators;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '부스 운영진',
          style: AppTypography.body.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        for (final operator in operators) BoothOperatorTile(operator: operator),
      ],
    );
  }
}

class BoothOperatorTile extends StatelessWidget {
  const BoothOperatorTile({super.key, required this.operator});

  static const double avatarSize = 44;

  final BoothOperator operator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        spacing: AppSpacing.s16,
        children: [
          AppAvatar(name: operator.name, size: avatarSize, highlighted: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operator.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (operator.role.isNotEmpty)
                  Text(
                    operator.role,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
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
