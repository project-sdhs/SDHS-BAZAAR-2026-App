import 'package:flutter/material.dart';

import '../../../../data/models/my_user.dart';
import '../../../components/basic/basic.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key, required this.user});
  final MyUser user;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AppAvatar(
        name: user.isGuest ? '' : user.name,
        size: 60,
        highlighted: true,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppBadge(user.roleLabel, variant: AppBadgeVariant.weak),
              ],
            ),
            Text(user.description),
          ],
        ),
      ),
    ],
  );
}
