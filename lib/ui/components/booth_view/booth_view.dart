import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../credit_amount/credit_amount.dart';

/// 부스 카드가 쓰이는 자리별 크기 (Figma 홈 · 부스 목록 · 지도 화면).
///
/// | 크기   | 너비 | 높이 | 쓰는 곳 |
/// |--------|------|------|---------|
/// | home   | 264  | 180  | 홈 가로 스크롤 (지금 붐비는 부스 · 선생님 특별 부스) |
/// | map    | 264  | 176  | 지도 바텀시트 가로 스크롤 |
/// | list   | 가득 | 176  | 부스 목록 (한 줄에 한 장) |
enum BoothViewSize {
  home(width: 264, height: 180),
  map(width: 264, height: 176),
  list(width: null, height: 176);

  const BoothViewSize({required this.width, required this.height});

  /// 고정 너비. null 이면 부모 너비를 가득 채웁니다.
  final double? width;
  final double height;
}

/// 부스 카드 (APP-11): 썸네일 위에 흐린 어두운 정보 띠와 원형 순위 배지를 올립니다.
///
/// 정보 띠에는 부스 이름 · 최소 가격(오른쪽) 과 분류 배지 · 위치 · 주문 수가 들어갑니다.
/// [rank] 를 주면 왼쪽 위에 순위 배지가 나타납니다.
class BoothView extends StatelessWidget {
  const BoothView({
    super.key,
    required this.name,
    required this.category,
    this.locationLabel,
    this.minPrice,
    this.size = BoothViewSize.list,
    this.thumbnail,
    this.trailingLabel,
    this.rank,
    this.onTap,
    this.fallbackColor = AppColors.body,
  }) : assert(rank == null || rank > 0),
       assert(minPrice == null || minPrice >= 0);

  /// 부스 이름. 한 줄을 넘으면 `…` 로 줄입니다.
  final String name;

  /// 분류 배지에 적을 글자 (예: `간식`)
  final String category;

  /// 위치 (예: `신관 2층 복도`). null 이면(위치 미정) 그 자리를 비웁니다.
  final String? locationLabel;

  /// 메뉴 중 가장 싼 가격 (크레딧). `1,000~` 처럼 보입니다.
  /// null 이면(판매 중인 메뉴가 없음) 가격을 숨깁니다.
  final int? minPrice;
  final BoothViewSize size;

  /// 카드 배경으로 깔 그림. 없거나 불러오지 못하면 [fallbackColor] 를 씁니다.
  final ImageProvider? thumbnail;

  /// 카드 오른쪽 끝에 적을 글자. 화면마다 달라서 문자열로 받습니다
  /// (예: `주문 128` · `메뉴 9개` · `도보 1분`). null 이면 숨깁니다.
  final String? trailingLabel;

  /// 1부터 시작하는 순위. null 이면 순위 배지를 숨깁니다.
  final int? rank;

  final VoidCallback? onTap;
  final Color fallbackColor;

  static const double radius = 16;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // 블러가 카드 밖 배경(흰색)을 끌어와 가장자리가 하얘지는 것을 막습니다.
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumbnail(image: thumbnail, fallbackColor: fallbackColor),
            if (rank case final rank?)
              Positioned(left: 12, top: 12, child: _RankBadge(rank: rank)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _InfoPanel(
                name: name,
                category: category,
                locationLabel: locationLabel,
                minPrice: minPrice,
                trailingLabel: trailingLabel,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: _semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 카드 크기가 정해져 있어서, 큰 글자 설정에서도 정보 띠가 카드를 넘지 않게 1.2배까지만 키웁니다.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: card,
        ),
      ),
    );
  }

  String get _semanticLabel {
    final parts = [
      ?(rank == null ? null : '$rank위'),
      name,
      category,
      ?locationLabel,
      ?(minPrice == null ? null : '${AppCreditAmount.format(minPrice!)}크레딧부터'),
      ?trailingLabel,
    ];
    return parts.join(', ');
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, required this.fallbackColor});

  final ImageProvider? image;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(color: fallbackColor);
    final image = this.image;
    if (image == null) return fallback;
    return Image(
      image: image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

/// 32 지름 원 · 배경 `#11161E` 42% · 블러 24 · 글자 Bold 15 흰색.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
          tileMode: TileMode.mirror,
        ),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          color: AppColors.scrim.withValues(alpha: 0.42),
          child: Text(
            '$rank',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 배경 `#11161E` 46% · 블러 36 · 안쪽 여백 위아래 12 좌우 14 · 줄 사이 6.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.name,
    required this.category,
    required this.locationLabel,
    required this.minPrice,
    required this.trailingLabel,
  });

  final String name;
  final String category;
  final String? locationLabel;
  final int? minPrice;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
          tileMode: TileMode.mirror,
        ),
        child: ColoredBox(
          color: AppColors.scrim.withValues(alpha: 0.46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.s6,
              children: [
                Row(
                  spacing: AppSpacing.s8,
                  children: [
                    // 이름이 가격을 뺀 남은 폭을 모두 씁니다 (Figma 이름 칸 171).
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 17,
                          // Figma 첫 줄 높이 20 (기본 1.5배면 26 이 되어 띠가 76 으로 커짐)
                          height: 20 / 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.17,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    // 가격이 아주 길어도 한 줄에 맞게 줄어듭니다.
                    if (minPrice case final price?)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        // 가격 글자의 기본 줄 높이(약 23)가 이름 줄(20)보다 커서 띠가 3 커지므로
                        // 줄 높이를 20 에 맞춥니다.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(height: 20 / 16),
                            child: AppCreditAmount(
                              amount: price,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                              suffix: '~',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 20),
                  child: Row(
                    spacing: AppSpacing.s6,
                    children: [
                      _CategoryBadge(label: category),
                      // 위치가 남는 폭을 모두 쓰고, 오른쪽 글자는 카드 오른쪽 끝에 붙습니다.
                      Expanded(
                        child: locationLabel == null
                            ? const SizedBox.shrink()
                            : Text(
                                locationLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _meta,
                              ),
                      ),
                      if (trailingLabel case final label?)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label, style: _meta),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final TextStyle _meta = AppTypography.bodySmall.copyWith(
    fontSize: 13,
    color: AppColors.onPrimary,
  );
}

/// 높이 20 · 모서리 6 · 좌우 6 · 흰색 24% · 글자 12 SemiBold 흰색.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
