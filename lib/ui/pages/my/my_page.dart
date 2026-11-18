import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/my_credit.dart';
import '../../../data/models/my_user.dart';
import '../../../data/repositories/my_repository.dart';
import 'widgets/my_profile.dart';
import 'widgets/my_wallet.dart';
import 'widgets/my_menus.dart';
import 'widgets/my_notifications.dart';
import 'widgets/my_account_actions.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, this.repository, this.onLogout});
  final MyRepository? repository;
  final Future<void> Function()? onLogout;
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final MyRepository _repository = widget.repository ?? MockMyRepository();
  late Future<(MyUser, MyCredit)> _data = _load();

  Future<(MyUser, MyCredit)> _load() async {
    final user = await _repository.getUser();
    final credit = await _repository.getCredit();
    return (user, credit);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<(MyUser, MyCredit)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _data = _load()),
                child: const Text('다시 불러오기'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (user, credit) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.s16,
            ),
            children: [
              MyProfile(user: user),
              const SizedBox(height: AppSpacing.s24),
              MyWallet(credit: credit),
              const SizedBox(height: AppSpacing.s24),
              MyMenus(user: user),
              if (!user.isGuest) ...[
                const SizedBox(height: AppSpacing.s24),
                const MyNotifications(),
              ],
              MyAccountActions(
                repository: _repository,
                onLogout: widget.onLogout ?? () async {},
              ),
            ],
          );
        },
      ),
    ),
  );
}
