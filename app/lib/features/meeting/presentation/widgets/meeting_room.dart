import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../cubit/meeting_cubit.dart';
import '../cubit/meeting_state.dart';
import 'chat_sheet.dart';
import 'control_bar.dart';
import 'participant_tile.dart';

class MeetingRoom extends StatelessWidget {
  const MeetingRoom({
    required this.roomCode,
    required this.username,
    required this.room,
    required this.isMicrophoneEnabled,
    required this.isCameraEnabled,
    required this.onToggleMicrophone,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onDisconnect,
    required this.onSendMessage,
    super.key,
  });

  final String roomCode;
  final String username;
  final Room room;
  final bool isMicrophoneEnabled;
  final bool isCameraEnabled;
  final Future<void> Function() onToggleMicrophone;
  final Future<void> Function() onToggleCamera;
  final Future<void> Function() onSwitchCamera;
  final Future<void> Function() onDisconnect;
  final ValueChanged<String> onSendMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF020611),
                    Color(0xFF07111B),
                    Color(0xFF0E2237),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _RoomHeader(
                  roomCode: roomCode,
                  username: username,
                  room: room,
                  onOpenChat: () => _openChat(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedBuilder(
                      animation: room,
                      builder: (context, _) {
                        final participants = _participants(room);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = _columnCount(
                              width: constraints.maxWidth,
                              participantCount: participants.length,
                            );

                            return GridView.builder(
                              padding: const EdgeInsets.only(top: 12, bottom: 12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: participants.length,
                              itemBuilder: (context, index) {
                                final participant = participants[index];
                                return ParticipantTile(
                                  participant: participant,
                                  isLocal: participant is LocalParticipant,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                MeetingControlBar(
                  isMicrophoneEnabled: isMicrophoneEnabled,
                  isCameraEnabled: isCameraEnabled,
                  onToggleMicrophone: onToggleMicrophone,
                  onToggleCamera: onToggleCamera,
                  onSwitchCamera: onSwitchCamera,
                  onOpenChat: () => _openChat(context),
                  onDisconnect: onDisconnect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Participant> _participants(Room room) {
    final participants = <Participant>[];
    final local = room.localParticipant;

    if (local != null) {
      participants.add(local);
    }

    participants.addAll(room.remoteParticipants.values);
    return participants;
  }

  int _columnCount({
    required double width,
    required int participantCount,
  }) {
    if (participantCount <= 1) {
      return 1;
    }

    if (width > 1100 && participantCount > 4) {
      return 3;
    }

    if (width > 720) {
      return 2;
    }

    return 1;
  }

  Future<void> _openChat(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
        backgroundColor: const Color(0xFF08111B),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.82,
        child: BlocBuilder<MeetingCubit, MeetingState>(
          builder: (context, state) {
            return ChatSheet(
              messages: state.messages,
              onSendMessage: onSendMessage,
            );
          },
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.roomCode,
    required this.username,
    required this.room,
    required this.onOpenChat,
  });

  final String roomCode;
  final String username;
  final Room room;
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
            ConnectionState.reconnecting => 'Reconnecting...',
            ConnectionState.connecting => 'Connecting...',
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
                      color: Colors.white.withOpacity(0.08),
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
