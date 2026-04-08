import 'package:flutter/material.dart';

class MessageInputBox extends StatefulWidget {
  const MessageInputBox({
    super.key,
    required this.hintText,
    required this.onSend,
  });

  final String hintText;
  final ValueChanged<String> onSend;

  @override
  State<MessageInputBox> createState() => _MessageInputBoxState();
}

class _MessageInputBoxState extends State<MessageInputBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE6E6EA)),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8D8DE)),
        ),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Color(0xFF8D8C8D)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              ),
              onSubmitted: (_) => _send(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: <Widget>[
                  _ComposerIconButton(
                    icon: Icons.add_circle_outline_rounded,
                    onTap: () {},
                  ),
                  _ComposerIconButton(
                    icon: Icons.format_bold_rounded,
                    onTap: () {},
                  ),
                  _ComposerIconButton(
                    icon: Icons.link_rounded,
                    onTap: () {},
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _send,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      backgroundColor: const Color(0xFF611F69),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    widget.onSend(text);
    _controller.clear();
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      icon: Icon(
        icon,
        size: 18,
        color: const Color(0xFF6A696A),
      ),
    );
  }
}
