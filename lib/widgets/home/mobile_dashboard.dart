import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_channel.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';
import 'package:slack_chat_app/theme/app_colors.dart';
import 'package:slack_chat_app/widgets/home/dashboard_stat_card.dart';
import 'package:slack_chat_app/widgets/home/light_channel_tile.dart';
import 'package:slack_chat_app/widgets/home/quick_launch_card.dart';

class MobileDashboard extends StatelessWidget {
  const MobileDashboard({
    super.key,
    required this.currentUser,
    required this.activeChannel,
    required this.activeDmUser,
    required this.onOpenChannel,
    required this.onOpenDirectMessage,
  });

  final AppUser currentUser;
  final ChatChannel? activeChannel;
  final AppUser? activeDmUser;
  final ValueChanged<String> onOpenChannel;
  final ValueChanged<String> onOpenDirectMessage;

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.plumDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: 18,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.sky,
                        borderRadius: BorderRadius.circular(14),
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
                            'Welcome back, ${currentUser.name.split(' ').first}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your workspace is ready.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textOnDarkSoft,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DashboardStatCard(
                        label: 'Channels',
                        value: '${chatProvider.channels.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        label: 'DMs',
                        value: '${chatProvider.directMessageUsers.length}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          QuickLaunchCard(
            title: 'Continue chatting',
            subtitle: activeDmUser != null
                ? 'Jump back into your conversation with ${activeDmUser!.name}.'
                : activeChannel != null
                    ? 'Open #${activeChannel!.name} and catch up fast.'
                    : 'Pick a channel or DM to start messaging.',
            actionLabel: activeDmUser != null
                ? 'Open ${activeDmUser!.name}'
                : activeChannel != null
                    ? 'Open #${activeChannel!.name}'
                    : 'Browse channels',
            onTap: () {
              if (activeDmUser != null) {
                onOpenDirectMessage(activeDmUser!.id);
                return;
              }
              if (activeChannel != null) {
                onOpenChannel(activeChannel!.id);
                return;
              }
              if (chatProvider.channels.isNotEmpty) {
                onOpenChannel(chatProvider.channels.first.id);
              }
            },
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Recent channels',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Open your most active spaces.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                ...chatProvider.channels.take(3).map(
                  (ChatChannel channel) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LightChannelTile(
                      channel: channel,
                      unreadCount: chatProvider.unreadChannelCount(channel.id),
                      onTap: () => onOpenChannel(channel.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
