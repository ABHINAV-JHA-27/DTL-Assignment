import 'package:permission_handler/permission_handler.dart';

import '../error/app_exception.dart';

class PermissionService {
  Future<void> ensureMediaPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return;
    }

    throw const AppException('Permission Denied');
  }
}
