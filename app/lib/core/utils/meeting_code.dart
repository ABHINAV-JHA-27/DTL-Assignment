import 'dart:math';

class MeetingCode {
  MeetingCode._();

  static const int length = 9;
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static bool isValid(String value) {
    return RegExp(r'^[A-Z0-9]{9}$').hasMatch(normalize(value));
  }

  static String generate() {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
  }
}
