import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_channel.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';
import 'package:slack_chat_app/providers/ui_provider.dart';
import 'package:slack_chat_app/theme/app_colors.dart';
import 'package:slack_chat_app/widgets/channel_tile.dart';
import 'package:slack_chat_app/widgets/user_tile.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    super.key,
    required this.currentUser,
    required this.onChannelSelected,
    required this.onDirectMessageSelected,
  });

  final AppUser currentUser;
  final ValueChanged<String> onChannelSelected;
  final ValueChanged<String> onDirectMessageSelected;

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final uiProvider = context.watch<UIProvider>();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.plumDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentUser.initials,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Teamspace HQ',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Signed in as ${currentUser.name}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textOnDarkSoft,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Channels',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textOnDarkSoft,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...chatProvider.channels.map(
              (ChatChannel channel) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ChannelTile(
                  channel: channel,
                  unreadCount: chatProvider.unreadChannelCount(channel.id),
                  isSelected: uiProvider.activeChannelId == channel.id,
                  onTap: () => onChannelSelected(channel.id),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Direct messages',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textOnDarkSoft,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: chatProvider.directMessageUsers.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = chatProvider.directMessageUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: UserTile(
                      user: user,
                      unreadCount: chatProvider.unreadDirectMessageCount(user.id),
                      isSelected: uiProvider.activeDirectMessageUserId == user.id,
                      onTap: () => onDirectMessageSelected(user.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
