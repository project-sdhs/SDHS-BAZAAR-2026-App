import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/seoul_time.dart';
import '../../../data/models/credit_transaction.dart';
import '../../../state/credit_store.dart';
import '../../components/basic/basic.dart';
import '../../components/credit_amount/credit_amount.dart';
import '../../components/feedback/feedback.dart';
import '../../navigation/app_top_bar.dart';

/// 탭 하나의 페이지 상태: 지금까지 받은 항목 · 다음 커서 · 읽는 중 · 오류.
class _TabFeed {
  final List<CreditTransaction> items = [];
  String? nextCursor;
  bool started = false;
  bool loading = false;
  Object? error;

  /// 새로고침하면 올라갑니다. 그 전에 보낸 요청의 응답은 버립니다.
  int generation = 0;

  bool get hasMore => nextCursor != null;

  void reset() {
    generation++;
    items.clear();
    nextCursor = null;
    started = false;
    loading = false;
    error = null;
  }
}

/// 거래 내역 (APP-64~66): 충전 · 구매 탭, 서울 날짜로 묶은 목록, 아래로 내리면 다음 페이지.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  /// 한 번에 받는 개수
  static const pageSize = 20;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final CreditStore _store;
  final Map<TransactionFilter, _TabFeed> _feeds = {
    for (final filter in TransactionFilter.values) filter: _TabFeed(),
  };
  TransactionFilter _tab = TransactionFilter.charge;

  /// 첫 페이지에 오는 충전 · 사용 합계 (없으면 null)
  int? _chargeTotal;

  _TabFeed get _feed => _feeds[_tab]!;

  @override
  void initState() {
    super.initState();
    _store = context.read<CreditStore>();
    // initState 안에서는 setState 를 못 부르므로 첫 페이지는 바로 받습니다.
    _feed.loading = true;
    unawaited(_fetch(_tab));
    // 사용액(`/me/credit.used`)을 최신으로 맞춥니다.
    unawaited(_store.refreshCredit());
  }

  /// 다음 페이지 (처음이면 첫 페이지). 이미 읽는 중이거나 마지막 페이지면 아무것도 안 합니다.
  Future<void> _loadNext(TransactionFilter tab) async {
    final feed = _feeds[tab]!;
    if (feed.loading || (feed.started && feed.nextCursor == null)) return;
    setState(() {
      feed.loading = true;
      feed.error = null;
    });
    await _fetch(tab);
  }

  Future<void> _fetch(TransactionFilter tab) async {
    final feed = _feeds[tab]!;
    final generation = feed.generation;
    final cursor = feed.nextCursor;
    try {
      final page = await _store.repository.transactions(
        type: tab,
        cursor: cursor,
        limit: TransactionsPage.pageSize,
      );
      if (!mounted || generation != feed.generation) return;
      setState(() {
        feed.items.addAll(page.items);
        feed.nextCursor = page.nextCursor;
        feed.started = true;
        if (page.summary case final summary?) {
          _chargeTotal = summary.chargeTotal;
        }
      });
    } catch (error) {
      if (!mounted || generation != feed.generation) return;
      setState(() => feed.error = error);
    } finally {
      if (mounted && generation == feed.generation) {
        setState(() => feed.loading = false);
      }
    }
  }

  /// 목록 끝 가까이를 그릴 때 다음 페이지를 부릅니다 (커서가 있고 읽는 중이 아닐 때만).
  void _maybeLoadMore() {
    final feed = _feed;
    if (!feed.hasMore || feed.loading || feed.error != null) return;
    final tab = _tab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadNext(tab));
    });
  }

  void _changeTab(TransactionFilter tab) {
    setState(() => _tab = tab);
    if (!_feeds[tab]!.started) unawaited(_loadNext(tab));
  }

  /// 당겨서 새로고침: 이 탭을 처음부터 다시 받고 잔액 · 사용액도 다시 읽습니다.
  Future<void> _refresh() async {
    setState(_feed.reset);
    await Future.wait([_loadNext(_tab), _store.refreshCredit()]);
  }

  void _retry() => unawaited(_loadNext(_tab));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final feed = _feed;
    final rows = _buildRows(feed.items);
    final firstLoad = !feed.started;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTopBar(
                      title: '거래 내역',
                      description: '이번 바자회에 쓴 크레딧이에요',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Column(
                        children: [
                          AppSegmentedControl<TransactionFilter>(
                            items: const {
                              TransactionFilter.charge: '크레딧 충전',
                              TransactionFilter.purchase: '부스 구매',
                            },
                            value: _tab,
                            onChanged: _changeTab,
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          _Summary(store: store, chargeTotal: _chargeTotal),
                          const SizedBox(height: AppSpacing.s24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (firstLoad && feed.error != null)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    title: '거래 내역을 불러오지 못했어요',
                    message: '잠시 뒤에 다시 시도해 주세요',
                    icon: Icons.wifi_off,
                    actionLabel: '다시 시도',
                    onAction: _retry,
                  ),
                )
              else if (firstLoad)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  sliver: SliverToBoxAdapter(child: AppSkeletonList()),
                )
              else if (rows.isEmpty)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    title: _tab == TransactionFilter.charge
                        ? '아직 충전 내역이 없어요'
                        : '아직 구매 내역이 없어요',
                    message: _tab == TransactionFilter.charge
                        ? '충전과 크레딧 조정 내역이 여기에 표시돼요.'
                        : '부스에서 결제하면 구매와 환불 내역을 볼 수 있어요.',
                    icon: Icons.receipt_long_rounded,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    if (index >= rows.length - 5) _maybeLoadMore();
                    return switch (rows[index]) {
                      _DayHeader(:final label, :final first) => Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          first ? 0 : AppSpacing.s16,
                          AppSpacing.s16,
                          AppSpacing.s8,
                        ),
                        child: Text(
                          label,
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      _Item(:final transaction) => _TransactionRow(
                        transaction: transaction,
                      ),
                    };
                  },
                ),
              if (!firstLoad && feed.loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.s24),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                )
              else if (!firstLoad && feed.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('다음 내역을 불러오지 못했어요 · 다시 시도'),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
            ],
          ),
        ),
      ),
    );
  }

  /// 서버 순서를 그대로 두고, 서울 날짜가 바뀌는 곳에 날짜 줄을 넣습니다.
  List<_Row> _buildRows(List<CreditTransaction> items) {
    final rows = <_Row>[];
    DateTime? previousDay;
    for (final transaction in items) {
      final day = seoulDay(transaction.occurredAt);
      if (day != previousDay) {
        rows.add(
          _DayHeader(
            seoulDayLabel(transaction.occurredAt),
            first: previousDay == null,
          ),
        );
        previousDay = day;
      }
      rows.add(_Item(transaction));
    }
    return rows;
  }
}

sealed class _Row {
  const _Row();
}

class _DayHeader extends _Row {
  const _DayHeader(this.label, {required this.first});

  final String label;
  final bool first;
}

class _Item extends _Row {
  const _Item(this.transaction);

  final CreditTransaction transaction;
}

/// 충전 · 사용 합계 카드. 사용 = `/me/credit.used`, 충전 = 첫 페이지 `summary.chargeTotal` (없으면 잔액 + 사용).
class _Summary extends StatelessWidget {
  const _Summary({required this.store, required this.chargeTotal});

  final CreditStore store;
  final int? chargeTotal;

  @override
  Widget build(BuildContext context) {
    final known = store.credit != null;
    return Row(
      spacing: AppSpacing.s8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            label: '충전',
            amount: known || chargeTotal != null
                ? chargeTotal ?? store.balance + store.used
                : null,
            tone: CreditAmountTone.charge,
          ),
        ),
        Expanded(
          child: _SummaryCard(label: '사용', amount: known ? store.used : null),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    this.tone = CreditAmountTone.normal,
  });

  final String label;
  final int? amount;
  final CreditAmountTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.s16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s6),
        if (amount case final amount?)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppCreditAmount(
              amount: amount,
              type: CreditAmountType.frame,
              tone: tone,
            ),
          )
        else
          const AppSkeleton(width: 96, height: 30, radius: 8),
      ],
    ),
  );
}

/// 거래 한 줄. 색은 금액 부호가 아니라 상태로 정합니다.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final CreditTransaction transaction;

  /// 확인 중 · 반려 · 환불된 결제는 흐리게
  bool get _muted => switch (transaction.status) {
    TransactionStatus.pending ||
    TransactionStatus.needsReview ||
    TransactionStatus.rejected ||
    TransactionStatus.refunded => true,
    _ => false,
  };

  /// 승인된 충전 · 환불은 파란 타일과 파란 금액
  bool get _highlighted =>
      (transaction.type == TransactionType.charge &&
          transaction.status == TransactionStatus.approved) ||
      transaction.type == TransactionType.refund;

  String get _statusLabel => switch (transaction.status) {
    TransactionStatus.pending => '입금 확인 중',
    TransactionStatus.needsReview => '확인 필요',
    TransactionStatus.approved => '승인',
    TransactionStatus.rejected => '반려',
    TransactionStatus.completed => switch (transaction.type) {
      TransactionType.refund => '환불',
      TransactionType.adjustment => '크레딧 조정',
      _ => '결제',
    },
    TransactionStatus.refunded => '환불됨',
  };

  String get _meta {
    final time = seoulHourMinute(transaction.occurredAt);
    final subtitle = transaction.subtitle;
    final parts = <String>[time];
    switch (transaction.type) {
      case TransactionType.purchase:
        parts.add(subtitle?.isNotEmpty ?? false ? subtitle! : '결제');
        if (transaction.status == TransactionStatus.refunded) {
          parts.add('환불됨');
        }
      case TransactionType.charge:
        parts.add(_statusLabel);
      case TransactionType.refund:
      case TransactionType.adjustment:
        parts.add(subtitle?.isNotEmpty ?? false ? subtitle! : _statusLabel);
    }
    return parts.join(' · ');
  }

  IconData get _icon => switch (transaction.type) {
    TransactionType.charge => Icons.add_rounded,
    TransactionType.purchase => Icons.storefront_rounded,
    TransactionType.refund => Icons.replay_rounded,
    TransactionType.adjustment => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final tone = _muted
        ? CreditAmountTone.muted
        : _highlighted
        ? CreditAmountTone.charge
        : CreditAmountTone.normal;
    return AppListRow(
      title: transaction.title,
      subtitle: _meta,
      leading: AppCategoryTile(icon: _icon, highlighted: _highlighted),
      trailing: AppCreditAmount(
        amount: transaction.amount,
        showPlus: transaction.amount > 0,
        showCoin: false,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        tone: tone,
      ),
    );
  }
}
