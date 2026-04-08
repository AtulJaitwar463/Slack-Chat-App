import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slack_chat_app/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.highlightQuery,
    this.showSenderName = false,
  });

  final ChatMessage message;
  final String currentUserId;
  final String highlightQuery;
  final bool showSenderName;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.senderId == currentUserId;
    final baseColor = isCurrentUser ? const Color(0xFFF6EFF8) : Colors.white;
    final avatarBackground = _avatarColorFor(message.senderId, isCurrentUser);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: avatarBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsFor(message.senderName),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      isCurrentUser ? '${message.senderName} (you)' : message.senderName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF1D1C1D),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF767676),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    children: _buildHighlightedTextSpans(
                      text: message.text,
                      query: highlightQuery,
                      baseColor: const Color(0xFF1D1C1D),
                      isCurrentUser: isCurrentUser,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF1D1C1D),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
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

  List<TextSpan> _buildHighlightedTextSpans({
    required String text,
    required String query,
    required Color baseColor,
    required bool isCurrentUser,
  }) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return <TextSpan>[TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = normalizedQuery.toLowerCase();
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + normalizedQuery.length),
          style: TextStyle(
            color: baseColor,
            fontWeight: FontWeight.w800,
            backgroundColor: isCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFFFE08A),
          ),
        ),
      );

      start = index + normalizedQuery.length;
    }

    return spans;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return DateFormat('h:mm a').format(timestamp);
    }

    return DateFormat('MMM d').add_jm().format(timestamp);
  }

  Color _avatarColorFor(String senderId, bool isCurrentUser) {
    if (isCurrentUser) {
      return const Color(0xFF611F69);
    }

    const palette = <Color>[
      Color(0xFF1264A3),
      Color(0xFF007A5A),
      Color(0xFF9F1853),
      Color(0xFFB16200),
      Color(0xFF2C6B2F),
    ];
    return palette[senderId.hashCode.abs() % palette.length];
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
