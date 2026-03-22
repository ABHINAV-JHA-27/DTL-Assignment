import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meetspace_mobile/core/error/app_exception.dart';
import 'package:meetspace_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:meetspace_mobile/features/meeting/data/models/meeting_access.dart';
import 'package:meetspace_mobile/features/meeting/data/services/meeting_api_service.dart';

void main() {
  group('HomeCubit', () {
    late _TestMeetingApiService apiService;
    late MeetingAccess access;

    setUp(() {
      access = const MeetingAccess(
        roomCode: 'ABC123XYZ',
        username: 'Abhinav',
        token: 'test-token',
        serverUrl: 'wss://livekit.example.com',
      );
      apiService = _TestMeetingApiService();
    });

    blocTest<HomeCubit, HomeState>(
      'createMeeting emits failure when name is blank',
      build: () => HomeCubit(apiService: apiService),
      act: (cubit) => cubit.createMeeting(),
      expect: () => const [
        HomeState(
          status: HomeStatus.failure,
          errorMessage: 'Your name is required.',
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'createMeeting emits submitting then navigation-ready state',
      build: () => HomeCubit(apiService: apiService),
      act: (cubit) async {
        cubit.updateName('Abhinav');
        await cubit.createMeeting();
      },
      skip: 1,
      expect: () => [
        const HomeState(
          name: 'Abhinav',
          status: HomeStatus.submitting,
        ),
        isA<HomeState>()
            .having((state) => state.name, 'name', 'Abhinav')
            .having(
              (state) => state.status,
              'status',
              HomeStatus.readyToNavigate,
            )
            .having(
              (state) => state.pendingAccess?.username,
              'username',
              'Abhinav',
            )
            .having(
              (state) => state.pendingAccess?.roomCode.length,
              'meeting code length',
              9,
            ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'joinMeeting emits failure when meeting code is invalid',
      build: () => HomeCubit(apiService: apiService),
      act: (cubit) async {
        cubit.updateName('Abhinav');
        cubit.updateMeetingCode('bad');
        await cubit.joinMeeting();
      },
      skip: 2,
      expect: () => const [
        HomeState(
          name: 'Abhinav',
          meetingCode: 'BAD',
          status: HomeStatus.failure,
          errorMessage: 'Enter a valid 9-character meeting code.',
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'joinMeeting emits submitting then navigation-ready on success',
      build: () {
        apiService.fetchHandler = ({
          required roomCode,
          required username,
        }) async {
          expect(roomCode, 'ABC123XYZ');
          expect(username, 'Abhinav');
          return access;
        };
        return HomeCubit(apiService: apiService);
      },
      act: (cubit) async {
        cubit.updateName('Abhinav');
        cubit.updateMeetingCode('abc123xyz');
        await cubit.joinMeeting();
      },
      skip: 2,
      expect: () => [
        const HomeState(
          name: 'Abhinav',
          meetingCode: 'ABC123XYZ',
          status: HomeStatus.submitting,
        ),
        HomeState(
          name: 'Abhinav',
          meetingCode: 'ABC123XYZ',
          status: HomeStatus.readyToNavigate,
          pendingAccess: access,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'joinMeeting emits backend error message on AppException',
      build: () {
        apiService.fetchHandler = ({
          required roomCode,
          required username,
        }) async {
          throw const AppException('Room not found.');
        };
        return HomeCubit(apiService: apiService);
      },
      act: (cubit) async {
        cubit.updateName('Abhinav');
        cubit.updateMeetingCode('ABC123XYZ');
        await cubit.joinMeeting();
      },
      skip: 2,
      expect: () => const [
        HomeState(
          name: 'Abhinav',
          meetingCode: 'ABC123XYZ',
          status: HomeStatus.submitting,
        ),
        HomeState(
          name: 'Abhinav',
          meetingCode: 'ABC123XYZ',
          status: HomeStatus.failure,
          errorMessage: 'Room not found.',
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'clearNavigation clears pending access and resets status',
      build: () => HomeCubit(apiService: apiService),
      act: (cubit) async {
        cubit.updateName('Abhinav');
        await cubit.createMeeting();
        cubit.clearNavigation();
      },
      skip: 3,
      expect: () => const [
        HomeState(
          name: 'Abhinav',
          status: HomeStatus.idle,
        ),
      ],
    );
  });
}

class _TestMeetingApiService extends MeetingApiService {
  _TestMeetingApiService() : super();

  Future<MeetingAccess> Function({
    required String roomCode,
    required String username,
  })? fetchHandler;

  @override
  Future<MeetingAccess> fetchParticipantAccess({
    required String roomCode,
    required String username,
  }) {
    final handler = fetchHandler;
    if (handler == null) {
      throw UnimplementedError('fetchHandler must be provided in tests.');
    }

    return handler(roomCode: roomCode, username: username);
  }
}
