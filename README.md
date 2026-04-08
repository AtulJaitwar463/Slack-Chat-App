# Slack Chat App

Slack-like chat UI built with Flutter. The app includes local auth, channels, direct messages, unread badges, message search, responsive layouts, and a premium workspace-style UI.

## Tech Stack

- Flutter
- Provider for state management
- SharedPreferences for local persistence

## State Management

The app uses `provider` with separate app-level providers:

- `AuthProvider`: login, signup, logout, current user, local auth session
- `ChatProvider`: channels, direct messages, local message storage, unread counts
- `UIProvider`: active channel/DM selection, search state, mobile navigation state

## Project Structure

```text
lib/
├── models/
├── providers/
├── screens/
├── services/
├── theme/
├── widgets/
└── main.dart
```

## Features

- Login and signup with local validation
- Session persistence using SharedPreferences
- Slack-style home layout with channels and direct messages
- Same-device multi-user chat simulation
- Channel chat and one-to-one DMs
- Unread/read state handling
- Message search with highlighting
- Splash screen and responsive mobile/desktop UI

## Setup Instructions

1. Make sure Flutter stable is installed.
2. Clone the repository.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Useful Commands

```bash
flutter analyze
flutter test
```

## Demo Accounts

These seeded local accounts are available for quick testing:

- `ava@teamspace.dev`
- `sarah@teamspace.dev`
- `marcus@teamspace.dev`
- `olivia@teamspace.dev`
- `jamal@teamspace.dev`

Password for all demo accounts:

```text
secret123
```

## Notes

- This project simulates multi-user chat on the same device.
- No backend is used in the current version.
