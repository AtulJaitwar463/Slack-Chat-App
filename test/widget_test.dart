import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slack_chat_app/main.dart';
import 'package:slack_chat_app/services/auth_storage_service.dart';
import 'package:slack_chat_app/services/chat_storage_service.dart';

void main() {
  testWidgets('shows login screen when no persisted session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final authStorageService = AuthStorageService();
    final chatStorageService = ChatStorageService();
    await authStorageService.init();
    await chatStorageService.init();

    await tester.pumpWidget(
      SlackChatApp(
        authStorageService: authStorageService,
        chatStorageService: chatStorageService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
