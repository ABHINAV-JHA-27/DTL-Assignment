import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:meetspace_mobile/core/error/app_exception.dart';
import 'package:meetspace_mobile/features/meeting/data/services/meeting_api_service.dart';

void main() {
  group('MeetingApiService', () {
    test('returns access details for a valid token response', () async {
      late Uri requestedUri;
      final service = MeetingApiService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            '{"token":"abc","serverUrl":"wss://livekit.example.com"}',
            200,
          );
        }),
      );

      final result = await service.fetchParticipantAccess(
        roomCode: 'abc 123 xyz',
        username: '  Abhinav  ',
      );

      expect(result.roomCode, 'ABC123XYZ');
      expect(result.username, 'Abhinav');
      expect(result.token, 'abc');
      expect(result.serverUrl, 'wss://livekit.example.com');
      expect(requestedUri.queryParameters['room'], 'ABC123XYZ');
      expect(requestedUri.queryParameters['username'], 'Abhinav');
    });

    test('throws backend error for non-2xx responses', () async {
      final service = MeetingApiService(
        client: MockClient(
          (_) async => http.Response('{"error":"Room not found."}', 404),
        ),
      );

      expect(
        () => service.fetchParticipantAccess(
          roomCode: 'ABC123XYZ',
          username: 'Abhinav',
        ),
        throwsA(
          isA<AppException>()
              .having((error) => error.message, 'message', 'Room not found.')
              .having((error) => error.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws when token response is incomplete', () async {
      final service = MeetingApiService(
        client: MockClient(
          (_) async => http.Response('{"token":"abc"}', 200),
        ),
      );

      expect(
        () => service.fetchParticipantAccess(
          roomCode: 'ABC123XYZ',
          username: 'Abhinav',
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'LiveKit token response was incomplete.',
          ),
        ),
      );
    });

    test('throws timeout message when client request times out', () async {
      final service = MeetingApiService(
        client: MockClient((_) => Future<http.Response>.error(TimeoutException('timeout'))),
      );

      expect(
        () => service.fetchParticipantAccess(
          roomCode: 'ABC123XYZ',
          username: 'Abhinav',
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Connection Timeout',
          ),
        ),
      );
    });

    test('throws invalid JSON message when backend response is malformed', () async {
      final service = MeetingApiService(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      expect(
        () => service.fetchParticipantAccess(
          roomCode: 'ABC123XYZ',
          username: 'Abhinav',
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Backend response was not valid JSON.',
          ),
        ),
      );
    });
  });
}
