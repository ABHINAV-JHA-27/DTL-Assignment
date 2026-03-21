"use client";

import { useState } from "react";
import { useMemo } from "react";
import { useRouter } from "next/navigation";
import type { LocalUserChoices } from "@livekit/components-react";
import {
  LiveKitRoom,
  RoomAudioRenderer,
  useConnectionState,
} from "@livekit/components-react";
import {
  AlertTriangle,
  Check,
  Copy,
  LoaderCircle,
  Radio,
  ShieldAlert,
} from "lucide-react";
import { ConnectionState, MediaDeviceFailure } from "livekit-client";
import { MeetingControls } from "@/components/meeting/MeetingControls";
import { ParticipantGrid } from "@/components/meeting/ParticipantGrid";
import { PreJoinLobby } from "@/components/meeting/PreJoinLobby";
import { Sidebar } from "@/components/meeting/Sidebar";
import {
  type MeetingSidebarPanel,
} from "@/components/meeting/MeetingControls";
import { useMeetingMetadata } from "@/hooks/useMeetingMetadata";
import { useParticipantToken } from "@/hooks/useParticipantToken";
import { useRecording } from "@/hooks/useRecording";

type RoomProps = {
  roomCode: string;
  initialUsername?: string;
};

type StatePanelProps = {
  icon: React.ReactNode;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
};

function StatePanel({
  icon,
  title,
  description,
  actionLabel,
  onAction,
}: StatePanelProps) {
  return (
    <div className="flex min-h-screen items-center justify-center px-6 text-white">
      <div className="w-full max-w-lg rounded-[2rem] border border-white/10 bg-slate-950/80 p-8 text-center shadow-2xl shadow-slate-950/60 backdrop-blur">
        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-white/5 text-sky-200">
          {icon}
        </div>
        <h1 className="mt-6 text-2xl font-semibold">{title}</h1>
        <p className="mt-3 text-base leading-7 text-slate-300">{description}</p>
        {actionLabel && onAction ? (
          <button
            type="button"
            onClick={onAction}
            className="mt-6 rounded-2xl bg-sky-500 px-5 py-3 font-semibold text-slate-950 transition hover:bg-sky-400"
          >
            {actionLabel}
          </button>
        ) : null}
      </div>
    </div>
  );
}

function ConnectionBanner() {
  const connectionState = useConnectionState();

  const message = useMemo(() => {
    if (connectionState === ConnectionState.Connecting) {
      return "Connecting to the room...";
    }

    if (connectionState === ConnectionState.Reconnecting) {
      return "Connection dropped. Reconnecting...";
    }

    return null;
  }, [connectionState]);

  if (!message) {
    return null;
  }

  return (
    <div className="border-b border-amber-400/15 bg-amber-400/10 px-4 py-3 text-sm text-amber-100">
      {message}
    </div>
  );
}

type MeetingExperienceProps = {
  roomCode: string;
  username: string;
  meetingError: string | null;
  onToggleRecording: () => Promise<void> | void;
  isRecording: boolean;
  isRecordingPending: boolean;
  recordingError: string | null;
  meeting: ReturnType<typeof useMeetingMetadata>["meeting"];
};

function MeetingExperience({
  roomCode,
  username,
  meetingError,
  onToggleRecording,
  isRecording,
  isRecordingPending,
  recordingError,
  meeting,
}: MeetingExperienceProps) {
  const [activePanel, setActivePanel] = useState<MeetingSidebarPanel>(null);
  const [copied, setCopied] = useState(false);

  const handleTogglePanel = (panel: Exclude<MeetingSidebarPanel, null>) => {
    setActivePanel((current) => (current === panel ? null : panel));
  };

  const handleCopyRoomCode = async () => {
    await navigator.clipboard.writeText(roomCode);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1800);
  };

  return (
    <div className="relative min-h-screen lg:h-full lg:min-h-0">
      <div className="flex min-h-screen flex-col lg:h-full lg:min-h-0">
        <div className="border-b border-white/10 bg-slate-950/80 px-4 py-4 backdrop-blur lg:px-6">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="flex flex-wrap items-center gap-3">
                <p className="text-sm uppercase tracking-[0.24em] text-slate-500">
                  Live room
                </p>
                {isRecording ? (
                  <span className="inline-flex items-center gap-2 rounded-full border border-rose-400/20 bg-rose-400/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-rose-100">
                    <Radio className="h-3.5 w-3.5 fill-current text-rose-400" />
                    Rec
                  </span>
                ) : null}
              </div>
              <div className="mt-1 flex flex-wrap items-center gap-2">
                <h1 className="text-2xl font-semibold text-white">{roomCode}</h1>
                <button
                  type="button"
                  onClick={() => void handleCopyRoomCode()}
                  className="inline-flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-slate-300 transition hover:border-sky-400/40 hover:bg-sky-400/10 hover:text-sky-100"
                  aria-label={copied ? "Room code copied" : "Copy room code"}
                  title={copied ? "Copied" : "Copy room code"}
                >
                  {copied ? (
                    <Check className="h-4.5 w-4.5" />
                  ) : (
                    <Copy className="h-4.5 w-4.5" />
                  )}
                </button>
              </div>
            </div>
            <div className="max-w-full truncate rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-slate-300">
              Joined as {username}
            </div>
          </div>
          {meetingError ? (
            <div className="mt-3 rounded-2xl border border-amber-400/20 bg-amber-400/10 px-4 py-3 text-sm text-amber-100">
              {meetingError}
            </div>
          ) : null}
        </div>

        <ConnectionBanner />

        <div className="min-h-0 flex-1 p-3 sm:p-4 lg:p-6">
          <ParticipantGrid />
        </div>

        <MeetingControls
          activePanel={activePanel}
          onTogglePanel={handleTogglePanel}
          isRecording={isRecording}
          isRecordingPending={isRecordingPending}
          recordingError={recordingError}
          onToggleRecording={onToggleRecording}
        />
      </div>

      <Sidebar
        roomCode={roomCode}
        panel={activePanel}
        isOpen={activePanel !== null}
        onClose={() => setActivePanel(null)}
        onSelectPanel={setActivePanel}
        meeting={meeting}
      />
    </div>
  );
}

export function Room({ roomCode, initialUsername = "" }: RoomProps) {
  const router = useRouter();
  const [userChoices, setUserChoices] = useState<LocalUserChoices | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [permissionDenied, setPermissionDenied] = useState(false);
  const [fallbackUsername] = useState(() => {
    if (initialUsername.trim()) {
      return initialUsername.trim();
    }

    if (typeof window === "undefined") {
      return "";
    }

    return window.localStorage.getItem("meetspace-display-name") ?? "";
  });
  const { meeting, error: meetingError } = useMeetingMetadata(roomCode);
  const username = userChoices?.username || fallbackUsername;
  const {
    token,
    serverUrl,
    isLoading,
    error: tokenError,
  } = useParticipantToken({
    roomCode,
    username,
    enabled: Boolean(userChoices && username),
  });
  const { isPending: isRecordingPending, error: recordingError, toggleRecording } =
    useRecording({
      roomCode,
      username,
      isRecording: meeting?.recording?.isRecording ?? false,
      egressId: meeting?.recording?.egressId ?? null,
    });

  if (!userChoices) {
    return (
      <PreJoinLobby
        roomCode={roomCode}
        initialUsername={fallbackUsername}
        onSubmit={setUserChoices}
      />
    );
  }

  if (isLoading || !token || !serverUrl) {
    if (tokenError || error) {
      return (
        <StatePanel
          icon={<AlertTriangle className="h-7 w-7" />}
          title="Unable to join meeting"
          description={tokenError ?? error ?? "Unable to join meeting"}
          actionLabel="Back to dashboard"
          onAction={() => router.push("/")}
        />
      );
    }

    return (
      <StatePanel
        icon={<LoaderCircle className="h-7 w-7 animate-spin" />}
        title="Preparing your room"
        description="Requesting your participant token and setting up devices."
      />
    );
  }

  if (permissionDenied) {
    return (
      <StatePanel
        icon={<ShieldAlert className="h-7 w-7" />}
        title="Camera or microphone access denied"
        description="Allow browser access to your camera and microphone, then rejoin the meeting."
        actionLabel="Back to dashboard"
        onAction={() => router.push("/")}
      />
    );
  }

  return (
    <LiveKitRoom
      token={token}
      serverUrl={serverUrl}
      connect={Boolean(userChoices && token)}
      audio={
        userChoices.audioEnabled
          ? { deviceId: userChoices.audioDeviceId }
          : false
      }
      video={
        userChoices.videoEnabled
          ? { deviceId: userChoices.videoDeviceId }
          : false
      }
      onDisconnected={() => router.push("/")}
      onError={(roomError) => setError(roomError.message)}
      onMediaDeviceFailure={(failure) => {
        if (failure === MediaDeviceFailure.PermissionDenied) {
          setPermissionDenied(true);
          return;
        }

        setError("We couldn't access your media devices.");
      }}
      className="min-h-screen bg-transparent text-white lg:h-screen"
      data-lk-theme="default"
    >
      <RoomAudioRenderer />
      <MeetingExperience
        roomCode={roomCode}
        username={username}
        meetingError={meetingError}
        onToggleRecording={toggleRecording}
        isRecording={meeting?.recording?.isRecording ?? false}
        isRecordingPending={isRecordingPending}
        recordingError={recordingError}
        meeting={meeting}
      />
    </LiveKitRoom>
  );
}
