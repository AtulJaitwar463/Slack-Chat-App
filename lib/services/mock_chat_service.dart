import 'package:slack_chat_app/models/app_user.dart';

class MockChatService {
  static String channelReplyFor({
    required String channelId,
    required String userMessage,
    required AppUser responder,
  }) {
    final repliesByChannel = <String, List<String>>{
      'general': <String>[
        'Thanks for the update. I will make sure the wider team sees this.',
        'Great momentum here. This feels ready for the next handoff.',
        'Helpful context. I am sharing this in the launch thread too.',
      ],
      'random': <String>[
        'That definitely improved the vibe in here.',
        'Strong contribution to the channel chaos, in the best way.',
        'Saving this one for the team roundup.',
      ],
      'dev': <String>[
        'I checked the latest build and this lines up with what I am seeing.',
        'Good catch. I can take a quick pass on the implementation side.',
        'This should unblock the next PR nicely.',
      ],
      'design': <String>[
        'This matches the visual direction really well.',
        'I like this. The spacing and hierarchy feel stronger now.',
        'Nice improvement. I can polish the final pass after this.',
      ],
    };

    final replies = repliesByChannel[channelId] ??
        <String>[
          '${responder.name} is aligned on this.',
          'Looks good from here.',
          'Let us keep it moving.',
        ];

    return replies[_safeIndex(userMessage, replies.length)];
  }

  static int _safeIndex(String text, int length) {
    return text.trim().isEmpty ? 0 : text.trim().length % length;
  }
}
