import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/credit_amount/credit_amounts.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _orderNotifications = true;

  void _showUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('아직 연결되지 않은 기능이에요.')));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.weakBackground,
                  foregroundColor: AppColors.weakForeground,
                  child: Text(
                    '이',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '이재원',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _RoleBadge(),
                        ],
                      ),
                      Text(
                        '2학년 3반 · 학번 2205',
                        style: TextStyle(fontSize: 16, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '보유 크레딧',
                      style: TextStyle(
                        color: AppColors.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AppCreditAmount(
                      amount: 12400,
                      type: CreditAmountType.tile,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _showUnavailable,
                          child: const Text(
                            '+  충전하기',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              backgroundColor: AppColors.canvas,
                              foregroundColor: AppColors.foreground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => context.go(Routes.pay),
                            icon: const Icon(Icons.qr_code_scanner, size: 19),
                            label: const Text(
                              'QR 결제',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: AppCreditAmount(
                amount: 17600,
                type: CreditAmountType.caption,
                tone: CreditAmountTone.muted,
                fontSize: 15,
                prefix: '이번 바자회에 ',
                suffix: ' 썼어요',
              ),
            ),
            const SizedBox(height: 24),
            _MenuRow(
              icon: Icons.receipt_long,
              title: '거래 내역',
              description: '충전 · 구매 기록',
              onTap: _showUnavailable,
            ),
            _MenuRow(
              icon: Icons.account_balance,
              title: '크레딧 충전',
              description: '계좌이체 · QR',
              onTap: _showUnavailable,
            ),
            _MenuRow(
              icon: Icons.shield,
              title: '반 인원 확인',
              description: '반장 · 선생님만 보여요',
              highlighted: true,
              onTap: _showUnavailable,
            ),
            _MenuRow(
              icon: Icons.storefront,
              title: '부스 운영',
              description: '2-3 타코야끼 · 캐셔 · 반장만 보여요',
              highlighted: true,
              onTap: _showUnavailable,
            ),
            const SizedBox(height: 34),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '주문 알림 받기',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              value: _orderNotifications,
              activeTrackColor: AppColors.primary,
              onChanged: (value) => setState(() => _orderNotifications = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('로그아웃'),
                ),
                TextButton(
                  onPressed: _showUnavailable,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.body,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('계정 삭제'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.weakBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '반장',
          style: TextStyle(
            color: AppColors.weakForeground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: highlighted ? AppColors.weakBackground : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: highlighted ? AppColors.primary : AppColors.body,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 14, color: AppColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: onTap,
    );
  }
}
