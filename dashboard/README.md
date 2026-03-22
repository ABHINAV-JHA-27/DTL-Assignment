# MeetSpace Dashboard

MeetSpace Dashboard is a Google Meet style video conferencing app built with Next.js App Router, LiveKit, Firebase, Tailwind CSS, and Lucide React.

It supports meeting creation and validation, a pre-join lobby, real-time audio/video rooms, screen sharing, in-room chat, participant lists, optional Krisp noise cancellation, and server-triggered recording controls.

## What The App Does

- Lets a user create a new meeting code from the landing page.
- Stores meeting metadata in Firebase under a `meetings` collection.
- Validates a meeting code before allowing a user to join.
- Shows a pre-join lobby for device selection, camera preview, and mic activity checks.
- Generates a LiveKit participant token through a Next.js API route.
- Connects users to a LiveKit room for real-time video, audio, chat, and screen sharing.
- Exposes recording start/stop APIs backed by LiveKit egress and S3-compatible storage.

## Core Features

- Landing page with `Create Meeting` and `Join Meeting`
- Random room code generation
- Firebase-backed meeting existence checks
- LiveKit token server at `/api/get-participant-token`
- Pre-join lobby with camera, microphone, and display name selection
- Responsive meeting room with participant video grid
- Mute, video toggle, leave, sidebar, and screen share controls
- In-meeting chat using LiveKit data messages
- Recording controls with shared recording status
- Dockerized local runtime for the app and supporting services

## High-Level Architecture

### Runtime Flow

1. A user opens the landing page and either creates or joins a room.
2. Meeting metadata is read from or written to Firebase Firestore.
3. The user enters the pre-join lobby and selects local devices.
4. The client calls `/api/meetings` to create a room or validate a join code through the server.
5. The client calls `/api/get-participant-token?room=<code>&username=<name>`.
6. The API route validates the room and uses `livekit-server-sdk` to mint a short-lived room token.
7. The client mounts `LiveKitRoom` and connects to the LiveKit server.
8. LiveKit handles media transport, subscriptions, data messages, and screen sharing.
9. Recording controls call `/api/recording/start` and `/api/recording/stop`.
10. Recording status is reflected back into Firebase metadata so all participants see it.

### Architecture Diagram

```text
Browser (Next.js client)
  |
  |-- Landing page / Pre-join / Meeting UI
  |-- Firebase Web SDK
  |-- LiveKit React Components + livekit-client
  |
  +--> Firestore
  |     - meetings/{roomCode}
  |     - meeting metadata
  |
  +--> Next.js API Routes
        - /api/meetings
        - /api/get-participant-token
        - /api/recording/start
        - /api/recording/stop
          |
          +--> livekit-server-sdk
                |
                +--> LiveKit Server
                +--> Egress / S3-compatible storage for recordings
```

### Main Application Layers

- UI Layer
  - `src/app/*`
  - `src/components/dashboard/*`
  - `src/components/meeting/*`
  - Responsible for page rendering, pre-join UX, room controls, and responsive layouts.

- Client Integration Layer
  - `src/hooks/*`
  - `src/lib/firebase/client.ts`
  - Responsible for fetching room tokens, listening to meeting metadata, and managing recording state.

- Server Integration Layer
  - `src/app/api/*`
  - `src/lib/livekit/server.ts`
  - Responsible for token minting and recording orchestration.

- Persistence Layer
  - `src/lib/firebase/meetings.ts`
  - Responsible for meeting lookup, subscription, and recording metadata updates.

## Tech Stack

- Next.js 16 with App Router
- React 19
- Tailwind CSS 4
- LiveKit client SDK and React components
- Firebase Firestore
- Lucide React
- TypeScript

## Project Structure

```text
src/
  app/
    api/
      get-participant-token/
      recording/start/
      recording/stop/
    meet/[code]/
    layout.tsx
    page.tsx
  components/
    dashboard/
      LandingPage.tsx
    meeting/
      AudioSettingsPanel.tsx
      MeetingControls.tsx
      ParticipantGrid.tsx
      PreJoinLobby.tsx
      Room.tsx
      Sidebar.tsx
  hooks/
    useMeetingMetadata.ts
    useParticipantToken.ts
    useRecording.ts
  lib/
    firebase/
      client.ts
      meetings.ts
    livekit/
      server.ts
    meeting-code.ts
```

## Environment Variables

Copy `.env.example` to `.env` and fill in the values.

```bash
cp .env.example .env
```

### Firebase

These are used by the browser to initialize the Firebase app and Firestore:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
```

### LiveKit

These are used by the app and token server:

```env
NEXT_PUBLIC_LIVEKIT_URL=ws://localhost:7880
LIVEKIT_SERVER_URL=http://livekit:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_EGRESS_LAYOUT=speaker-dark
```

Notes:

- `NEXT_PUBLIC_LIVEKIT_URL` is the WebSocket URL used by the browser.
- `LIVEKIT_SERVER_URL` is the server-side HTTP URL used by the LiveKit server SDK.
- When running without Docker, `LIVEKIT_SERVER_URL` usually needs to be `http://localhost:7880`.

### Recording Storage

These are required only if you want recording to work:

```env
RECORDING_S3_ACCESS_KEY=
RECORDING_S3_SECRET_KEY=
RECORDING_S3_REGION=us-east-1
RECORDING_S3_ENDPOINT=http://minio:9000
RECORDING_S3_BUCKET=livekit-recordings
RECORDING_S3_FORCE_PATH_STYLE=true
```

## Firebase Setup

### 1. Create A Firebase Project

1. Open the Firebase Console.
2. Create a new project or use an existing one.
3. Add a Web app to the project.
4. Copy the Firebase Web config values into `.env`.

### 2. Create Firestore Database

1. Go to `Firestore Database`.
2. Create the database in production mode or test mode.
3. Make sure the database exists before running the app.

### 3. Add Firestore Rules

For local development, the app needs access to the `meetings` collection. Use rules like this while developing:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /meetings/{meetingId} {
      allow read, write: if true;
    }
  }
}
```

For a safer temporary development rule:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /meetings/{meetingId} {
      allow read: if true;
      allow create: if true;
      allow update: if true;
      allow delete: if false;
    }
  }
}
```

Do not use these rules in production as-is. In a production setup, move meeting mutations to server-side endpoints or secure them with authentication and stricter rules.

## LiveKit Setup

You can run LiveKit in two ways.

### Option 1. Run Against Your Own Local LiveKit Server

Provide:

- `NEXT_PUBLIC_LIVEKIT_URL=ws://localhost:7880`
- `LIVEKIT_SERVER_URL=http://localhost:7880`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`

### Option 2. Use Docker Compose From This Repo

The included `docker-compose.yml` starts:

- the Next.js app
- LiveKit server
- Redis
- MinIO
- a bucket bootstrap container

This is useful for local testing. Recording still depends on an egress-capable LiveKit backend and valid S3-compatible settings.

## Local Development Setup

### Prerequisites

- Node.js 22 or newer
- npm
- A Firebase project with Firestore enabled
- A LiveKit server, local or remote

### End-To-End Setup

1. Install dependencies:

```bash
npm install
```

2. Copy the environment file:

```bash
cp .env.example .env
```

3. Fill in Firebase values in `.env`.

4. Set your LiveKit values:

```env
NEXT_PUBLIC_LIVEKIT_URL=ws://localhost:7880
LIVEKIT_SERVER_URL=http://localhost:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
```

5. Publish Firestore rules that allow the app to read and write `meetings`.

6. Start the Next.js app:

```bash
npm run dev
```

7. Open:

```txt
http://localhost:3000
```

8. Create a meeting from one device or browser tab.

9. Join the same meeting from another device or tab using the room code.

## Docker Setup

### Start Everything

```bash
docker compose up --build
```

Then open:

```txt
http://localhost:3000
```

### Important Docker Notes

- The app container reads environment variables from `.env`.
- The default compose file exposes LiveKit on `7880` and `7881`.
- MinIO is exposed on `9000` and the console on `9001`.
- The Docker image uses Next.js standalone output for production-style packaging.

## Available Scripts

```bash
npm run dev
npm run build
npm run start
npm run lint
npm test
npm run verify:responsive
```

### What They Do

- `npm run dev`
  - Starts the local development server.
- `npm run build`
  - Builds the production app.
- `npm run start`
  - Starts the built production app.
- `npm run lint`
  - Runs ESLint.
- `npm test`
  - Runs lightweight unit tests for core meeting-code utilities.
- `npm run verify:responsive`
  - Runs the responsive layout verification script.

## Key Routes

- `/`
  - Landing page with create/join flows.
- `/meet/[code]`
  - Pre-join and meeting room experience.
- `/api/meetings`
  - Server-owned meeting creation and join-code validation.
- `/api/get-participant-token`
  - Validates the room and generates a LiveKit participant token.
- `/api/recording/start`
  - Starts a room composite recording.
- `/api/recording/stop`
  - Stops an active recording.

## Recording Notes

Recording is wired into the app, but it only works if the backend supports egress and the storage target is configured correctly.

To enable recording end to end, you need:

- valid `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET`
- a working `LIVEKIT_SERVER_URL`
- an egress-capable LiveKit deployment
- valid S3-compatible recording credentials
- a writable recording bucket

Without that backend setup, the room can still function for meetings, chat, and screen sharing, but recording requests will fail.

## Noise Cancellation Notes

Krisp support is integrated in the UI, but the exact behavior depends on your LiveKit environment and client runtime support.

## Troubleshooting

### Firestore says the client is offline

- Confirm Firestore Database is created.
- Confirm the Firebase Web config values are correct.
- Confirm Firestore rules allow the app to access `meetings`.
- Check if a VPN, Brave Shields, privacy extension, or network filter is blocking Firestore.

### Firestore denied the request

- Publish Firestore rules that allow reads and writes to `meetings` for development.

### Users can join but cannot see each other

- Make sure each participant has camera permission enabled.
- Make sure the LiveKit server URL and API credentials are correct.
- Join with a fresh room and make sure both users are in the same room code.

### Lobby camera preview is black

- Check browser camera permission.
- Verify the selected camera device exists and is not busy in another app.
- Re-toggle the camera in the pre-join lobby.

### Recording does not start

- Confirm egress is available in your LiveKit deployment.
- Confirm the S3-compatible bucket settings are valid.
- Confirm `LIVEKIT_SERVER_URL` resolves correctly from the server environment.

## Verification

The project has been validated with:

- `npm run lint`
- `npm run build`
- `npm run verify:responsive`

## Future Improvements

- Server-side Firebase Admin integration for stricter security
- Authenticated meeting ownership and participant permissions
- Production Firestore security rules
- Persistent chat history
- Better recording lifecycle visibility and download management
