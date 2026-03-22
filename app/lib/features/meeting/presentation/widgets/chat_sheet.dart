import 'package:flutter/material.dart';

import '../../data/models/chat_message.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({
    required this.messages,
    required this.onSendMessage,
    super.key,
  });

  final List<ChatMessage> messages;
  final ValueChanged<String> onSendMessage;

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Meeting Chat',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Start the conversation.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final message = widget.messages[index];
                        final alignment = message.isLocalUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft;

                        return Align(
                          alignment: alignment,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: message.isLocalUser
                                  ? const Color(0xFF14B8A6)
                                  : const Color(0xFF17293C),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: message.isLocalUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.sender,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(message.message),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () => _send(_controller.text),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _send(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return;
    }

    widget.onSendMessage(text);
    _controller.clear();
  }
}
