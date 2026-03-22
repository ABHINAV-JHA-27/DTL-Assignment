import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class MeetingHeader extends StatelessWidget {
  const MeetingHeader({
    required this.roomCode,
    required this.username,
    required this.room,
    required this.onOpenChat,
    super.key,
  });

  final String roomCode;
  final String username;
  final lk.Room room;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedBuilder(
        animation: room,
        builder: (context, _) {
          final count = room.remoteParticipants.length + 1;
          final connectionMessage = switch (room.connectionState) {
            lk.ConnectionState.reconnecting => 'Reconnecting...',
            lk.ConnectionState.connecting => 'Connecting...',
            _ => null,
          };

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomCode,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Joined as $username',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('$count participants'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ],
              ),
              if (connectionMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x33F59E0B),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(connectionMessage),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
