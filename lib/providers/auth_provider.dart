import 'package:flutter/foundation.dart';
import 'package:slack_chat_app/models/app_user.dart';
import 'package:slack_chat_app/services/auth_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authStorageService);

  final AuthStorageService _authStorageService;

  AppUser? _currentUser;
  List<AppUser> _registeredUsers = <AppUser>[];
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  List<AppUser> get registeredUsers => List<AppUser>.unmodifiable(
        _registeredUsers,
      );

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    _registeredUsers = await _authStorageService.getRegisteredUsers();
    if (_registeredUsers.isEmpty) {
      _registeredUsers = const <AppUser>[
        AppUser(
          id: 'user-demo-ava',
          name: 'Ava Patel',
          email: 'ava@teamspace.dev',
          password: 'secret123',
        ),
        AppUser(
          id: 'user-sarah',
          name: 'Sarah Chen',
          email: 'sarah@teamspace.dev',
          password: 'secret123',
        ),
        AppUser(
          id: 'user-marcus',
          name: 'Marcus Reed',
          email: 'marcus@teamspace.dev',
          password: 'secret123',
        ),
        AppUser(
          id: 'user-olivia',
          name: 'Olivia Park',
          email: 'olivia@teamspace.dev',
          password: 'secret123',
        ),
        AppUser(
          id: 'user-jamal',
          name: 'Jamal Carter',
          email: 'jamal@teamspace.dev',
          password: 'secret123',
        ),
      ];
      await _authStorageService.saveRegisteredUsers(_registeredUsers);
    }

    _currentUser = await _authStorageService.getCurrentUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final normalizedPassword = password.trim();

    AppUser? matchedUser;
    for (final user in _registeredUsers) {
      final isMatch = user.email.toLowerCase() == normalizedIdentifier ||
          user.name.toLowerCase() == normalizedIdentifier;
      if (isMatch && user.password == normalizedPassword) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser == null) {
      return 'We could not find a matching account for those credentials.';
    }

    _currentUser = matchedUser;
    await _authStorageService.saveCurrentUser(matchedUser);
    notifyListeners();
    return null;
  }

  Future<String?> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();

    final emailExists = _registeredUsers.any(
      (AppUser user) => user.email.toLowerCase() == normalizedEmail,
    );
    if (emailExists) {
      return 'That email is already in use. Try logging in instead.';
    }

    final usernameExists = _registeredUsers.any(
      (AppUser user) => user.name.toLowerCase() == normalizedUsername,
    );
    if (usernameExists) {
      return 'That username is already taken. Pick a different one.';
    }

    final user = AppUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: username.trim(),
      email: normalizedEmail,
      password: password.trim(),
    );

    _registeredUsers = <AppUser>[..._registeredUsers, user];
    _currentUser = user;

    await _authStorageService.saveRegisteredUsers(_registeredUsers);
    await _authStorageService.saveCurrentUser(user);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _authStorageService.clearCurrentUser();
    notifyListeners();
  }
}
