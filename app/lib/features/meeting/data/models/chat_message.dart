import 'dart:convert';

import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isLocalUser,
  });

  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isLocalUser;

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toPayload() => jsonEncode(toJson());

  factory ChatMessage.fromPayload(
    String payload, {
    required bool isLocalUser,
  }) {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return ChatMessage(
      sender: map['sender'] as String? ?? 'Guest',
      message: map['message'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isLocalUser: isLocalUser,
    );
  }

  @override
  List<Object?> get props => [sender, message, timestamp, isLocalUser];
}
