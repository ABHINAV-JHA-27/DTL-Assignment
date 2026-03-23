import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/error/app_exception.dart';
import '../../../../core/services/permission_service.dart';
import '../../data/models/chat_message.dart' as models;
import '../../data/models/meeting_access.dart';
import '../../data/services/livekit_service.dart';
import '../../data/services/meeting_api_service.dart';
import 'meeting_state.dart';

class MeetingCubit extends Cubit<MeetingState> {
  MeetingCubit({
    required MeetingApiService apiService,
    required LiveKitService liveKitService,
    required PermissionService permissionService,
  })  : _apiService = apiService,
        _liveKitService = liveKitService,
        _permissionService = permissionService,
        super(const MeetingState());

  final MeetingApiService _apiService;
  final LiveKitService _liveKitService;
  final PermissionService _permissionService;

  lk.EventsListener<lk.RoomEvent>? _roomEventsListener;

  Future<void> connect({
    required MeetingAccess access,
    required bool microphoneEnabled,
    required bool cameraEnabled,
  }) async {
    var resolvedMicrophoneEnabled = microphoneEnabled;
    var resolvedCameraEnabled = cameraEnabled;

    emit(
      state.copyWith(
        status: MeetingStatus.connecting,
        access: access,
        isMicrophoneEnabled: resolvedMicrophoneEnabled,
        isCameraEnabled: resolvedCameraEnabled,
        clearFeedback: true,
        clearMessages: true,
      ),
    );

    try {
      final permissionResult = await _permissionService.requestMediaPermissions(
        microphoneEnabled: resolvedMicrophoneEnabled,
        cameraEnabled: resolvedCameraEnabled,
      );

      resolvedMicrophoneEnabled =
          resolvedMicrophoneEnabled && permissionResult.microphoneGranted;
      resolvedCameraEnabled =
          resolvedCameraEnabled && permissionResult.cameraGranted;

      if (!resolvedMicrophoneEnabled && !resolvedCameraEnabled) {
        emit(
          state.copyWith(
            infoMessage:
                'Microphone and camera permissions were denied. Joining without local media.',
            isMicrophoneEnabled: false,
            isCameraEnabled: false,
          ),
        );
      } else if (microphoneEnabled && !resolvedMicrophoneEnabled) {
        emit(
          state.copyWith(
            infoMessage:
                'Microphone permission denied. Joining with microphone off.',
            isMicrophoneEnabled: false,
            isCameraEnabled: resolvedCameraEnabled,
          ),
        );
      } else if (cameraEnabled && !resolvedCameraEnabled) {
        emit(
          state.copyWith(
            infoMessage: 'Camera permission denied. Joining with camera off.',
            isMicrophoneEnabled: resolvedMicrophoneEnabled,
            isCameraEnabled: false,
          ),
        );
      }

      final resolvedAccess = access.hasConnectionDetails
          ? access
          : await _apiService.fetchParticipantAccess(
              roomCode: access.roomCode,
              username: access.username,
            );

      final room = await _liveKitService.connect(
        serverUrl: resolvedAccess.serverUrl!,
        token: resolvedAccess.token!,
        microphoneEnabled: resolvedMicrophoneEnabled,
        cameraEnabled: resolvedCameraEnabled,
      );

      _bindRoom(room);

      emit(
        state.copyWith(
          status: MeetingStatus.connected,
          room: room,
          access: resolvedAccess,
          isMicrophoneEnabled: resolvedMicrophoneEnabled,
          isCameraEnabled: resolvedCameraEnabled,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: MeetingStatus.failure,
          errorMessage: error.message,
          clearRoom: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: MeetingStatus.failure,
          errorMessage: 'Unable to connect to the room.',
          clearRoom: true,
        ),
      );
    }
  }

  Future<void> toggleMicrophone() async {
    final room = state.room;
    if (room == null) {
      return;
    }

    final nextValue = !state.isMicrophoneEnabled;
    try {
      await _liveKitService.toggleMicrophone(room, nextValue);
      emit(state.copyWith(isMicrophoneEnabled: nextValue, clearFeedback: true));
    } on AppException catch (error) {
      emit(state.copyWith(infoMessage: error.message));
    }
  }

  Future<void> toggleCamera() async {
    final room = state.room;
    if (room == null) {
      return;
    }

    final nextValue = !state.isCameraEnabled;
    try {
      await _liveKitService.toggleCamera(room, nextValue);
      emit(state.copyWith(isCameraEnabled: nextValue, clearFeedback: true));
    } on AppException catch (error) {
      emit(state.copyWith(infoMessage: error.message));
    }
  }

  Future<void> switchCamera() async {
    final room = state.room;
    if (room == null) {
      return;
    }

    try {
      await _liveKitService.switchCamera(room);
    } on AppException catch (error) {
      emit(state.copyWith(infoMessage: error.message));
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final room = state.room;
    final access = state.access;

    if (trimmed.isEmpty || room == null || access == null) {
      return;
    }

    final message = models.ChatMessage(
      sender: access.username,
      message: trimmed,
      timestamp: DateTime.now(),
      isLocalUser: true,
    );

    try {
      await _liveKitService.sendChatMessage(
        room,
        chatMessage: message,
      );

      emit(
        state.copyWith(
          messages: [...state.messages, message],
          clearFeedback: true,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(infoMessage: error.message));
    }
  }

  Future<void> disconnect() async {
    await _unbindRoom();
    emit(
      state.copyWith(
        status: MeetingStatus.ended,
        clearRoom: true,
      ),
    );
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  void _bindRoom(lk.Room room) {
    _roomEventsListener = room.createListener()
      ..listen((event) async {
        if (event is lk.DataReceivedEvent) {
          final chatMessage = _liveKitService.parseChatMessage(event);
          if (chatMessage != null) {
            emit(
              state.copyWith(
                messages: [...state.messages, chatMessage],
                clearFeedback: true,
              ),
            );
          }
        }

        if (event is lk.RoomDisconnectedEvent) {
          emit(
            state.copyWith(
              status: MeetingStatus.ended,
              clearRoom: true,
            ),
          );
        }
      });
  }

  Future<void> _unbindRoom() async {
    await _roomEventsListener?.dispose();
    _roomEventsListener = null;
    await _liveKitService.disconnect(state.room);
  }

  @override
  Future<void> close() async {
    await _unbindRoom();
    return super.close();
  }
}
