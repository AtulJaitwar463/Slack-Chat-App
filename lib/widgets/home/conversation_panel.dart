import 'package:flutter/material.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_channel.dart';
import 'package:slack_chat_app/models/chat_message.dart';
import 'package:slack_chat_app/theme/app_colors.dart';
import 'package:slack_chat_app/widgets/chat_bubble.dart';
import 'package:slack_chat_app/widgets/message_input_box.dart';

class ConversationPanel extends StatelessWidget {
  const ConversationPanel({
    super.key,
    required this.currentUser,
    required this.activeChannel,
    required this.activeDmUser,
    required this.filteredMessages,
    required this.searchQuery,
    required this.scrollController,
    required this.onSend,
  });

  final AppUser currentUser;
  final ChatChannel? activeChannel;
  final AppUser? activeDmUser;
  final List<ChatMessage> filteredMessages;
  final String searchQuery;
  final ScrollController scrollController;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final title = activeChannel != null ? '#${activeChannel!.name}' : activeDmUser?.name;
    final subtitle = activeChannel?.topic ??
        'Private conversation with ${activeDmUser?.name ?? 'a teammate'}.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderMuted),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeChannel != null
                        ? AppColors.plumSoft
                        : AppColors.skySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    activeChannel != null ? Icons.tag_rounded : Icons.person_rounded,
                    color: activeChannel != null ? AppColors.plum : AppColors.sky,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title ?? 'Conversation',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (searchQuery.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.plumSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${filteredMessages.length} match${filteredMessages.length == 1 ? '' : 'es'}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.plum,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: filteredMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          searchQuery.trim().isNotEmpty
                              ? 'No messages matched "$searchQuery". Try a different keyword.'
                              : 'This conversation is quiet right now. Start the thread with your first message.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      itemCount: filteredMessages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (BuildContext context, int index) {
                        final message = filteredMessages[index];
                        return ChatBubble(
                          message: message,
                          currentUserId: currentUser.id,
                          highlightQuery: searchQuery,
                          showSenderName:
                              activeChannel != null && message.senderId != currentUser.id,
                        );
                      },
                    ),
            ),
          ),
          MessageInputBox(
            hintText: activeChannel != null
                ? 'Message #${activeChannel!.name}'
                : 'Message ${activeDmUser?.name ?? 'teammate'}',
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}
