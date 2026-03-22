import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const tokenPath = '/api/get-participant-token';
  static const validationPath = '/api/meeting-exists';
  static const requestTimeout = Duration(seconds: 15);
  static const roomConnectTimeout = Duration(seconds: 20);
  static const chatTopic = 'chat.message.v1';

  static String get backendBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}
