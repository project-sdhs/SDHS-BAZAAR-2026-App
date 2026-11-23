import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/my_user.dart';
import 'widgets/my_profile.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key, this.user = mockStudent});
  final MyUser user;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [MyProfile(user: user)],
      ),
    ),
  );
}
