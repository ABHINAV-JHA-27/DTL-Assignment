import 'package:permission_handler/permission_handler.dart';

class MediaPermissionResult {
  const MediaPermissionResult({
    required this.microphoneGranted,
    required this.cameraGranted,
  });

  final bool microphoneGranted;
  final bool cameraGranted;
}

class PermissionService {
  Future<MediaPermissionResult> requestMediaPermissions({
    required bool microphoneEnabled,
    required bool cameraEnabled,
  }) async {
    var cameraGranted = !cameraEnabled;
    var microphoneGranted = !microphoneEnabled;

    if (cameraEnabled) {
      final cameraStatus = await Permission.camera.request();
      cameraGranted = cameraStatus.isGranted;
    }

    if (microphoneEnabled) {
      final microphoneStatus = await Permission.microphone.request();
      microphoneGranted = microphoneStatus.isGranted;
    }

    return MediaPermissionResult(
      microphoneGranted: microphoneGranted,
      cameraGranted: cameraGranted,
    );
  }
}
