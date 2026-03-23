import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/state_panel.dart';
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

        final message = state.infoMessage;
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
            return const Scaffold(
              body: StatePanel(
                title: 'Preparing your room',
                subtitle:
                    'Requesting permissions, connecting to LiveKit, and starting media devices.',
                child: CircularProgressIndicator(),
              ),
            );
          case MeetingStatus.permissionDenied:
            return Scaffold(
              body: StatePanel(
                title: 'Permission denied',
                subtitle:
                    'Allow camera and microphone access, then rejoin the meeting.',
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            );
          case MeetingStatus.failure:
            return Scaffold(
              body: StatePanel(
                title: 'Unable to join meeting',
                subtitle: state.errorMessage ?? 'Connection failed.',
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
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
