"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  LiveKitRoom,
  RoomAudioRenderer,
  useConnectionState,
} from "@livekit/components-react";
import {
  AlertTriangle,
  LoaderCircle,
  ShieldAlert,
  Video,
} from "lucide-react";
import { ConnectionState, MediaDeviceFailure } from "livekit-client";
import { MeetingControls } from "@/components/meeting/MeetingControls";
import { ParticipantGrid } from "@/components/meeting/ParticipantGrid";
import { Sidebar } from "@/components/meeting/Sidebar";
import { getDefaultUsername } from "@/lib/meeting-code";

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

function MeetingNameGate({
  roomCode,
  onContinue,
}: {
  roomCode: string;
  onContinue: (value: string) => void;
}) {
  const [name, setName] = useState(() => {
    if (typeof window === "undefined") {
      return getDefaultUsername();
    }

    return window.localStorage.getItem("meetspace-display-name") ?? getDefaultUsername();
  });

  const handleContinue = () => {
    const value = name.trim() || getDefaultUsername();
    window.localStorage.setItem("meetspace-display-name", value);
    onContinue(value);
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-6">
      <div className="w-full max-w-lg rounded-[2rem] border border-white/10 bg-slate-950/80 p-8 shadow-2xl shadow-slate-950/60 backdrop-blur">
        <div className="flex h-16 w-16 items-center justify-center rounded-3xl bg-sky-500/10 text-sky-200">
          <Video className="h-7 w-7" />
        </div>
        <p className="mt-6 text-sm uppercase tracking-[0.24em] text-slate-400">
          Meeting room
        </p>
        <h1 className="mt-2 text-3xl font-semibold text-white">{roomCode}</h1>
        <p className="mt-3 text-slate-300">
          Add a display name before joining the room.
        </p>
        <label className="mt-6 block space-y-2">
          <span className="text-sm font-medium text-slate-300">Your name</span>
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder="Add your display name"
            className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none transition focus:border-sky-400/60 focus:bg-white/8"
          />
        </label>
        <button
          type="button"
          onClick={handleContinue}
          className="mt-6 w-full rounded-2xl bg-sky-500 px-4 py-3 font-semibold text-slate-950 transition hover:bg-sky-400"
        >
          Join meeting
        </button>
      </div>
    </div>
  );
}

export function Room({ roomCode, initialUsername = "" }: RoomProps) {
  const router = useRouter();
  const [username, setUsername] = useState(() => {
    const normalizedInitialUsername = initialUsername.trim();

    if (normalizedInitialUsername) {
      return normalizedInitialUsername;
    }

    if (typeof window === "undefined") {
      return "";
    }

    return window.localStorage.getItem("meetspace-display-name") ?? "";
  });
  const [token, setToken] = useState<string | null>(null);
  const [serverUrl, setServerUrl] = useState(process.env.NEXT_PUBLIC_LIVEKIT_URL ?? "");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [permissionDenied, setPermissionDenied] = useState(false);

  useEffect(() => {
    if (!username) {
      return;
    }

    let isCancelled = false;
    const controller = new AbortController();

    const loadToken = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const params = new URLSearchParams({
          room: roomCode,
          username,
        });
        const response = await fetch(
          `/api/get-participant-token?${params.toString()}`,
          {
            cache: "no-store",
            signal: controller.signal,
          },
        );
        const data = (await response.json()) as
          | { token?: string; serverUrl?: string; error?: string }
          | undefined;

        if (!response.ok) {
          throw new Error(data?.error ?? "Unable to create a participant token.");
        }

        if (!data?.token || !data.serverUrl) {
          throw new Error("LiveKit token response was incomplete.");
        }

        if (!isCancelled) {
          setToken(data.token);
          setServerUrl(data.serverUrl);
        }
      } catch (requestError) {
        if (controller.signal.aborted || isCancelled) {
          return;
        }

        setError(
          requestError instanceof Error
            ? requestError.message
            : "Unable to connect to the room.",
        );
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    };

    void loadToken();

    return () => {
      isCancelled = true;
      controller.abort();
    };
  }, [roomCode, username]);

  if (!username) {
    return <MeetingNameGate roomCode={roomCode} onContinue={setUsername} />;
  }

  if (isLoading || !token || !serverUrl) {
    if (error) {
      return (
        <StatePanel
          icon={<AlertTriangle className="h-7 w-7" />}
          title="Unable to join meeting"
          description={error}
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
      connect
      audio
      video
      onDisconnected={() => router.push("/")}
      onMediaDeviceFailure={(failure) => {
        if (failure === MediaDeviceFailure.PermissionDenied) {
          setPermissionDenied(true);
          return;
        }

        setError("We couldn't access your media devices.");
      }}
      className="h-screen bg-transparent text-white"
      data-lk-theme="default"
    >
      <RoomAudioRenderer />

      <div className="flex h-full flex-col lg:flex-row">
        <div className="flex min-h-0 flex-1 flex-col">
          <div className="border-b border-white/10 bg-slate-950/80 px-4 py-4 backdrop-blur lg:px-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-sm uppercase tracking-[0.24em] text-slate-500">
                  Live room
                </p>
                <h1 className="text-2xl font-semibold text-white">{roomCode}</h1>
              </div>
              <div className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-slate-300">
                Joined as {username}
              </div>
            </div>
          </div>

          <ConnectionBanner />

          <div className="min-h-0 flex-1 p-4 lg:p-6">
            <ParticipantGrid />
          </div>

          <MeetingControls />
        </div>

        <Sidebar roomCode={roomCode} />
      </div>
    </LiveKitRoom>
  );
}
