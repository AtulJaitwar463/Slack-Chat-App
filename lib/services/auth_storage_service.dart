import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:slack_chat_app/models/app_user.dart';

class AuthStorageService {
  static const String _currentUserKey = 'current_user';
  static const String _registeredUsersKey = 'registered_users';

  SharedPreferences? _preferences;

  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<AppUser>> getRegisteredUsers() async {
    await init();

    final storedUsers = _preferences?.getString(_registeredUsersKey);
    if (storedUsers == null || storedUsers.isEmpty) {
      return <AppUser>[];
    }

    final decoded = jsonDecode(storedUsers) as List<dynamic>;
    return decoded
        .map((dynamic item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRegisteredUsers(List<AppUser> users) async {
    await init();

    final payload = jsonEncode(
      users.map((AppUser user) => user.toJson()).toList(),
    );
    await _preferences?.setString(_registeredUsersKey, payload);
  }

  Future<AppUser?> getCurrentUser() async {
    await init();

    final storedUser = _preferences?.getString(_currentUserKey);
    if (storedUser == null || storedUser.isEmpty) {
      return null;
    }

    return AppUser.fromJson(
      jsonDecode(storedUser) as Map<String, dynamic>,
    );
  }

  Future<void> saveCurrentUser(AppUser user) async {
    await init();

    await _preferences?.setString(
      _currentUserKey,
      jsonEncode(user.toJson()),
    );
  }

  Future<void> clearCurrentUser() async {
    await init();
    await _preferences?.remove(_currentUserKey);
  }
}
