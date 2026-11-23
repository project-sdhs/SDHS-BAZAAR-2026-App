import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/booth_detail.dart';
import '../../../components/basic/basic.dart';

class BoothInfoHeader extends StatelessWidget {
  const BoothInfoHeader({super.key, required this.booth});

  static const double imageAspectRatio = 296 / 148;

  final BoothDetail booth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: imageAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            child: _BoothImage(imageUrl: booth.imageUrl),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          spacing: AppSpacing.s6,
          children: [
            AppBadge(booth.className),
            AppBadge(
              booth.isOpen ? '운영 중' : '운영 종료',
              variant: booth.isOpen
                  ? AppBadgeVariant.weak
                  : AppBadgeVariant.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          booth.name,
          style: AppTypography.h3.copyWith(
            fontSize: 26,
            letterSpacing: 26 * -0.02,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          spacing: AppSpacing.s6,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.muted,
            ),
            Expanded(
              child: Text(
                '${booth.location} · ${booth.openHours}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BoothImage extends StatelessWidget {
  const _BoothImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const _ImagePlaceholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.placeholder,
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 48,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
