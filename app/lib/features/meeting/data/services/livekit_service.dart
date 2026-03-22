import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_exception.dart';
import '../models/chat_message.dart' as models;

class LiveKitService {
  Future<lk.Room> connect({
    required String serverUrl,
    required String token,
    required bool microphoneEnabled,
    required bool cameraEnabled,
  }) async {
    final room = lk.Room(
      roomOptions: const lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    try {
      await room
          .connect(
            serverUrl,
            token,
            connectOptions: const lk.ConnectOptions(
              autoSubscribe: true,
            ),
          )
          .timeout(AppConfig.roomConnectTimeout);

      await room.localParticipant?.setMicrophoneEnabled(microphoneEnabled);
      await room.localParticipant?.setCameraEnabled(cameraEnabled);

      return room;
    } on lk.LiveKitException catch (error) {
      await room.dispose();
      if (error is TimeoutException) {
        throw const AppException('Connection Timeout');
      }
      throw AppException(error.message);
    } on Object {
      await room.dispose();
      throw const AppException('Unable to connect to the room.');
    }
  }

  Future<void> toggleMicrophone(lk.Room room, bool enabled) async {
    await room.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> toggleCamera(lk.Room room, bool enabled) async {
    await room.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> switchCamera(lk.Room room) async {
    final publication = room.localParticipant?.getTrackPublicationBySource(
      lk.TrackSource.camera,
    );
    final track = publication?.track;

    if (track is lk.LocalVideoTrack) {
      final videoInputs = await lk.Hardware.instance.videoInputs();
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
    lk.Room room, {
    required models.ChatMessage chatMessage,
  }) async {
    final payload = utf8.encode(chatMessage.toPayload());
    await room.localParticipant?.publishData(
      payload,
      topic: AppConfig.chatTopic,
      reliable: true,
    );
  }

  models.ChatMessage? parseChatMessage(lk.DataReceivedEvent event) {
    if (event.topic != AppConfig.chatTopic) {
      return null;
    }

    final payload = utf8.decode(event.data);
    return models.ChatMessage.fromPayload(
      payload,
      isLocalUser: false,
    );
  }

  Future<void> disconnect(lk.Room? room) async {
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
