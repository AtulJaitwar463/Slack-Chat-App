import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/providers/auth_provider.dart';
import 'package:slack_chat_app/providers/chat_provider.dart';
import 'package:slack_chat_app/providers/ui_provider.dart';
import 'package:slack_chat_app/screens/auth_gate.dart';
import 'package:slack_chat_app/services/auth_storage_service.dart';
import 'package:slack_chat_app/services/chat_storage_service.dart';
import 'package:slack_chat_app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authStorageService = AuthStorageService();
  await authStorageService.init();
  final chatStorageService = ChatStorageService();
  await chatStorageService.init();

  runApp(
    SlackChatApp(
      authStorageService: authStorageService,
      chatStorageService: chatStorageService,
    ),
  );
}

class SlackChatApp extends StatelessWidget {
  const SlackChatApp({
    super.key,
    required this.authStorageService,
    required this.chatStorageService,
  });

  final AuthStorageService authStorageService;
  final ChatStorageService chatStorageService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authStorageService)..restoreSession(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(chatStorageService),
          update: (_, AuthProvider authProvider, ChatProvider? chatProvider) =>
              chatProvider!
                ..syncWithAuth(
                  currentUser: authProvider.currentUser,
                  registeredUsers: authProvider.registeredUsers,
                ),
        ),
        ChangeNotifierProvider<UIProvider>(
          create: (_) => UIProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Teamspace Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
