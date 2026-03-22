# MeetSpace Mobile

Flutter mobile client for the existing Next.js + LiveKit dashboard in `../dashboard`.

## Stack

- `livekit_client` for WebRTC room connectivity
- `http` for Next.js API requests
- `flutter_bloc` for production-oriented state management
- `permission_handler` for camera and microphone permissions

## Project structure

```text
lib/
  app/
    app.dart
    theme/app_theme.dart
  core/
    config/app_config.dart
    error/app_exception.dart
    services/permission_service.dart
    utils/meeting_code.dart
  features/
    home/
      presentation/
        cubit/home_cubit.dart
        pages/home_screen.dart
    lobby/
      presentation/pages/pre_join_lobby_screen.dart
    meeting/
      data/
        models/chat_message.dart
        models/meeting_access.dart
        services/livekit_service.dart
        services/meeting_api_service.dart
      presentation/
        cubit/meeting_cubit.dart
        cubit/meeting_state.dart
        pages/meeting_room_page.dart
        widgets/chat_sheet.dart
        widgets/control_bar.dart
        widgets/meeting_room.dart
        widgets/participant_tile.dart
```

## Backend contract

The current repo exposes `GET /api/get-participant-token?room={code}&username={name}` from the Next.js app. This Flutter client uses that route to prefetch the LiveKit token and treat the backend response as the join validation step.

The dashboard currently validates meeting existence directly against Firebase on the web client and does **not** expose a dedicated mobile validation route yet. If you need strict room existence checks before the lobby, add a Next.js route backed by the same datastore and point `AppConfig.validationPath` to it.

## Base URL

The mobile app is currently configured to use the deployed Next.js backend:

- `https://dtl-assignment.vercel.app`

## Native permission setup

Add these entries to your generated platform projects after running `flutter create .`.

### Android `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

### iOS `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video meetings.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for meeting audio.</string>
```

## Local verification status

The Flutter and Dart SDKs are not installed in this workspace, so I could not run:

- `flutter pub get`
- `flutter analyze`
- `flutter test`

Install Flutter locally, run `flutter create .`, apply the permission entries above, then run the commands.
