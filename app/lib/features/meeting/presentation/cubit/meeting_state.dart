import 'package:equatable/equatable.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../data/models/chat_message.dart' as models;
import '../../data/models/meeting_access.dart';

enum MeetingStatus {
  initial,
  connecting,
  connected,
  permissionDenied,
  failure,
  ended,
}

class MeetingState extends Equatable {
  const MeetingState({
    this.status = MeetingStatus.initial,
    this.room,
    this.access,
    this.messages = const [],
    this.isMicrophoneEnabled = true,
    this.isCameraEnabled = true,
    this.errorMessage,
    this.infoMessage,
  });

  final MeetingStatus status;
  final lk.Room? room;
  final MeetingAccess? access;
  final List<models.ChatMessage> messages;
  final bool isMicrophoneEnabled;
  final bool isCameraEnabled;
  final String? errorMessage;
  final String? infoMessage;

  MeetingState copyWith({
    MeetingStatus? status,
    lk.Room? room,
    MeetingAccess? access,
    List<models.ChatMessage>? messages,
    bool? isMicrophoneEnabled,
    bool? isCameraEnabled,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
    bool clearFeedback = false,
    bool clearRoom = false,
    bool clearAccess = false,
  }) {
    return MeetingState(
      status: status ?? this.status,
      room: clearRoom ? null : room ?? this.room,
      access: clearAccess ? null : access ?? this.access,
      messages: clearMessages ? const [] : messages ?? this.messages,
      isMicrophoneEnabled: isMicrophoneEnabled ?? this.isMicrophoneEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearFeedback ? null : infoMessage ?? this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        room,
        access,
        messages,
        isMicrophoneEnabled,
        isCameraEnabled,
        errorMessage,
        infoMessage,
      ];
}
