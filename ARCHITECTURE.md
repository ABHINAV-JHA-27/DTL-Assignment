# MeetSpace Architecture Document

## Overview

MeetSpace is a cross-platform video conferencing system with two primary clients:

- A **web experience** built with Next.js, Tailwind CSS, LiveKit React components, and Firebase.
- A **mobile experience** built with Flutter, `flutter_bloc`, and the LiveKit Flutter SDK.

The platform uses **LiveKit Cloud** as the real-time media layer, **Firebase Firestore** as the meeting metadata store, and **Vercel-hosted Next.js route handlers** as the control-plane backend for token issuance, meeting validation, and recording orchestration.

> **Architectural principle:** MeetSpace separates the **application control plane** from the **real-time media plane**. Next.js and Firebase manage room metadata, validation, token minting, and recording state. LiveKit Cloud handles WebRTC signaling, media transport, track forwarding, and in-room data delivery.

---

## 1. High-Level System Design

### 1.1 Architectural Style

MeetSpace follows a **Client-Server-Media Server** architecture rather than a purely client-to-client design.

- **Clients**
  - Web browser running the Next.js front end.
  - Flutter application running on Android, iOS, desktop, and web targets.
- **Application server / control plane**
  - Next.js route handlers deployed on Vercel.
  - Responsible for meeting validation, participant token generation, and recording lifecycle endpoints.
- **Media server**
  - LiveKit Cloud acting as the SFU-backed media plane.
  - Responsible for WebRTC session establishment, track distribution, chat/data transport, screen share, and reconnection handling.
- **Metadata store**
  - Firebase Firestore storing meeting existence and lightweight room metadata.

This split is intentional:

- **Next.js does not proxy media.**
- **Firebase does not transport audio/video.**
- **LiveKit does not own business metadata such as whether a meeting code exists in the product domain.**

### 1.2 Logical Component View

| Layer                 | Primary Technology                       | Responsibility                                                   |
| --------------------- | ---------------------------------------- | ---------------------------------------------------------------- |
| Presentation          | Next.js App Router, Tailwind, Flutter UI | Landing, pre-join lobby, meeting room, controls                  |
| Client state          | React hooks, Cubit/BLoC                  | Local UI state, join lifecycle, room state transitions           |
| Control plane API     | Next.js route handlers                   | Meeting create/validate, token minting, recording start/stop     |
| Metadata persistence  | Firebase Firestore                       | Meeting directory, status, recording metadata                    |
| Real-time media plane | LiveKit Cloud                            | WebRTC signaling, media forwarding, data channels, room presence |
| Hosting               | Vercel                                   | Web delivery and API hosting                                     |

### 1.3 How Next.js Serves Two Roles

Next.js serves **two distinct architectural roles** in MeetSpace:

1. **Web client**
   - Renders the landing page, pre-join lobby, and in-room meeting UI.
   - Uses LiveKit React components to connect to the room from the browser.
   - Reads meeting metadata from Firestore and calls internal API routes.

2. **Signaling / management backend for both web and Flutter**
   - Exposes `/api/meetings` for meeting creation and existence validation.
   - Exposes `/api/get-participant-token` to generate room-scoped LiveKit access tokens.
   - Exposes `/api/recording/start` and `/api/recording/stop` for egress orchestration.
   - Acts as the shared control-plane backend for the Flutter client via HTTPS.

In other words, the Flutter app does **not** talk directly to LiveKit for authorization. It first talks to the Next.js backend, which validates the meeting and returns a signed participant token plus the LiveKit server URL.

### 1.4 Role of Firebase

Firebase Firestore is the **meeting metadata system of record**. It stores:

- Meeting code
- Creator identity
- Meeting creation timestamp
- Meeting status
- Recording state such as `isRecording`, `egressId`, and `startedBy`

Firestore is used for **business-level meeting existence**, not media transport. This distinction matters:

- A room code can exist in Firestore before any participant is connected.
- LiveKit can host transient room activity, but MeetSpace still uses Firestore to determine whether a room code is valid in product terms.
- Recording state is synchronized through Firestore so multiple clients can observe a consistent room-level status.

### 1.5 High-Level Runtime Topology

```text
                    +---------------------------+
                    |        Firebase           |
                    |   Firestore metadata      |
                    | meetings/{roomCode}       |
                    +-------------+-------------+
                                  ^
                                  |
                                  | metadata read/write
                                  |
+------------------+    HTTPS     |       HTTPS / SDK calls
| Web Client       +--------------+-----------------------------+
| Next.js UI       |                                            |
| Browser          |                                            v
+------------------+                              +---------------------------+
                                                  | Next.js Route Handlers    |
+------------------+    HTTPS                     | on Vercel                 |
| Flutter Client   +----------------------------->| - /api/meetings           |
| Cubit + LiveKit  |                              | - /api/get-participant-   |
+------------------+                              |   token                   |
                                                  | - /api/recording/*        |
                                                  +-------------+-------------+
                                                                |
                                                                | signed JWT / egress API
                                                                v
                                                  +---------------------------+
                                                  | LiveKit Cloud             |
                                                  | SFU + signaling + data    |
                                                  +-------------+-------------+
                                                                ^
                                                                |
                                                                | WSS + WebRTC
                                                                |
                                                     audio / video / chat / share
```

---

## 2. Signaling & Media Flow

### 2.1 End-to-End Join Sequence

The join path has two phases:

- **Application signaling / authorization**
  - Handled over HTTPS by Next.js.
- **Real-time signaling and media establishment**
  - Handled by LiveKit over WebSocket and WebRTC.

### 2.2 Step-by-Step Flow

1. A user enters a **meeting code** and **display name** in the web pre-join lobby or Flutter UI.
2. The client normalizes the room code to the canonical meeting format.
3. When the user clicks **Join**, the client calls:
   - `GET /api/get-participant-token?room=<meetingCode>&username=<displayName>`
4. The Next.js route performs input validation:
   - Ensures `room` and `username` are present.
   - Ensures the room code matches the expected 9-character format.
5. The route checks Firestore to confirm the meeting exists in the `meetings` collection.
6. If the room exists, the route creates a scoped LiveKit access token using `livekit-server-sdk`.
7. The API returns:
   - `token`
   - `serverUrl`
8. The client uses the returned `serverUrl` to open a **secure WebSocket connection** to LiveKit Cloud:
   - `wss://...`
9. During connection setup, LiveKit validates the JWT signature and grant claims.
10. Once authenticated, the client and LiveKit perform WebRTC session setup:
    - signaling exchange over the LiveKit connection
    - ICE candidate gathering
    - NAT traversal via STUN/TURN as required
    - transport negotiation for media and data channels
11. The client enables or publishes local tracks based on user device choices and permission outcomes.
12. Audio, video, chat messages, and screen-share streams then flow through LiveKit Cloud, which forwards them to subscribed participants.

### 2.3 Sequence Summary

```text
User clicks Join
  -> Client calls /api/get-participant-token
  -> Next.js validates meeting code and room existence in Firestore
  -> Next.js signs room-scoped LiveKit JWT
  -> Client receives token + LiveKit URL
  -> Client opens WSS connection to LiveKit Cloud
  -> LiveKit validates JWT grant
  -> ICE / DTLS / SRTP negotiation completes
  -> Client publishes local media tracks
  -> SFU forwards subscribed tracks to participants
```

### 2.4 Web Flow vs Flutter Flow

The media flow is intentionally symmetrical across platforms.

| Concern                   | Web                                                        | Flutter                                        |
| ------------------------- | ---------------------------------------------------------- | ---------------------------------------------- |
| UI entry                  | Pre-join lobby in Next.js                                  | Home and lobby screens in Flutter              |
| Token fetch               | `useParticipantToken` calling `/api/get-participant-token` | `MeetingApiService.fetchParticipantAccess()`   |
| Room connect              | `LiveKitRoom` / `livekit-client`                           | `LiveKitService.connect()`                     |
| Meeting metadata          | Firestore hooks                                            | Shared backend validation through Next.js APIs |
| Local permission handling | Browser device prompts                                     | `permission_handler` via `PermissionService`   |

### 2.5 Important Boundary

> The **HTTPS API call to Next.js is not the media connection**. It is the authorization and control-plane step that makes the media connection possible. The actual media session starts only after the client connects to LiveKit over WSS and completes WebRTC negotiation.

---

## 3. Authentication & Token Flow

### 3.1 Token Issuance Model

MeetSpace uses the **`livekit-server-sdk`** in the Next.js backend to generate short-lived participant tokens. These tokens are minted only after application-level validation succeeds.

Current implementation characteristics:

- Generated server-side in `/api/get-participant-token`
- Signed with `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET`
- Time-limited with a **1 hour TTL**
- Bound to a single room grant
- Returned to the client together with the LiveKit `serverUrl`

### 3.2 Token Scope and Claims

Each token is deliberately scoped to the meeting being joined.

| Token Attribute            | Purpose                                                                      |
| -------------------------- | ---------------------------------------------------------------------------- |
| `room` / `room_name` grant | Restricts the token to a single LiveKit room, mapped to the meeting code     |
| `roomJoin: true`           | Allows the participant to join that room                                     |
| `canPublish: true`         | Allows publishing local audio/video/screen-share tracks                      |
| `canSubscribe: true`       | Allows receiving remote tracks                                               |
| `canPublishData: true`     | Allows chat and other data channel messages                                  |
| `identity`                 | Unique participant identity used by LiveKit for presence and track ownership |
| `name`                     | Human-readable participant display name                                      |

### 3.3 Participant Identity Strategy

The backend generates a `participant_identity` by:

- Normalizing the supplied username
- Truncating to a safe length
- Appending a random UUID-derived suffix

This avoids collisions when multiple users join with the same display name and ensures the LiveKit identity remains unique even if the UI label is not.

### 3.4 Why the Token Flow Matters

This design provides several security and control benefits:

- Clients never receive the LiveKit API secret.
- Meeting existence is validated against Firestore before token issuance.
- Room access is constrained to a specific meeting code.
- Participant identities are centrally generated rather than trusted from the client.
- Privileges can be narrowed later without changing the client connection pattern.

### 3.5 Authentication Sequence

```text
Client -> Next.js API: room code + username
Next.js API -> Firestore: validate meeting exists
Next.js API -> livekit-server-sdk: create AccessToken
Next.js API -> Client: signed JWT + serverUrl
Client -> LiveKit Cloud: connect using JWT
LiveKit Cloud: accept only if JWT signature and room grants are valid
```

---

## 4. Room & Participant Management

### 4.1 Meeting Lifecycle in Firebase

Firebase Firestore tracks the **application lifecycle** of a meeting. A meeting becomes valid when a document exists under:

```text
meetings/{roomCode}
```

The document currently stores fields equivalent to:

| Field                   | Purpose                                       |
| ----------------------- | --------------------------------------------- |
| `code`                  | Canonical meeting code                        |
| `createdAt`             | Creation timestamp                            |
| `createdBy`             | Display name of the creator                   |
| `status`                | Product-level room status, currently `active` |
| `recording.isRecording` | Shared recording status                       |
| `recording.egressId`    | LiveKit egress identifier                     |
| `recording.startedAt`   | Recording start timestamp                     |
| `recording.startedBy`   | User who initiated recording                  |

This allows the platform to support:

- Meeting creation with generated room codes
- Room existence checks before join
- Shared recording indicators
- Cross-client visibility into room metadata

### 4.2 Why Firestore Is Not the Presence Layer

Firestore is not responsible for transport-level participant presence or media membership. That responsibility remains with LiveKit.

- **Firestore answers:** “Does this meeting exist, and what is its metadata?”
- **LiveKit answers:** “Who is connected right now, what tracks are published, and which participants are subscribed?”

This separation reduces coupling and prevents the metadata store from becoming a bottleneck for media events.

### 4.3 LiveKit SFU Participant Model

MeetSpace uses LiveKit’s **Selective Forwarding Unit (SFU)** model rather than a peer-to-peer mesh.

#### SFU behavior

- Each participant uploads one audio stream and one or more video/screen-share streams to LiveKit.
- LiveKit receives these uplinks and forwards them as separate downlinks to subscribed participants.
- Adaptive subscriptions, dynacast, and selective forwarding reduce unnecessary bandwidth and CPU usage.

#### Why this matters

In a peer-to-peer mesh, each participant would need to send media directly to every other participant. That scales poorly:

- With 6 participants, each client may need multiple simultaneous uplinks.
- CPU and upstream bandwidth requirements grow rapidly.
- Mobile networks degrade quickly under mesh topologies.

With an SFU:

- The sender publishes once.
- The SFU fan-outs the stream to many receivers.
- The system scales to larger rooms with significantly better client efficiency.

### 4.4 Media Track Management

Participant and room behavior is managed by LiveKit, including:

- Track publication and unpublication
- Device mute/unmute
- Camera on/off
- Screen-share publication
- Data channel delivery for chat
- Participant join/leave events
- Reconnection and resubscription

The application UI observes and reacts to these events, but it does not implement its own media routing logic.

---

## 5. Tech Stack Justification

### 5.1 Why LiveKit

LiveKit is an appropriate media backbone for MeetSpace for three main reasons.

#### 1. SFU architecture instead of mesh

MeetSpace is a conferencing product, not a simple one-to-one call tool. An SFU is the correct architectural choice because it:

- Scales better for multi-party rooms
- Reduces client uplink pressure
- Supports adaptive subscriptions and simulcast/dynacast patterns
- Preserves acceptable performance on mobile and weaker networks

#### 2. Cross-platform SDK parity

MeetSpace has both web and Flutter clients. LiveKit provides strong SDK coverage across:

- Browser / React
- Flutter / Dart
- Server-side token and egress APIs

That parity reduces architectural drift across platforms and allows both clients to use the same room model, permission model, and media semantics.

#### 3. Product-level capabilities out of the box

LiveKit supports:

- Real-time audio and video
- Screen sharing
- Data messaging for chat
- Reconnection handling
- Recording / egress workflows

This accelerates delivery versus building a custom WebRTC control plane.

### 5.2 Why Cubit / BLoC on Mobile

Cubit/BLoC is a good fit for the Flutter application because MeetSpace has a stateful meeting lifecycle:

- Idle
- Validating
- Connecting
- Connected
- Failure
- Ended

Cubit/BLoC provides:

- Predictable, explicit state transitions
- Clear separation between UI widgets and business logic
- Better testability for room join/connect/disconnect flows
- Easier handling of asynchronous events such as permission failures and network errors

For an MTS-style or production-oriented codebase, this is more robust than pushing stateful logic directly into widgets.

### 5.3 Why Next.js and Vercel

Next.js and Vercel are used as the product’s **web delivery platform and lightweight backend layer**.

They are a strong fit because they provide:

- A single codebase for web UI and backend route handlers
- Tight colocation between pages and API endpoints
- Fast deployment and operational simplicity
- Globally distributed hosting suitable for low-latency token issuance

> **Implementation note:** The current API routes are explicitly configured with `runtime = "nodejs"`, not the Vercel Edge Runtime. Architecturally, Vercel still provides an efficient serverless control plane, and the platform retains the option to move latency-sensitive endpoints closer to the edge when SDK/runtime constraints allow it.

### 5.4 Why Firebase Firestore

Firestore is a pragmatic metadata store for a conferencing POC or MVP because it offers:

- Minimal operational overhead
- Real-time subscriptions for meeting metadata
- Straightforward document modeling for room state
- Good fit for sparse, room-scoped application data

It complements LiveKit well because it stores product metadata without interfering with the media path.

---

## 6. Trade-offs & Decisions

### 6.1 Cloud vs Self-Hosted Media Plane

**Decision:** Use **LiveKit Cloud** for the primary architecture.

#### Why this was chosen

- Faster proof-of-concept delivery and lower latency to a production-grade media plane
- No need to operate a globally distributed SFU fleet
- Lower operational complexity around TURN, regional placement, failover, and upgrades
- Better focus on product behavior instead of media infrastructure management

#### Trade-off

- Less infrastructure-level customization than a fully self-hosted deployment
- Ongoing vendor dependency and managed-service cost
- Reduced control over media node placement strategy compared with a bespoke global mesh

#### Practical note

The repository still includes Docker-based local infrastructure for development and testing, which is useful for local iteration. That does not change the production architecture choice.

### 6.2 State Management Decision on Mobile

**Decision:** Use **Cubit/BLoC** instead of `Provider`.

#### Why Cubit was selected

- Better fit for multi-step workflows such as create room, validate join, request token, connect, reconnect, and disconnect
- More explicit failure handling
- Cleaner separation between view rendering and orchestration logic
- Easier to scale as meeting features become more complex

#### Why not Provider for this use case

`Provider` is effective for simpler dependency injection and lightweight reactive state, but MeetSpace has enough asynchronous workflow complexity that a more opinionated state machine style is justified.

### 6.3 Reconnection Strategy

**Decision:** Rely on LiveKit’s built-in reconnection and **0-second resume / fast session-resume behavior** rather than implementing a custom reconnection protocol in the app layer.

#### Implications

- Temporary network drops are handled in the media layer.
- Clients can surface a reconnecting state in the UI while transport recovery happens.
- Application code remains focused on user messaging and room state observation instead of low-level WebRTC recovery.

In the current web implementation, reconnection is surfaced through connection-state messaging such as **“Connection dropped. Reconnecting...”**.

### 6.4 Camera and Microphone Permission Denials

**Decision:** Degrade gracefully rather than block the join flow.

#### Behavior

- If camera permission is denied, the user can still join with camera off.
- If microphone permission is denied, the user can still join muted.
- If both are denied, the user can still join as a listen-only / view-only participant if room policy allows.

This is the correct UX trade-off for conferencing because permission denial is often a local device issue, not a reason to deny room access entirely.

### 6.5 Meeting Validation Strategy

**Decision:** Treat Firestore as the source of truth for whether a meeting code is legitimate before minting a token.

#### Benefit

- Prevents arbitrary token issuance for nonexistent meeting codes
- Keeps product-level room lifecycle under MeetSpace control
- Decouples business validation from LiveKit transient room existence

#### Trade-off

- Adds one metadata dependency to the join path
- Requires Firestore availability for token issuance

---

## 7. Operational Considerations

### 7.1 Scalability

MeetSpace scales along three largely independent dimensions:

- **Web/API scale**
  - Handled by Vercel serverless scaling characteristics
- **Metadata scale**
  - Handled by Firestore document access and snapshot subscriptions
- **Media scale**
  - Handled by LiveKit Cloud’s SFU infrastructure

This separation is desirable because media scale and application API scale are not forced through the same runtime bottleneck.

### 7.2 Reliability

The architecture improves reliability by avoiding unnecessary coupling:

- Next.js APIs can fail without forcing already-connected media sessions to drop.
- Firestore can hold room metadata independently of participant presence.
- LiveKit remains the specialized system for media continuity and reconnection.

### 7.3 Security Posture

Key security characteristics include:

- LiveKit secrets remain server-side only.
- Access tokens are short-lived and room-scoped.
- Room access is gated by application-level meeting validation.
- Participant identity is server-generated rather than fully trusted from the client.

For production hardening, the next logical steps would be:

- Add user authentication for meeting creation and administrative actions
- Tighten Firestore security rules
- Add authorization checks for recording start/stop
- Audit token TTL and grant minimization by role

---

## 8. Implementation Mapping

The following files are the most important implementation anchors for this architecture.

| Concern                           | Primary Files                                                                                     |
| --------------------------------- | ------------------------------------------------------------------------------------------------- |
| Meeting creation / validation API | `dashboard/src/app/api/meetings/route.ts`                                                         |
| Participant token issuance        | `dashboard/src/app/api/get-participant-token/route.ts`                                            |
| Recording control                 | `dashboard/src/app/api/recording/start/route.ts`, `dashboard/src/app/api/recording/stop/route.ts` |
| Firestore meeting metadata        | `dashboard/src/lib/firebase/meetings.ts`                                                          |
| LiveKit server utilities          | `dashboard/src/lib/livekit/server.ts`                                                             |
| Web token acquisition             | `dashboard/src/hooks/useParticipantToken.ts`                                                      |
| Web meeting metadata subscription | `dashboard/src/hooks/useMeetingMetadata.ts`                                                       |
| Web room experience               | `dashboard/src/components/meeting/Room.tsx`                                                       |
| Flutter backend integration       | `app/lib/features/meeting/data/services/meeting_api_service.dart`                                 |
| Flutter LiveKit integration       | `app/lib/features/meeting/data/services/livekit_service.dart`                                     |
| Flutter meeting orchestration     | `app/lib/features/meeting/presentation/cubit/meeting_cubit.dart`                                  |
| Flutter permission handling       | `app/lib/core/services/permission_service.dart`                                                   |

---

## 9. Summary

MeetSpace is architected as a **cross-platform conferencing system with a shared control plane and a specialized media plane**:

- **Next.js on Vercel** provides the web client and backend route handlers.
- **Flutter** consumes the same backend contract for mobile.
- **Firebase Firestore** stores room metadata and recording state.
- **LiveKit Cloud** provides the SFU-based real-time media backbone.

This architecture is appropriate for an MVP or production-leaning collaboration platform because it balances:

- low operational overhead
- strong cross-platform consistency
- scalable media routing
- clean separation between metadata, authorization, and transport

The result is a system that is easier to reason about, easier to extend, and materially more scalable than a peer-to-peer conferencing design.
