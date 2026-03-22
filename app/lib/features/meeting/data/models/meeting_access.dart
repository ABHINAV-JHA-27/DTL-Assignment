import 'package:equatable/equatable.dart';

class MeetingAccess extends Equatable {
  const MeetingAccess({
    required this.roomCode,
    required this.username,
    this.token,
    this.serverUrl,
  });

  final String roomCode;
  final String username;
  final String? token;
  final String? serverUrl;

  bool get hasConnectionDetails =>
      token != null && token!.isNotEmpty && serverUrl != null && serverUrl!.isNotEmpty;

  MeetingAccess copyWith({
    String? roomCode,
    String? username,
    String? token,
    String? serverUrl,
  }) {
    return MeetingAccess(
      roomCode: roomCode ?? this.roomCode,
      username: username ?? this.username,
      token: token ?? this.token,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  @override
  List<Object?> get props => [roomCode, username, token, serverUrl];
}
