import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../components/buttons/app_button.dart';
import '../../components/feedback/feedback.dart';
import '../../components/inputs/inputs.dart';

/// 입력 · 피드백 카탈로그 (개발용, 디버그 빌드에서만 `/dev/input-feedback` 로 열림).
class InputFeedbackCatalogPage extends StatefulWidget {
  const InputFeedbackCatalogPage({super.key});

  @override
  State<InputFeedbackCatalogPage> createState() =>
      _InputFeedbackCatalogPageState();
}

class _InputFeedbackCatalogPageState extends State<InputFeedbackCatalogPage> {
  final _searchController = TextEditingController(text: '타코');
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('입력 · 피드백 카탈로그')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          const _Section('빈 상태'),
          const SizedBox(
            height: 220,
            child: AppEmptyState(
              title: '검색 결과가 없어요',
              message: '반 번호(예: 2-3)나 메뉴 이름으로\n다시 검색해 보세요',
            ),
          ),
          const _Section('토스트'),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              AppButton(
                '성공 토스트',
                size: AppButtonSize.medium,
                onPressed: () =>
                    AppToast.show(context, message: '10,000 크레딧이 충전됐어요'),
              ),
              AppButton(
                '오류 토스트',
                size: AppButtonSize.medium,
                variant: AppButtonVariant.weakDanger,
                onPressed: () => AppToast.show(
                  context,
                  message: '입금자명이 학번과 달라요',
                  type: AppToastType.error,
                ),
              ),
            ],
          ),
          const _Section('다이얼로그'),
          AppButton(
            '권한 확인 다이얼로그 열기',
            variant: AppButtonVariant.light,
            onPressed: () => AppDialog.show(
              context,
              title: '캐셔 권한을 줄까요?',
              message: '학생이 우리 반 부스에서 결제를 받을 수 있게 돼요.',
              confirmLabel: '권한 주기',
            ),
          ),
          const _Section('바텀시트'),
          AppButton(
            '부스 목록 바텀시트 열기',
            variant: AppButtonVariant.light,
            onPressed: _showBottomSheet,
          ),
          const _Section('텍스트 필드'),
          const _FieldExample(
            label: 'box · 기본',
            field: AppTextField(hintText: '이름을 입력하세요'),
          ),
          const _FieldExample(
            label: 'box · 오류',
            field: AppTextField(
              initialValue: '22-5',
              errorText: '학번은 숫자 4자리로 입력해 주세요.',
            ),
          ),
          const _FieldExample(
            label: 'line',
            field: AppTextField(
              initialValue: '타코야끼',
              variant: AppTextFieldVariant.line,
            ),
          ),
          const _FieldExample(
            label: 'hero · 금액',
            field: AppTextField(
              initialValue: '10,000',
              variant: AppTextFieldVariant.hero,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              creditSuffix: true,
            ),
          ),
          const _FieldExample(
            label: '비활성',
            field: AppTextField(initialValue: '2학년 3반', enabled: false),
          ),
          const _Section('검색 필드'),
          AppSearchField(
            controller: _searchController,
            hintText: '반 · 부스 · 메뉴 검색',
            onChanged: (value) => setState(() => _searchText = value),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            _searchText.isEmpty ? '검색어를 입력해 보세요' : '검색어: $_searchText',
            style: AppTypography.bodySmall.copyWith(color: AppColors.body),
          ),
          const SizedBox(height: AppSpacing.s32),
        ],
      ),
    );
  }

  Future<void> _showBottomSheet() async {
    await AppBottomSheet.show<void>(
      context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 구역 부스 16곳',
              style: AppTypography.h4.copyWith(color: AppColors.foreground),
            ),
            const SizedBox(height: AppSpacing.s16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront, color: AppColors.primary),
              title: const Text('2-3 타코야끼'),
              subtitle: const Text('도보 1분 · 신관 2층 복도'),
              trailing: const Text('1,000 크레딧'),
            ),
            AppButton(
              '닫기',
              expand: true,
              variant: AppButtonVariant.light,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s24,
        bottom: AppSpacing.s16,
      ),
      child: Text(
        title,
        style: AppTypography.h4.copyWith(color: AppColors.foreground),
      ),
    );
  }
}

class _FieldExample extends StatelessWidget {
  const _FieldExample({required this.label, required this.field});

  final String label;
  final AppTextField field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.body),
            ),
          ),
          field,
        ],
      ),
    );
  }
}
