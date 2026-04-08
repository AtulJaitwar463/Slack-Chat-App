import 'package:flutter/material.dart';
import 'package:slack_chat_app/theme/app_colors.dart';

class MobileHeaderTitle extends StatelessWidget {
  const MobileHeaderTitle({
    super.key,
    required this.currentUserName,
    required this.mobileTabIndex,
  });

  final String currentUserName;
  final int mobileTabIndex;

  @override
  Widget build(BuildContext context) {
    final title = switch (mobileTabIndex) {
      0 => 'Home',
      1 => 'Channels',
      _ => 'Direct Messages',
    };

    final subtitle = switch (mobileTabIndex) {
      0 => 'Hi, ${currentUserName.split(' ').first}',
      1 => 'Browse your workspace',
      _ => 'One-to-one chats',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
