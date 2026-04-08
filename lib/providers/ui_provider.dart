import 'package:flutter/foundation.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';

class UIProvider extends ChangeNotifier {
  String? _activeChannelId;
  String? _activeDirectMessageUserId;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  String? _sessionUserId;
  int _mobileTabIndex = 0;
  bool _isMobileConversationOpen = false;

  String? get activeChannelId => _activeChannelId;
  String? get activeDirectMessageUserId => _activeDirectMessageUserId;
  bool get isSearchVisible => _isSearchVisible;
  String get searchQuery => _searchQuery;
  int get mobileTabIndex => _mobileTabIndex;
  bool get isMobileConversationOpen => _isMobileConversationOpen;

  void syncForUser({
    required String userId,
    required ChatProvider chatProvider,
  }) {
    if (_sessionUserId != userId) {
      _sessionUserId = userId;
      _activeChannelId = null;
      _activeDirectMessageUserId = null;
      _isSearchVisible = false;
      _searchQuery = '';
      _mobileTabIndex = 0;
      _isMobileConversationOpen = false;
    }

    final activeChannelStillExists = _activeChannelId == null
        ? false
        : chatProvider.channelById(_activeChannelId!) != null;
    final activeDirectStillExists = _activeDirectMessageUserId == null
        ? false
        : chatProvider.directMessageUserById(_activeDirectMessageUserId!) != null;

    if (!activeChannelStillExists && !activeDirectStillExists) {
      _activeChannelId = null;
      _activeDirectMessageUserId = null;
      _isSearchVisible = false;
      _searchQuery = '';
    }

    ensureSelection(chatProvider);
  }

  void ensureSelection(ChatProvider chatProvider) {
    if (_activeChannelId != null || _activeDirectMessageUserId != null) {
      return;
    }

    if (chatProvider.channels.isEmpty) {
      return;
    }

    _activeChannelId = chatProvider.channels.first.id;
    _activeDirectMessageUserId = null;
    chatProvider.markChannelAsRead(_activeChannelId!);
    notifyListeners();
  }

  void selectChannel({
    required String channelId,
    required ChatProvider chatProvider,
  }) {
    _activeChannelId = channelId;
    _activeDirectMessageUserId = null;
    chatProvider.markChannelAsRead(channelId);
    notifyListeners();
  }

  void selectDirectMessage({
    required String userId,
    required ChatProvider chatProvider,
  }) {
    _activeChannelId = null;
    _activeDirectMessageUserId = userId;
    chatProvider.markDirectMessageAsRead(userId);
    notifyListeners();
  }

  void setMobileTabIndex(int value) {
    if (_mobileTabIndex == value) {
      return;
    }

    _mobileTabIndex = value;
    notifyListeners();
  }

  void setMobileConversationOpen(bool value) {
    if (_isMobileConversationOpen == value) {
      return;
    }

    _isMobileConversationOpen = value;
    notifyListeners();
  }

  void showSearch() {
    if (_isSearchVisible) {
      return;
    }

    _isSearchVisible = true;
    notifyListeners();
  }

  void hideSearch() {
    if (!_isSearchVisible && _searchQuery.isEmpty) {
      return;
    }

    _isSearchVisible = false;
    _searchQuery = '';
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }
}
