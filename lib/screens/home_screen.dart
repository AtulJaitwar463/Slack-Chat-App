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
import 'package:slack_chat_app/widgets/chat_bubble.dart';
import 'package:slack_chat_app/widgets/channel_tile.dart';
import 'package:slack_chat_app/widgets/message_input_box.dart';
import 'package:slack_chat_app/widgets/user_tile.dart';

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
      backgroundColor: const Color(0xFFF4F4F8),
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
                          color: const Color(0xFFF8F8FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD8D8DE),
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
                              color: Color(0xFF1D1C1D),
                            ),
                          ),
                          Text(
                            activeChannel != null
                                ? '#${activeChannel.name}'
                                : activeDmUser != null
                                    ? activeDmUser.name
                                    : 'Workspace',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF616061),
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
              title: _MobileHeaderTitle(
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
                    backgroundColor: const Color(0xFF4A154B),
                    indicatorColor: const Color(0xFF611F69),
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
                      child: _WorkspaceSidebar(
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
                      child: _ConversationPanel(
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
              : _MobileHomeView(
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
            color: const Color(0xFF1D1C1D),
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
          builder: (_) => _MobileConversationScreen.channel(
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
          builder: (_) => _MobileConversationScreen.direct(
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

class _MobileHomeView extends StatelessWidget {
  const _MobileHomeView({
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
      return _MobileDashboard(
        currentUser: currentUser,
        activeChannel: activeChannel,
        activeDmUser: activeDmUser,
        onOpenChannel: onOpenChannel,
        onOpenDirectMessage: onOpenDirectMessage,
      );
    }

    if (mobileTabIndex == 1) {
      return _MobileListPanel(
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

    return _MobileListPanel(
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

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
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
              color: const Color(0xFF4A154B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
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
                        color: const Color(0xFF1264A3),
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
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your workspace is ready.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFFD8C1DB),
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
                      child: _DashboardStatCard(
                        label: 'Channels',
                        value: '${chatProvider.channels.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashboardStatCard(
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
          _QuickLaunchCard(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x12000000),
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
                        color: const Color(0xFF1D1C1D),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Open your most active spaces.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF616061),
                      ),
                ),
                const SizedBox(height: 16),
                ...chatProvider.channels.take(3).map(
                  (ChatChannel channel) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LightChannelTile(
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

class _MobileListPanel extends StatelessWidget {
  const _MobileListPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF4A154B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD8C1DB),
                  ),
            ),
            const SizedBox(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MobileHeaderTitle extends StatelessWidget {
  const _MobileHeaderTitle({
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
                color: const Color(0xFF1D1C1D),
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF616061),
              ),
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFD8C1DB),
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickLaunchCard extends StatelessWidget {
  const _QuickLaunchCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE7E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1D1C1D),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF616061),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LightChannelTile extends StatelessWidget {
  const _LightChannelTile({
    required this.channel,
    required this.unreadCount,
    required this.onTap,
  });

  final ChatChannel channel;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E3E8)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EAF4),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                '#',
                style: TextStyle(
                  color: Color(0xFF611F69),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '#${channel.name}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1D1C1D),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    channel.topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF616061),
                        ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF611F69),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unreadCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileConversationScreen extends StatefulWidget {
  const _MobileConversationScreen.channel({
    required this.channelId,
    required this.currentUser,
    required this.onSendChannelMessage,
  })  : userId = null,
        onSendDirectMessage = null;

  const _MobileConversationScreen.direct({
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
  State<_MobileConversationScreen> createState() =>
      _MobileConversationScreenState();
}

class _MobileConversationScreenState extends State<_MobileConversationScreen> {
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
        : messages
            .where(
              (ChatMessage message) =>
                  message.text.toLowerCase().contains(_query.trim().toLowerCase()),
            )
            .toList();

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
      backgroundColor: const Color(0xFFF4F4F8),
      appBar: AppBar(
        leadingWidth: 34,
        titleSpacing: 10,
        title: _isSearchMode
            ? Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FB),
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
                      color: _isChannel
                          ? const Color(0xFFF1EAF4)
                          : const Color(0xFFE8EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isChannel ? Icons.tag_rounded : Icons.person_rounded,
                      color: _isChannel
                          ? const Color(0xFF611F69)
                          : const Color(0xFF1264A3),
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
                                color: const Color(0xFF1D1C1D),
                              ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF616061),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
              ),
              child: filteredMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.trim().isNotEmpty
                              ? 'No message matched "$_query".'
                              : 'Start the conversation.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF616061),
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

class _WorkspaceSidebar extends StatelessWidget {
  const _WorkspaceSidebar({
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
        color: const Color(0xFF4A154B),
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
                      color: const Color(0xFF1264A3),
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
                                color: const Color(0xFFD8C1DB),
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
                    color: const Color(0xFFD8C1DB),
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
                    color: const Color(0xFFD8C1DB),
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

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
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
                bottom: BorderSide(
                  color: Color(0xFFE6E6EA),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeChannel != null
                        ? const Color(0xFFF1EAF4)
                        : const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    activeChannel != null ? Icons.tag_rounded : Icons.person_rounded,
                    color: activeChannel != null
                        ? const Color(0xFF611F69)
                        : const Color(0xFF1264A3),
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
                              color: const Color(0xFF1D1C1D),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF616061),
                            ),
                      ),
                    ],
                  ),
                ),
                if (searchQuery.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAF4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${filteredMessages.length} match${filteredMessages.length == 1 ? '' : 'es'}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF611F69),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFFFFFFF),
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
                                color: const Color(0xFF616061),
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
