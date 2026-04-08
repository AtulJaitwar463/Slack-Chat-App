import 'package:flutter/foundation.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/models/chat_channel.dart';
import 'package:slack_chat_app/models/chat_message.dart';
import 'package:slack_chat_app/services/chat_storage_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._chatStorageService) {
    _channels = const <ChatChannel>[
      ChatChannel(
        id: 'general',
        name: 'general',
        topic: 'Company-wide updates, launches, and celebrations.',
      ),
      ChatChannel(
        id: 'random',
        name: 'random',
        topic: 'Ideas, memes, and quick team energy boosts.',
      ),
      ChatChannel(
        id: 'dev',
        name: 'dev',
        topic: 'Frontend, backend, release notes, and blockers.',
      ),
      ChatChannel(
        id: 'design',
        name: 'design',
        topic: 'Mocks, reviews, polish passes, and motion studies.',
      ),
    ];

    _channelMessages = _seedChannelMessages();
    _directMessages = _seedDirectMessages();
    _channelUnreadCounts = <String, int>{};
    _dmUnreadCounts = <String, int>{};
    _restorePersistedState();
  }

  final ChatStorageService _chatStorageService;

  late final List<ChatChannel> _channels;
  late Map<String, List<ChatMessage>> _channelMessages;
  late Map<String, List<ChatMessage>> _directMessages;
  late Map<String, int> _channelUnreadCounts;
  late Map<String, int> _dmUnreadCounts;

  AppUser? _currentUser;
  List<AppUser> _registeredUsers = <AppUser>[];

  List<ChatChannel> get channels => List<ChatChannel>.unmodifiable(_channels);

  List<AppUser> get directMessageUsers {
    final currentUserId = _currentUser?.id;
    final users = _registeredUsers
        .where((AppUser user) => user.id != currentUserId)
        .toList()
      ..sort((AppUser a, AppUser b) => a.name.compareTo(b.name));
    return List<AppUser>.unmodifiable(users);
  }

  void syncWithAuth({
    required AppUser? currentUser,
    required List<AppUser> registeredUsers,
  }) {
    _currentUser = currentUser;
    _registeredUsers = List<AppUser>.from(registeredUsers);
    notifyListeners();
  }

  ChatChannel? channelById(String id) {
    for (final channel in _channels) {
      if (channel.id == id) {
        return channel;
      }
    }
    return null;
  }

  AppUser? directMessageUserById(String id) {
    for (final user in directMessageUsers) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  List<ChatMessage> messagesForChannel(String channelId) {
    return List<ChatMessage>.unmodifiable(
      _channelMessages[channelId] ?? const <ChatMessage>[],
    );
  }

  List<ChatMessage> messagesForDirectMessage(String userId) {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) {
      return const <ChatMessage>[];
    }

    return List<ChatMessage>.unmodifiable(
      _directMessages[_conversationKey(currentUserId, userId)] ??
          const <ChatMessage>[],
    );
  }

  int unreadChannelCount(String channelId) {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) {
      return 0;
    }

    return _channelUnreadCounts[_channelUnreadKey(currentUserId, channelId)] ?? 0;
  }

  int unreadDirectMessageCount(String userId) {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) {
      return 0;
    }

    return _dmUnreadCounts[_directUnreadKey(currentUserId, userId)] ?? 0;
  }

  Future<void> sendChannelMessage({
    required String channelId,
    required AppUser sender,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    _channelMessages.putIfAbsent(channelId, () => <ChatMessage>[]).add(
          ChatMessage(
            id: 'channel-${DateTime.now().microsecondsSinceEpoch}',
            senderId: sender.id,
            senderName: sender.name,
            text: trimmedText,
            timestamp: DateTime.now(),
          ),
        );

    for (final user in _registeredUsers) {
      final unreadKey = _channelUnreadKey(user.id, channelId);
      if (user.id == sender.id) {
        _channelUnreadCounts[unreadKey] = 0;
      } else {
        _channelUnreadCounts[unreadKey] = (_channelUnreadCounts[unreadKey] ?? 0) + 1;
      }
    }

    await _persistChannels();
    notifyListeners();
  }

  Future<void> sendDirectMessage({
    required String userId,
    required AppUser sender,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final conversationKey = _conversationKey(sender.id, userId);
    _directMessages.putIfAbsent(conversationKey, () => <ChatMessage>[]).add(
          ChatMessage(
            id: 'dm-${DateTime.now().microsecondsSinceEpoch}',
            senderId: sender.id,
            senderName: sender.name,
            text: trimmedText,
            timestamp: DateTime.now(),
          ),
        );

    _dmUnreadCounts[_directUnreadKey(sender.id, userId)] = 0;
    _dmUnreadCounts[_directUnreadKey(userId, sender.id)] =
        (_dmUnreadCounts[_directUnreadKey(userId, sender.id)] ?? 0) + 1;

    await _persistDirectMessages();
    notifyListeners();
  }

  Future<void> receiveChannelMessage({
    required String channelId,
    required AppUser sender,
    required String text,
    bool markUnread = true,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    _channelMessages.putIfAbsent(channelId, () => <ChatMessage>[]).add(
          ChatMessage(
            id: 'channel-reply-${DateTime.now().microsecondsSinceEpoch}',
            senderId: sender.id,
            senderName: sender.name,
            text: trimmedText,
            timestamp: DateTime.now(),
          ),
        );

    for (final user in _registeredUsers) {
      final unreadKey = _channelUnreadKey(user.id, channelId);
      if (user.id == sender.id) {
        _channelUnreadCounts[unreadKey] = 0;
      } else if (markUnread) {
        _channelUnreadCounts[unreadKey] = (_channelUnreadCounts[unreadKey] ?? 0) + 1;
      }
    }

    await _persistChannels();
    notifyListeners();
  }

  Future<void> markChannelAsRead(String channelId) async {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) {
      return;
    }

    final unreadKey = _channelUnreadKey(currentUserId, channelId);
    if ((_channelUnreadCounts[unreadKey] ?? 0) == 0) {
      return;
    }

    _channelUnreadCounts[unreadKey] = 0;
    await _chatStorageService.saveChannelUnreadCounts(_channelUnreadCounts);
    notifyListeners();
  }

  Future<void> markDirectMessageAsRead(String userId) async {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) {
      return;
    }

    final unreadKey = _directUnreadKey(currentUserId, userId);
    if ((_dmUnreadCounts[unreadKey] ?? 0) == 0) {
      return;
    }

    _dmUnreadCounts[unreadKey] = 0;
    await _chatStorageService.saveDirectUnreadCounts(_dmUnreadCounts);
    notifyListeners();
  }

  Future<void> _restorePersistedState() async {
    final channelMessages = await _chatStorageService.getChannelMessages();
    final directMessages = await _chatStorageService.getDirectMessages();
    final channelUnreadCounts = await _chatStorageService.getChannelUnreadCounts();
    final directUnreadCounts = await _chatStorageService.getDirectUnreadCounts();

    if (channelMessages.isNotEmpty) {
      _channelMessages = channelMessages;
    }

    if (directMessages.isNotEmpty) {
      _directMessages = directMessages;
    }

    if (channelUnreadCounts.isNotEmpty) {
      _channelUnreadCounts = channelUnreadCounts;
    }

    if (directUnreadCounts.isNotEmpty) {
      _dmUnreadCounts = directUnreadCounts;
    }

    notifyListeners();
  }

  Future<void> _persistChannels() async {
    await _chatStorageService.saveChannelMessages(_channelMessages);
    await _chatStorageService.saveChannelUnreadCounts(_channelUnreadCounts);
  }

  Future<void> _persistDirectMessages() async {
    await _chatStorageService.saveDirectMessages(_directMessages);
    await _chatStorageService.saveDirectUnreadCounts(_dmUnreadCounts);
  }

  Map<String, List<ChatMessage>> _seedChannelMessages() {
    final now = DateTime.now();
    return <String, List<ChatMessage>>{
      'general': <ChatMessage>[
        ChatMessage(
          id: 'g-1',
          senderId: 'user-sarah',
          senderName: 'Sarah Chen',
          text:
              'Morning team. The customer onboarding refresh ships this afternoon.',
          timestamp: now.subtract(const Duration(hours: 4, minutes: 30)),
        ),
        ChatMessage(
          id: 'g-2',
          senderId: 'user-marcus',
          senderName: 'Marcus Reed',
          text:
              'Support docs are updated. I added the final screenshots to the launch brief.',
          timestamp: now.subtract(const Duration(hours: 4, minutes: 12)),
        ),
        ChatMessage(
          id: 'g-3',
          senderId: 'user-olivia',
          senderName: 'Olivia Park',
          text:
              'Design QA looks clean on tablet. Only one hover state needs a tiny spacing tweak.',
          timestamp: now.subtract(const Duration(hours: 3, minutes: 54)),
        ),
      ],
      'random': <ChatMessage>[
        ChatMessage(
          id: 'r-1',
          senderId: 'user-jamal',
          senderName: 'Jamal Carter',
          text:
              'Friday playlist is live. Drop one song that helps you focus when the sprint gets loud.',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
        ),
        ChatMessage(
          id: 'r-2',
          senderId: 'user-sarah',
          senderName: 'Sarah Chen',
          text:
              'Also: office coffee machine survived another week. Feels like a small miracle.',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
        ),
      ],
      'dev': <ChatMessage>[
        ChatMessage(
          id: 'd-1',
          senderId: 'user-marcus',
          senderName: 'Marcus Reed',
          text:
              'Release candidate is green on Android and Web. I am watching iOS one more time.',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 26)),
        ),
        ChatMessage(
          id: 'd-2',
          senderId: 'user-jamal',
          senderName: 'Jamal Carter',
          text:
              'The message composer now keeps draft state on navigation. Nice win for usability.',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 8)),
        ),
        ChatMessage(
          id: 'd-3',
          senderId: 'user-sarah',
          senderName: 'Sarah Chen',
          text:
              'Can someone sanity-check the analytics event names before I tag the release?',
          timestamp: now.subtract(const Duration(minutes: 42)),
        ),
      ],
      'design': <ChatMessage>[
        ChatMessage(
          id: 'ds-1',
          senderId: 'user-olivia',
          senderName: 'Olivia Park',
          text:
              'Uploaded the motion pass for the sidebar and tightened the unread badge contrast.',
          timestamp: now.subtract(const Duration(hours: 3, minutes: 12)),
        ),
      ],
    };
  }

  Map<String, List<ChatMessage>> _seedDirectMessages() {
    final now = DateTime.now();
    return <String, List<ChatMessage>>{
      _conversationKey('user-demo-ava', 'user-sarah'): <ChatMessage>[
        ChatMessage(
          id: 'dm-a-s-1',
          senderId: 'user-sarah',
          senderName: 'Sarah Chen',
          text:
              'Could you give the launch copy one final pass when you have ten minutes?',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 44)),
        ),
        ChatMessage(
          id: 'dm-a-s-2',
          senderId: 'user-demo-ava',
          senderName: 'Ava Patel',
          text: 'Yes, I can review it before lunch and send back edits.',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        ),
      ],
      _conversationKey('user-demo-ava', 'user-marcus'): <ChatMessage>[
        ChatMessage(
          id: 'dm-a-m-1',
          senderId: 'user-marcus',
          senderName: 'Marcus Reed',
          text: 'Heads-up: staging is refreshed and ready for your smoke test.',
          timestamp: now.subtract(const Duration(minutes: 58)),
        ),
      ],
      _conversationKey('user-demo-ava', 'user-olivia'): <ChatMessage>[
        ChatMessage(
          id: 'dm-a-o-1',
          senderId: 'user-olivia',
          senderName: 'Olivia Park',
          text:
              'I left two layout options in Figma. The bolder one feels more like the product direction.',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 6)),
        ),
      ],
      _conversationKey('user-demo-ava', 'user-jamal'): <ChatMessage>[
        ChatMessage(
          id: 'dm-a-j-1',
          senderId: 'user-jamal',
          senderName: 'Jamal Carter',
          text:
              'The API logs are calm again. Appreciate the quick report earlier.',
          timestamp: now.subtract(const Duration(minutes: 35)),
        ),
      ],
    };
  }

  static String _conversationKey(String firstUserId, String secondUserId) {
    final pair = <String>[firstUserId, secondUserId]..sort();
    return pair.join('__');
  }

  static String _channelUnreadKey(String userId, String channelId) {
    return '$userId::$channelId';
  }

  static String _directUnreadKey(String ownerUserId, String otherUserId) {
    return '$ownerUserId::$otherUserId';
  }
}
