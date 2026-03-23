class AppConfig {
  AppConfig._();

  static const backendBaseUrl = 'https://dtl-assignment.vercel.app';
  static const meetingsPath = '/api/meetings';
  static const tokenPath = '/api/get-participant-token';
  static const validationPath = '/api/meeting-exists';
  static const requestTimeout = Duration(seconds: 15);
  static const roomConnectTimeout = Duration(seconds: 20);
  static const chatTopic = 'chat.message.v1';
}
