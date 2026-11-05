import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../components/basic/basic.dart';

/// APP-08 부품과 선택 동작을 확인하는 개발용 화면.
class BasicCatalogPage extends StatefulWidget {
  const BasicCatalogPage({super.key});

  @override
  State<BasicCatalogPage> createState() => _BasicCatalogPageState();
}

class _BasicCatalogPageState extends State<BasicCatalogPage> {
  String _grade = '전체';
  String _sort = 'grade';
  bool _notifications = true;
  bool _loading = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('APP-08 · 기본 위젯')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('바자회 앱의 공통 부품', style: AppTypography.h3),
            const SizedBox(height: 8),
            Text(
              '피그마 디자인 시스템 · 선택 항목과 스위치를 눌러 보세요.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            ),
            const _Heading('배지', '누를 수 없는 역할·상태 표시'),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppBadge('학생'),
                AppBadge('반장', variant: AppBadgeVariant.primary),
                AppBadge('캐셔', variant: AppBadgeVariant.weak),
                AppBadge('선생님', variant: AppBadgeVariant.dark),
                AppBadge('특별부스', variant: AppBadgeVariant.weak),
                AppBadge('품절', variant: AppBadgeVariant.danger),
              ],
            ),
            const _Heading('칩 · 세그먼트', '선택한 값은 화면을 만드는 쪽에서 관리합니다'),
            AppSegmentedControl<String>(
              items: const {'grade': '학년 순', 'popular': '인기 순'},
              value: _sort,
              onChanged: (value) => setState(() => _sort = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grade in ['전체', '1학년', '2학년', '3학년', '특별부스'])
                  AppChip(
                    grade,
                    selected: _grade == grade,
                    onSelected: (_) => setState(() => _grade = grade),
                  ),
                const AppChip('비활성', onSelected: null),
              ],
            ),
            const _Heading('리스트 행 · 스위치', '구분선 없이 여백으로 나눕니다'),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const AppListRow(
                    title: '3-1 로제떡볶이',
                    subtitle: '본관 1층 로비',
                    leading: AppCategoryTile(icon: Icons.ramen_dining),
                    trailing: AppBadge('운영 중', variant: AppBadgeVariant.weak),
                  ),
                  AppListRow(
                    title: '거래 내역',
                    subtitle: '충전 · 구매 기록',
                    leading: const AppCategoryTile(icon: Icons.receipt_long),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('목록 행 누르기 확인')),
                    ),
                  ),
                  AppListRow(
                    title: '주문 알림 받기',
                    trailing: AppToggle(
                      label: '주문 알림 받기',
                      value: _notifications,
                      onChanged: (value) =>
                          setState(() => _notifications = value),
                    ),
                  ),
                ],
              ),
            ),
            const _Heading('카테고리 타일', '48px · 모서리 14px · 아이콘 24px'),
            const Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                AppCategoryTile(icon: Icons.ramen_dining, label: '분식'),
                AppCategoryTile(icon: Icons.bakery_dining, label: '간식'),
                AppCategoryTile(icon: Icons.local_cafe, label: '음료'),
                AppCategoryTile(icon: Icons.rice_bowl, label: '한식'),
                AppCategoryTile(icon: Icons.shopping_bag, label: '굿즈'),
                AppCategoryTile(icon: Icons.sports_esports, label: '체험'),
                AppCategoryTile(icon: Icons.palette, label: '전시'),
                AppCategoryTile(
                  icon: Icons.school,
                  label: '특별부스',
                  highlighted: true,
                ),
              ],
            ),
            const _Heading('아바타', '사진 대신 이름 첫 글자를 표시합니다'),
            const Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                AppAvatar(name: '이재원', highlighted: true),
                AppAvatar(name: '박도현'),
                AppAvatar(name: '김서연'),
                AppAvatar(name: '한지우'),
                AppAvatar(name: ''),
              ],
            ),
            const _Heading('스켈레톤', '응답 후 카테고리 타일과 실제 내용으로 바꿉니다'),
            AppListRow(
              title: '로딩 미리보기',
              trailing: AppToggle(
                label: '로딩 미리보기',
                value: _loading,
                onChanged: (value) => setState(() => _loading = value),
              ),
            ),
            if (_loading)
              const AppSkeletonList()
            else
              const AppListRow(
                title: '2-3 타코야끼',
                subtitle: '도보 1분 · 신관 2층 복도',
                leading: AppCategoryTile(icon: Icons.bakery_dining),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h4),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
        ),
      ],
    ),
  );
}
