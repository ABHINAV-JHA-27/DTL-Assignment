import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../cubit/meeting_cubit.dart';
import '../cubit/meeting_state.dart';
import 'chat_sheet.dart';
import 'control_bar.dart';
import 'meeting_header.dart';
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
  final lk.Room room;
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
                MeetingHeader(
                  roomCode: roomCode,
                  username: username,
                  room: room,
                  onOpenChat: () => _openChat(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AnimatedBuilder(
                      animation: room,
                      builder: (context, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final localParticipant = room.localParticipant;
                            final remoteParticipants =
                                _remoteParticipants(room);
                            final showFloatingPreview =
                                localParticipant != null &&
                                remoteParticipants.isNotEmpty;
                            final previewWidth = _localPreviewWidth(
                              constraints.maxWidth,
                            );

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: _ParticipantStage(
                                    remoteParticipants: remoteParticipants,
                                    localParticipant: localParticipant,
                                    maxWidth: constraints.maxWidth,
                                    maxHeight: constraints.maxHeight,
                                  ),
                                ),
                                if (showFloatingPreview)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: SizedBox(
                                      width: previewWidth,
                                      child: AspectRatio(
                                        aspectRatio: 0.72,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.16),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.22),
                                                blurRadius: 24,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ParticipantTile(
                                            participant: localParticipant,
                                            isLocal: true,
                                            compact: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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

  List<lk.Participant> _remoteParticipants(lk.Room room) {
    final participants = room.remoteParticipants.values.toList()
      ..sort((a, b) => _participantRank(b).compareTo(_participantRank(a)));
    return participants;
  }

  int _participantRank(lk.Participant participant) {
    var rank = 0;
    if (participant.isSpeaking) {
      rank += 4;
    }
    if (_hasVisibleVideo(participant)) {
      rank += 2;
    }
    if (participant.connectionQuality != lk.ConnectionQuality.poor) {
      rank += 1;
    }
    return rank;
  }

  bool _hasVisibleVideo(lk.Participant participant) {
    final publication = participant.getTrackPublicationBySource(
          lk.TrackSource.camera,
        ) ??
        participant.getTrackPublicationBySource(
          lk.TrackSource.screenShareVideo,
        );
    return publication?.track is lk.VideoTrack && !(publication?.muted ?? true);
  }

  double _localPreviewWidth(double maxWidth) {
    return (maxWidth * 0.24).clamp(92.0, 124.0);
  }

  Future<void> _openChat(BuildContext context) async {
    final meetingCubit = context.read<MeetingCubit>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08111B),
      builder: (_) => BlocProvider.value(
        value: meetingCubit,
        child: FractionallySizedBox(
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
      ),
    );
  }
}

class _ParticipantStage extends StatelessWidget {
  const _ParticipantStage({
    required this.remoteParticipants,
    required this.localParticipant,
    required this.maxWidth,
    required this.maxHeight,
  });

  final List<lk.Participant> remoteParticipants;
  final lk.LocalParticipant? localParticipant;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (remoteParticipants.isEmpty) {
      if (localParticipant == null) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Center(
            child: Text(
              'Waiting for others to join...',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
      }

      return ParticipantTile(
        participant: localParticipant!,
        isLocal: true,
      );
    }

    if (remoteParticipants.length == 1) {
      return ParticipantTile(
        participant: remoteParticipants.first,
        isLocal: false,
      );
    }

    const pageSize = 4;
    final pages = <List<lk.Participant>>[];
    for (var index = 0; index < remoteParticipants.length; index += pageSize) {
      final end = (index + pageSize).clamp(0, remoteParticipants.length);
      pages.add(remoteParticipants.sublist(index, end));
    }

    return PageView.builder(
      controller: PageController(viewportFraction: 1),
      padEnds: false,
      itemCount: pages.length,
      itemBuilder: (context, pageIndex) {
        final pageParticipants = pages[pageIndex];
        final columns = pageParticipants.length == 2 ? 1 : 2;
        final rows = (pageParticipants.length / columns).ceil();
        const spacing = 12.0;
        final gridWidth = maxWidth;
        final gridHeight = maxHeight;
        final tileWidth = (gridWidth - (spacing * (columns - 1))) / columns;
        final tileHeight = (gridHeight - (spacing * (rows - 1))) / rows;
        final aspectRatio = tileWidth / tileHeight;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: pageParticipants.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final participant = pageParticipants[index];
              return ParticipantTile(
                participant: participant,
                isLocal: false,
              );
            },
          ),
        );
      },
    );
  }
}
