import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/meeting_code.dart';
import '../models/meeting_access.dart';

class MeetingApiService {
  MeetingApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<MeetingAccess> fetchParticipantAccess({
    required String roomCode,
    required String username,
  }) async {
    final normalizedCode = MeetingCode.normalize(roomCode);
    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}${AppConfig.tokenPath}',
    ).replace(
      queryParameters: {
        'room': normalizedCode,
        'username': username.trim(),
      },
    );

    try {
      final response = await _client.get(uri).timeout(AppConfig.requestTimeout);
      final body = _parseJson(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          _extractError(
            body,
            fallback: response.statusCode == 404
                ? 'Room not found.'
                : 'Unable to get a participant token.',
          ),
          statusCode: response.statusCode,
        );
      }

      final token = body['token'] as String?;
      final serverUrl = body['serverUrl'] as String?;

      if (token == null || serverUrl == null) {
        throw const AppException('LiveKit token response was incomplete.');
      }

      return MeetingAccess(
        roomCode: normalizedCode,
        username: username.trim(),
        token: token,
        serverUrl: serverUrl,
      );
    } on TimeoutException {
      throw const AppException('Connection Timeout');
    } on FormatException {
      throw const AppException('Backend response was not valid JSON.');
    }
  }

  Future<void> validateMeetingCode({
    required String roomCode,
    required String username,
  }) async {
    try {
      await fetchParticipantAccess(roomCode: roomCode, username: username);
    } on AppException {
      rethrow;
    } on Object {
      throw const AppException('Connection Timeout');
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  String _extractError(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    return fallback;
  }
}
