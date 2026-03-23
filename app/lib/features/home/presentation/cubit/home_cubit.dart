import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/meeting_code.dart';
import '../../../meeting/data/models/meeting_access.dart';
import '../../../meeting/data/services/meeting_api_service.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required MeetingApiService apiService})
      : _apiService = apiService,
        super(const HomeState());

  final MeetingApiService _apiService;

  void updateName(String value) {
    emit(state.copyWith(name: value, clearFeedback: true));
  }

  void updateMeetingCode(String value) {
    emit(
      state.copyWith(
        meetingCode: MeetingCode.normalize(value),
        clearFeedback: true,
      ),
    );
  }

  Future<void> createMeeting() async {
    final name = _validatedName();
    if (name == null) {
      return;
    }

    emit(state.copyWith(status: HomeStatus.submitting, clearFeedback: true));

    try {
      final access = await _apiService.createMeeting(createdBy: name);

      emit(
        state.copyWith(
          status: HomeStatus.readyToNavigate,
          pendingAccess: access,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error.message,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Connection Timeout',
        ),
      );
    }
  }

  Future<void> joinMeeting() async {
    final name = _validatedName();
    if (name == null) {
      return;
    }

    if (!MeetingCode.isValid(state.meetingCode)) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Enter a valid 9-character meeting code.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: HomeStatus.submitting, clearFeedback: true));

    try {
      final access = await _apiService.fetchParticipantAccess(
        roomCode: state.meetingCode,
        username: name,
      );

      emit(
        state.copyWith(
          status: HomeStatus.readyToNavigate,
          pendingAccess: access,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error.message,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Connection Timeout',
        ),
      );
    }
  }

  void clearNavigation() {
    emit(
      state.copyWith(
        status: HomeStatus.idle,
        clearPendingAccess: true,
      ),
    );
  }

  String? _validatedName() {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Your name is required.',
        ),
      );
      return null;
    }

    return name;
  }
}
