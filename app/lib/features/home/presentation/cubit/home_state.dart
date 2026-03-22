part of 'home_cubit.dart';

enum HomeStatus {
  idle,
  submitting,
  readyToNavigate,
  failure,
}

class HomeState extends Equatable {
  const HomeState({
    this.name = '',
    this.meetingCode = '',
    this.status = HomeStatus.idle,
    this.errorMessage,
    this.pendingAccess,
  });

  final String name;
  final String meetingCode;
  final HomeStatus status;
  final String? errorMessage;
  final MeetingAccess? pendingAccess;

  HomeState copyWith({
    String? name,
    String? meetingCode,
    HomeStatus? status,
    String? errorMessage,
    MeetingAccess? pendingAccess,
    bool clearFeedback = false,
    bool clearPendingAccess = false,
  }) {
    return HomeState(
      name: name ?? this.name,
      meetingCode: meetingCode ?? this.meetingCode,
      status: status ?? this.status,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
      pendingAccess: clearPendingAccess
          ? null
          : pendingAccess ?? (clearFeedback ? null : this.pendingAccess),
    );
  }

  @override
  List<Object?> get props => [
        name,
        meetingCode,
        status,
        errorMessage,
        pendingAccess,
      ];
}
