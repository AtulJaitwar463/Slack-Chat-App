import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_channel.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';
import 'package:slack_chat_app/widgets/channel_tile.dart';
import 'package:slack_chat_app/widgets/home/mobile_dashboard.dart';
import 'package:slack_chat_app/widgets/home/mobile_list_panel.dart';
import 'package:slack_chat_app/widgets/user_tile.dart';

class MobileHomeView extends StatelessWidget {
  const MobileHomeView({
    super.key,
    required this.currentUser,
    required this.activeChannel,
    required this.activeDmUser,
    required this.mobileTabIndex,
    required this.onOpenChannel,
    required this.onOpenDirectMessage,
  });

  final AppUser currentUser;
  final ChatChannel? activeChannel;
  final AppUser? activeDmUser;
  final int mobileTabIndex;
  final ValueChanged<String> onOpenChannel;
  final ValueChanged<String> onOpenDirectMessage;

  @override
  Widget build(BuildContext context) {
    if (mobileTabIndex == 0) {
      return MobileDashboard(
        currentUser: currentUser,
        activeChannel: activeChannel,
        activeDmUser: activeDmUser,
        onOpenChannel: onOpenChannel,
        onOpenDirectMessage: onOpenDirectMessage,
      );
    }

    if (mobileTabIndex == 1) {
      return MobileListPanel(
        title: 'Channels',
        subtitle: 'Jump into team conversations and project updates.',
        child: Consumer<ChatProvider>(
          builder: (BuildContext context, ChatProvider chatProvider, _) {
            return ListView.builder(
              itemCount: chatProvider.channels.length,
              itemBuilder: (BuildContext context, int index) {
                final channel = chatProvider.channels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChannelTile(
                    channel: channel,
                    unreadCount: chatProvider.unreadChannelCount(channel.id),
                    isSelected: activeChannel?.id == channel.id,
                    onTap: () => onOpenChannel(channel.id),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return MobileListPanel(
      title: 'Direct Messages',
      subtitle: 'Private one-to-one conversations across your workspace.',
      child: Consumer<ChatProvider>(
        builder: (BuildContext context, ChatProvider chatProvider, _) {
          return ListView.builder(
            itemCount: chatProvider.directMessageUsers.length,
            itemBuilder: (BuildContext context, int index) {
              final user = chatProvider.directMessageUsers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: UserTile(
                  user: user,
                  unreadCount: chatProvider.unreadDirectMessageCount(user.id),
                  isSelected: activeDmUser?.id == user.id,
                  onTap: () => onOpenDirectMessage(user.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
