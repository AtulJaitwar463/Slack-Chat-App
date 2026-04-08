import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_channel.dart';
import 'package:slack_chat_app/models/chat_message.dart';
import 'package:slack_chat_app/providers/auth_provider.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';
import 'package:slack_chat_app/providers/ui_provider.dart';
import 'package:slack_chat_app/screens/login_screen.dart';
import 'package:slack_chat_app/services/mock_chat_service.dart';
import 'package:slack_chat_app/theme/app_colors.dart';
import 'package:slack_chat_app/widgets/home/conversation_panel.dart';
import 'package:slack_chat_app/widgets/home/mobile_conversation_screen.dart';
import 'package:slack_chat_app/widgets/home/mobile_header_title.dart';
import 'package:slack_chat_app/widgets/home/mobile_home_view.dart';
import 'package:slack_chat_app/widgets/home/workspace_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _didInitializeSelection = false;
  String? _lastConversationKey;
  int _lastMessageCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitializeSelection) {
      return;
    }

    _didInitializeSelection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        return;
      }

      context.read<UIProvider>().syncForUser(
            userId: currentUser.id,
            chatProvider: context.read<ChatProvider>(),
          );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final uiProvider = context.watch<UIProvider>();
    final currentUser = authProvider.currentUser!;

    final activeChannel = uiProvider.activeChannelId == null
        ? null
        : chatProvider.channelById(uiProvider.activeChannelId!);
    final activeDmUser = uiProvider.activeDirectMessageUserId == null
        ? null
        : chatProvider.directMessageUserById(uiProvider.activeDirectMessageUserId!);

    final messages = activeChannel != null
        ? chatProvider.messagesForChannel(activeChannel.id)
        : activeDmUser != null
            ? chatProvider.messagesForDirectMessage(activeDmUser.id)
            : const <ChatMessage>[];

    final trimmedQuery = uiProvider.searchQuery.trim().toLowerCase();
    final filteredMessages = trimmedQuery.isEmpty
        ? messages
        : messages.where((ChatMessage message) {
            return message.text.toLowerCase().contains(trimmedQuery);
          }).toList();

    final conversationKey =
        activeChannel != null ? 'channel-${activeChannel.id}' : 'dm-${activeDmUser?.id ?? 'none'}';
    _scheduleScrollIfNeeded(
      conversationKey: conversationKey,
      messageCount: messages.length,
    );

    final width = MediaQuery.of(context).size.width;
    final isDesktopLayout = width >= 940;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: isDesktopLayout
          ? AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 20,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: uiProvider.isSearchVisible
                    ? Container(
                        key: const ValueKey<String>('search-field'),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: context.read<UIProvider>().updateSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Search messages',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      )
                    : Column(
                        key: const ValueKey<String>('app-title'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Teamspace',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            activeChannel != null
                                ? '#${activeChannel.name}'
                                : activeDmUser != null
                                    ? activeDmUser.name
                                    : 'Workspace',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
              actions: _buildHomeActions(
                context: context,
                showSearchButton: true,
                currentUserName: currentUser.name,
              ),
            )
          : AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 20,
              title: MobileHeaderTitle(
                currentUserName: currentUser.name,
                mobileTabIndex: uiProvider.mobileTabIndex,
              ),
              actions: _buildHomeActions(
                context: context,
                showSearchButton: false,
                currentUserName: currentUser.name,
              ),
            ),
      bottomNavigationBar: isDesktopLayout
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                      (Set<WidgetState> states) {
                        final isSelected = states.contains(WidgetState.selected);
                        return TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.72),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        );
                      },
                    ),
                  ),
                  child: NavigationBar(
                    height: 74,
                    backgroundColor: AppColors.plumDark,
                    indicatorColor: AppColors.plum,
                    selectedIndex: uiProvider.mobileTabIndex,
                    onDestinationSelected: uiProvider.setMobileTabIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const <Widget>[
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined, color: Colors.white70),
                        selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.tag_rounded, color: Colors.white70),
                        selectedIcon: Icon(Icons.tag_rounded, color: Colors.white),
                        label: 'Channels',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.mail_outline_rounded, color: Colors.white70),
                        selectedIcon: Icon(Icons.mail_rounded, color: Colors.white),
                        label: 'DMs',
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: isDesktopLayout
              ? Row(
                  children: <Widget>[
                    SizedBox(
                      width: 316,
                      child: WorkspaceSidebar(
                        currentUser: currentUser,
                        onChannelSelected: (String channelId) {
                          context.read<UIProvider>().selectChannel(
                                channelId: channelId,
                                chatProvider: chatProvider,
                              );
                        },
                        onDirectMessageSelected: (String userId) {
                          context.read<UIProvider>().selectDirectMessage(
                                userId: userId,
                                chatProvider: chatProvider,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ConversationPanel(
                        currentUser: currentUser,
                        activeChannel: activeChannel,
                        activeDmUser: activeDmUser,
                        filteredMessages: filteredMessages,
                        searchQuery: uiProvider.searchQuery,
                        scrollController: _scrollController,
                        onSend: (String text) {
                          if (activeChannel != null) {
                            context.read<ChatProvider>().sendChannelMessage(
                                  channelId: activeChannel.id,
                                  sender: currentUser,
                                  text: text,
                                );
                            _scheduleChannelReply(
                              channel: activeChannel,
                              currentUser: currentUser,
                              userMessage: text,
                            );
                          } else if (activeDmUser != null) {
                            context.read<ChatProvider>().sendDirectMessage(
                                  userId: activeDmUser.id,
                                  sender: currentUser,
                                  text: text,
                                );
                          }
                        },
                      ),
                    ),
                  ],
                )
              : MobileHomeView(
                  currentUser: currentUser,
                  activeChannel: activeChannel,
                  activeDmUser: activeDmUser,
                  mobileTabIndex: uiProvider.mobileTabIndex,
                  onOpenChannel: (String channelId) {
                    _openMobileChannelConversation(
                      channelId: channelId,
                      currentUser: currentUser,
                    );
                  },
                  onOpenDirectMessage: (String userId) {
                    _openMobileDirectConversation(
                      userId: userId,
                      currentUser: currentUser,
                    );
                  },
                ),
        ),
      ),
    );
  }

  List<Widget> _buildHomeActions({
    required BuildContext context,
    required bool showSearchButton,
    required String currentUserName,
  }) {
    final uiProvider = context.read<UIProvider>();

    return <Widget>[
      if (showSearchButton)
        IconButton(
          tooltip: uiProvider.isSearchVisible ? 'Close search' : 'Search messages',
          onPressed: () {
            if (uiProvider.isSearchVisible) {
              _searchController.clear();
              uiProvider.hideSearch();
              return;
            }

            uiProvider.showSearch();
          },
          icon: Icon(
            uiProvider.isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      PopupMenuButton<String>(
        offset: const Offset(0, 8),
        color: Colors.white,
        onSelected: (String value) async {
          if (value != 'logout') {
            return;
          }

          _searchController.clear();
          context.read<UIProvider>().hideSearch();
          await context.read<AuthProvider>().logout();
          if (!context.mounted) {
            return;
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                currentUserName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: <Widget>[
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 10),
                  Text('Log out'),
                ],
              ),
            ),
          ];
        },
      ),
      const SizedBox(width: 8),
    ];
  }

  void _scheduleScrollIfNeeded({
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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scheduleChannelReply({
    required ChatChannel channel,
    required AppUser currentUser,
    required String userMessage,
  }) {
    final responder = _pickChannelResponder(
      chatProvider: context.read<ChatProvider>(),
      currentUser: currentUser,
      userMessage: userMessage,
    );

    if (responder == null) {
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }

      final uiProvider = context.read<UIProvider>();
      final chatProvider = context.read<ChatProvider>();
      final isDesktopLayout = MediaQuery.of(context).size.width >= 940;
      final isActiveConversation = uiProvider.activeChannelId == channel.id &&
          uiProvider.activeDirectMessageUserId == null &&
          (isDesktopLayout || uiProvider.isMobileConversationOpen);

      chatProvider.receiveChannelMessage(
        channelId: channel.id,
        sender: responder,
        text: MockChatService.channelReplyFor(
          channelId: channel.id,
          userMessage: userMessage,
          responder: responder,
        ),
        markUnread: !isActiveConversation,
      );

      if (isActiveConversation) {
        chatProvider.markChannelAsRead(channel.id);
      }
    });
  }

  Future<void> _openMobileChannelConversation({
    required String channelId,
    required AppUser currentUser,
  }) async {
    final chatProvider = context.read<ChatProvider>();
    final channel = chatProvider.channelById(channelId);
    if (channel == null) {
      return;
    }

    context.read<UIProvider>().selectChannel(
          channelId: channelId,
          chatProvider: chatProvider,
        );
    context.read<UIProvider>().setMobileConversationOpen(true);

    if (!mounted) {
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MobileConversationScreen.channel(
            channelId: channelId,
            currentUser: currentUser,
            onSendChannelMessage: (String text) async {
              await context.read<ChatProvider>().sendChannelMessage(
                    channelId: channelId,
                    sender: currentUser,
                    text: text,
                  );
              _scheduleChannelReply(
                channel: channel,
                currentUser: currentUser,
                userMessage: text,
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        context.read<UIProvider>().setMobileConversationOpen(false);
      }
    }
  }

  Future<void> _openMobileDirectConversation({
    required String userId,
    required AppUser currentUser,
  }) async {
    final chatProvider = context.read<ChatProvider>();
    final teammate = chatProvider.directMessageUserById(userId);
    if (teammate == null) {
      return;
    }

    context.read<UIProvider>().selectDirectMessage(
          userId: userId,
          chatProvider: chatProvider,
        );
    context.read<UIProvider>().setMobileConversationOpen(true);

    if (!mounted) {
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MobileConversationScreen.direct(
            userId: userId,
            currentUser: currentUser,
            onSendDirectMessage: (String text) async {
              await context.read<ChatProvider>().sendDirectMessage(
                    userId: userId,
                    sender: currentUser,
                    text: text,
                  );
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        context.read<UIProvider>().setMobileConversationOpen(false);
      }
    }
  }

  AppUser? _pickChannelResponder({
    required ChatProvider chatProvider,
    required AppUser currentUser,
    required String userMessage,
  }) {
    final teammates = chatProvider.directMessageUsers
        .where((AppUser user) => user.id != currentUser.id)
        .toList();

    if (teammates.isEmpty) {
      return null;
    }

    return teammates[userMessage.trim().length % teammates.length];
  }
}



