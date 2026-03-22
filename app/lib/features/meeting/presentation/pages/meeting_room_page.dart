import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/meeting_cubit.dart';
import '../cubit/meeting_state.dart';
import '../widgets/meeting_room.dart';

class MeetingRoomPage extends StatelessWidget {
  const MeetingRoomPage({
    required this.roomCode,
    super.key,
  });

  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeetingCubit, MeetingState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.infoMessage != current.infoMessage ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == MeetingStatus.ended) {
          Navigator.of(context).maybePop();
          return;
        }

        final message = state.errorMessage ?? state.infoMessage;
        if (message == null) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<MeetingCubit>().clearFeedback();
      },
      builder: (context, state) {
        switch (state.status) {
          case MeetingStatus.initial:
          case MeetingStatus.connecting:
            return const _StateScaffold(
              title: 'Preparing your room',
              subtitle: 'Requesting permissions, connecting to LiveKit, and starting media devices.',
              child: CircularProgressIndicator(),
            );
          case MeetingStatus.permissionDenied:
            return _StateScaffold(
              title: 'Permission denied',
              subtitle: 'Allow camera and microphone access, then rejoin the meeting.',
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            );
          case MeetingStatus.failure:
            return _StateScaffold(
              title: 'Unable to join meeting',
              subtitle: state.errorMessage ?? 'Connection failed.',
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            );
          case MeetingStatus.connected:
            final room = state.room;
            final access = state.access;

            if (room == null || access == null) {
              return const SizedBox.shrink();
            }

            return MeetingRoom(
              roomCode: roomCode,
              username: access.username,
              room: room,
              isMicrophoneEnabled: state.isMicrophoneEnabled,
              isCameraEnabled: state.isCameraEnabled,
              onToggleMicrophone: context.read<MeetingCubit>().toggleMicrophone,
              onToggleCamera: context.read<MeetingCubit>().toggleCamera,
              onSwitchCamera: context.read<MeetingCubit>().switchCamera,
              onDisconnect: context.read<MeetingCubit>().disconnect,
              onSendMessage: context.read<MeetingCubit>().sendMessage,
            );
          case MeetingStatus.ended:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _StateScaffold extends StatelessWidget {
  const _StateScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child,
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
