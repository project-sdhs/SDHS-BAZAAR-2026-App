import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/payment_models.dart';
import '../../../state/credit_store.dart';
import '../../components/basic/app_segmented_control.dart';
import '../../components/credit_amount/credit_amount.dart';
import '../../components/feedback/app_empty_state.dart';
import '../../navigation/app_top_bar.dart';

enum _TransactionTab { charge, purchase }

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const _pageSize = 20;
  final _scrollController = ScrollController();
  _TransactionTab _tab = _TransactionTab.charge;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<CreditTransaction> _filteredTransactions(CreditStore store) {
    final transactions = store.transactions.where((transaction) {
      final isCharge =
          transaction.type == TransactionType.charge ||
          transaction.type == TransactionType.adjustment;
      return _tab == _TransactionTab.charge ? isCharge : !isCharge;
    }).toList();
    transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return transactions;
  }

  void _loadMore() {
    final count = _filteredTransactions(context.read<CreditStore>()).length;
    if (_scrollController.position.extentAfter < 200 && _visibleCount < count) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  void _changeTab(_TransactionTab tab) {
    setState(() {
      _tab = tab;
      _visibleCount = _pageSize;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final transactions = _filteredTransactions(store);
    final visibleTransactions = transactions.take(_visibleCount).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            const AppTopBar(title: '거래 내역', description: '이번 바자회에 쓴 크레딧이에요'),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (store.isPreview) ...[
                    Text(
                      '디자인 미리보기 · 예시 데이터',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                  ],
                  AppSegmentedControl<_TransactionTab>(
                    items: const {
                      _TransactionTab.charge: '크레딧 충전',
                      _TransactionTab.purchase: '부스 구매',
                    },
                    value: _tab,
                    onChanged: _changeTab,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Row(
                    spacing: AppSpacing.s8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: '충전',
                          amount: store.chargedTotal,
                          tone: CreditAmountTone.charge,
                        ),
                      ),
                      Expanded(
                        child: _SummaryCard(
                          label: '사용',
                          amount: store.usedTotal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  if (transactions.isEmpty)
                    AppEmptyState(
                      title: _tab == _TransactionTab.charge
                          ? '아직 충전 내역이 없어요'
                          : '아직 구매 내역이 없어요',
                      message: _tab == _TransactionTab.charge
                          ? '충전과 크레딧 조정 내역이 여기에 표시돼요.'
                          : '부스에서 결제하면 구매와 환불 내역을 볼 수 있어요.',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ..._transactionRows(visibleTransactions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _transactionRows(List<CreditTransaction> transactions) {
    final rows = <Widget>[];
    DateTime? previousDate;
    for (final transaction in transactions) {
      final date = _seoulTime(transaction.occurredAt);
      final day = DateTime(date.year, date.month, date.day);
      if (day != previousDate) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(
              top: previousDate == null ? 0 : AppSpacing.s24,
              bottom: AppSpacing.s8,
            ),
            child: Text(
              _dateLabel(day),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
        );
        previousDate = day;
      }
      rows.add(_TransactionRow(transaction: transaction));
    }
    return rows;
  }
}

// 서버의 UTC 시각은 기기 시간대와 관계없이 바자회 현지 시각으로 표시합니다.
DateTime _seoulTime(DateTime date) =>
    date.toUtc().add(const Duration(hours: 9));

String _dateLabel(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    this.tone = CreditAmountTone.normal,
  });

  final String label;
  final int amount;
  final CreditAmountTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.s16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppCreditAmount(
            amount: amount,
            type: CreditAmountType.frame,
            tone: tone,
          ),
        ),
      ],
    ),
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final CreditTransaction transaction;

  String get _status => switch (transaction.type) {
    TransactionType.charge => switch (transaction.status) {
      'approved' || 'completed' => '승인',
      'pending' => '입금 확인 중',
      'needs_review' => '확인 필요',
      'rejected' => '반려',
      _ => '충전',
    },
    TransactionType.purchase => '결제',
    TransactionType.refund => '환불',
    TransactionType.adjustment => '크레딧 조정',
  };

  String get _description {
    final time = _seoulTime(transaction.occurredAt);
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final detail =
        transaction.type == TransactionType.purchase &&
            transaction.subtitle.isNotEmpty
        ? transaction.subtitle
        : _status;
    return '$hours:$minutes · $detail';
  }

  @override
  Widget build(BuildContext context) {
    final positive = transaction.amount > 0;
    final icon = switch (transaction.type) {
      TransactionType.charge => Icons.add_rounded,
      TransactionType.purchase => Icons.storefront_rounded,
      TransactionType.refund => Icons.replay_rounded,
      TransactionType.adjustment => Icons.tune_rounded,
    };
    final amount = AppCreditAmount(
      amount: transaction.amount,
      showPlus: positive,
      showCoin: false,
      fontSize: 18,
      tone: positive ? CreditAmountTone.charge : CreditAmountTone.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(16) > 21;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: positive
                      ? AppColors.weakBackground
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: positive ? AppColors.primary : AppColors.body,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (transaction.type != TransactionType.purchase &&
                        transaction.subtitle.isNotEmpty &&
                        transaction.subtitle != _status)
                      Text(
                        transaction.subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    if (stacked) ...[
                      const SizedBox(height: AppSpacing.s4),
                      amount,
                    ],
                  ],
                ),
              ),
              if (!stacked) ...[
                const SizedBox(width: AppSpacing.s8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(140, constraints.maxWidth * .4),
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: amount),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
