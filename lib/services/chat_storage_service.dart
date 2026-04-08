import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:slack_chat_app/models/chat_message.dart';

class ChatStorageService {
  static const String _channelMessagesKey = 'channel_messages';
  static const String _directMessagesKey = 'direct_messages';
  static const String _channelUnreadCountsKey = 'channel_unread_counts';
  static const String _directUnreadCountsKey = 'direct_unread_counts';

  SharedPreferences? _preferences;

  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, List<ChatMessage>>> getChannelMessages() async {
    await init();
    return _decodeMessageMap(
      _preferences?.getString(_channelMessagesKey),
    );
  }

  Future<void> saveChannelMessages(
    Map<String, List<ChatMessage>> messages,
  ) async {
    await init();
    await _preferences?.setString(
      _channelMessagesKey,
      jsonEncode(_encodeMessageMap(messages)),
    );
  }

  Future<Map<String, List<ChatMessage>>> getDirectMessages() async {
    await init();
    return _decodeMessageMap(
      _preferences?.getString(_directMessagesKey),
    );
  }

  Future<void> saveDirectMessages(
    Map<String, List<ChatMessage>> messages,
  ) async {
    await init();
    await _preferences?.setString(
      _directMessagesKey,
      jsonEncode(_encodeMessageMap(messages)),
    );
  }

  Future<Map<String, int>> getChannelUnreadCounts() async {
    await init();
    return _decodeUnreadMap(
      _preferences?.getString(_channelUnreadCountsKey),
    );
  }

  Future<void> saveChannelUnreadCounts(Map<String, int> unreadCounts) async {
    await init();
    await _preferences?.setString(
      _channelUnreadCountsKey,
      jsonEncode(unreadCounts),
    );
  }

  Future<Map<String, int>> getDirectUnreadCounts() async {
    await init();
    return _decodeUnreadMap(
      _preferences?.getString(_directUnreadCountsKey),
    );
  }

  Future<void> saveDirectUnreadCounts(Map<String, int> unreadCounts) async {
    await init();
    await _preferences?.setString(
      _directUnreadCountsKey,
      jsonEncode(unreadCounts),
    );
  }

  Map<String, dynamic> _encodeMessageMap(
    Map<String, List<ChatMessage>> messages,
  ) {
    return messages.map(
      (String key, List<ChatMessage> value) => MapEntry(
        key,
        value.map((ChatMessage message) => message.toJson()).toList(),
      ),
    );
  }

  Map<String, List<ChatMessage>> _decodeMessageMap(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <String, List<ChatMessage>>{};
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return decoded.map(
      (String key, dynamic value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map(
              (dynamic item) =>
                  ChatMessage.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
  }

  Map<String, int> _decodeUnreadMap(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <String, int>{};
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return decoded.map(
      (String key, dynamic value) => MapEntry(key, value as int),
    );
  }
}
