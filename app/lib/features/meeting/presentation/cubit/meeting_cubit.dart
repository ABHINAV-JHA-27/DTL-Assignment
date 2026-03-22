import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/services/permission_service.dart';
import '../../data/models/chat_message.dart';
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

  EventsListener<RoomEvent>? _roomEventsListener;

  Future<void> connect({
    required MeetingAccess access,
    required bool microphoneEnabled,
    required bool cameraEnabled,
  }) async {
    emit(
      state.copyWith(
        status: MeetingStatus.connecting,
        access: access,
        isMicrophoneEnabled: microphoneEnabled,
        isCameraEnabled: cameraEnabled,
        clearFeedback: true,
        clearMessages: true,
      ),
    );

    try {
      await _permissionService.ensureMediaPermissions();

      final resolvedAccess = access.hasConnectionDetails
          ? access
          : await _apiService.fetchParticipantAccess(
              roomCode: access.roomCode,
              username: access.username,
            );

      final room = await _liveKitService.connect(
        serverUrl: resolvedAccess.serverUrl!,
        token: resolvedAccess.token!,
        microphoneEnabled: microphoneEnabled,
        cameraEnabled: cameraEnabled,
      );

      _bindRoom(room);

      emit(
        state.copyWith(
          status: MeetingStatus.connected,
          room: room,
          access: resolvedAccess,
          clearFeedback: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: error.message == 'Permission Denied'
              ? MeetingStatus.permissionDenied
              : MeetingStatus.failure,
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

    final message = ChatMessage(
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

  void _bindRoom(Room room) {
    _roomEventsListener = room.createListener()
      ..listen((event) async {
        if (event is DataReceivedEvent) {
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

        if (event is RoomDisconnectedEvent) {
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
