import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_message.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';
import 'package:slack_chat_app/theme/app_colors.dart';
import 'package:slack_chat_app/widgets/chat_bubble.dart';
import 'package:slack_chat_app/widgets/message_input_box.dart';

class MobileConversationScreen extends StatefulWidget {
  const MobileConversationScreen.channel({
    super.key,
    required this.channelId,
    required this.currentUser,
    required this.onSendChannelMessage,
  })  : userId = null,
        onSendDirectMessage = null;

  const MobileConversationScreen.direct({
    super.key,
    required this.userId,
    required this.currentUser,
    required this.onSendDirectMessage,
  })  : channelId = null,
        onSendChannelMessage = null;

  final String? channelId;
  final String? userId;
  final AppUser currentUser;
  final Future<void> Function(String text)? onSendChannelMessage;
  final Future<void> Function(String text)? onSendDirectMessage;

  @override
  State<MobileConversationScreen> createState() => _MobileConversationScreenState();
}

class _MobileConversationScreenState extends State<MobileConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearchMode = false;
  String? _lastConversationKey;
  int _lastMessageCount = 0;

  bool get _isChannel => widget.channelId != null;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final channel =
        widget.channelId == null ? null : chatProvider.channelById(widget.channelId!);
    final teammate = widget.userId == null
        ? null
        : chatProvider.directMessageUserById(widget.userId!);

    final messages = _isChannel
        ? chatProvider.messagesForChannel(widget.channelId!)
        : chatProvider.messagesForDirectMessage(widget.userId!);
    final filteredMessages = _query.trim().isEmpty
        ? messages
        : messages.where((ChatMessage message) {
            return message.text.toLowerCase().contains(_query.trim().toLowerCase());
          }).toList();

    final conversationKey =
        _isChannel ? 'mobile-channel-${widget.channelId}' : 'mobile-dm-${widget.userId}';
    _scheduleScroll(
      conversationKey: conversationKey,
      messageCount: messages.length,
    );

    final title = _isChannel ? '#${channel?.name ?? 'channel'}' : teammate?.name ?? 'Chat';
    final subtitle = _isChannel
        ? channel?.topic ?? 'Workspace conversation'
        : 'Last seen just now';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leadingWidth: 34,
        titleSpacing: 10,
        title: _isSearchMode
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (String value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search in $title',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _isSearchMode = false;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            : Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isChannel ? AppColors.plumSoft : AppColors.skySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isChannel ? Icons.tag_rounded : Icons.person_rounded,
                      color: _isChannel ? AppColors.plum : AppColors.sky,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              if (_isSearchMode) {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _isSearchMode = false;
                });
                return;
              }
              setState(() {
                _isSearchMode = true;
              });
            },
            icon: Icon(
              _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: filteredMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.trim().isNotEmpty
                              ? 'No message matched "$_query".'
                              : 'Start the conversation.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      itemCount: filteredMessages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final message = filteredMessages[index];
                        return ChatBubble(
                          message: message,
                          currentUserId: widget.currentUser.id,
                          highlightQuery: _query,
                          showSenderName:
                              _isChannel && message.senderId != widget.currentUser.id,
                        );
                      },
                    ),
            ),
          ),
          MessageInputBox(
            hintText: _isChannel ? 'Message $title' : 'Type a message',
            onSend: (String text) async {
              if (_isChannel) {
                await widget.onSendChannelMessage?.call(text);
              } else {
                await widget.onSendDirectMessage?.call(text);
              }
            },
          ),
        ],
      ),
    );
  }

  void _scheduleScroll({
    required String conversationKey,
    required int messageCount,
  }) {
    if (_lastConversationKey == conversationKey && _lastMessageCount == messageCount) {
      return;
    }

    _lastConversationKey = conversationKey;
    _lastMessageCount = messageCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}
