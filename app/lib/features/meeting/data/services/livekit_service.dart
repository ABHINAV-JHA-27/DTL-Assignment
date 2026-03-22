import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_exception.dart';
import '../models/chat_message.dart';

class LiveKitService {
  Future<Room> connect({
    required String serverUrl,
    required String token,
    required bool microphoneEnabled,
    required bool cameraEnabled,
  }) async {
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    try {
      await room
          .connect(
            serverUrl,
            token,
            connectOptions: const ConnectOptions(
              autoSubscribe: true,
            ),
          )
          .timeout(AppConfig.roomConnectTimeout);

      await room.localParticipant?.setMicrophoneEnabled(microphoneEnabled);
      await room.localParticipant?.setCameraEnabled(cameraEnabled);

      return room;
    } on LiveKitException catch (error) {
      await room.dispose();
      throw AppException(error.message);
    } on TimeoutException {
      await room.dispose();
      throw const AppException('Connection Timeout');
    } on Object {
      await room.dispose();
      throw const AppException('Unable to connect to the room.');
    }
  }

  Future<void> toggleMicrophone(Room room, bool enabled) async {
    await room.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> toggleCamera(Room room, bool enabled) async {
    await room.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> switchCamera(Room room) async {
    final publication = room.localParticipant?.getTrackPublicationBySource(
      TrackSource.camera,
    );
    final track = publication?.track;

    if (track is LocalVideoTrack) {
      final videoInputs = await Hardware.instance.videoInputs();
      final selectedDeviceId = room.selectedVideoInputDeviceId;
      final nextDevice = videoInputs.firstWhere(
        (device) => device.deviceId != selectedDeviceId,
        orElse: () => throw const AppException('No secondary camera was found.'),
      );
      await room.setVideoInputDevice(nextDevice);
      return;
    }

    throw const AppException('No local camera track is available.');
  }

  Future<void> sendChatMessage(
    Room room, {
    required ChatMessage chatMessage,
  }) async {
    final payload = utf8.encode(chatMessage.toPayload());
    await room.localParticipant?.publishData(
      payload,
      topic: AppConfig.chatTopic,
      reliable: true,
    );
  }

  ChatMessage? parseChatMessage(DataReceivedEvent event) {
    if (event.topic != AppConfig.chatTopic) {
      return null;
    }

    final payload = utf8.decode(event.data);
    return ChatMessage.fromPayload(
      payload,
      isLocalUser: false,
    );
  }

  Future<void> disconnect(Room? room) async {
    if (room == null) {
      return;
    }

    try {
      await room.disconnect();
    } on Object {
      // Ignore duplicate disconnects; disposing the room is still required.
    } finally {
      await room.dispose();
    }
  }
}
