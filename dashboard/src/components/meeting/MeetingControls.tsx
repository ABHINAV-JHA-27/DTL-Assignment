"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import {
  Mic,
  MicOff,
  MonitorUp,
  PhoneOff,
  Video,
  VideoOff,
} from "lucide-react";
import { useLocalParticipant, useRoomContext } from "@livekit/components-react";

type ControlButtonProps = {
  icon: React.ReactNode;
  label: string;
  onClick: () => Promise<void> | void;
  variant?: "default" | "danger";
  active?: boolean;
  disabled?: boolean;
};

function ControlButton({
  icon,
  label,
  onClick,
  variant = "default",
  active = false,
  disabled = false,
}: ControlButtonProps) {
  const baseStyles =
    "flex min-w-28 items-center justify-center gap-2 rounded-2xl border px-4 py-3 text-sm font-semibold transition";
  const activeStyles =
    variant === "danger"
      ? "border-rose-400/20 bg-rose-500 text-white hover:bg-rose-400"
      : active
        ? "border-sky-400/40 bg-sky-500 text-slate-950 hover:bg-sky-400"
        : "border-white/10 bg-white/5 text-white hover:border-white/20 hover:bg-white/10";

  return (
    <button
      type="button"
      onClick={() => void onClick()}
      disabled={disabled}
      className={`${baseStyles} ${activeStyles} disabled:cursor-not-allowed disabled:opacity-60`}
    >
      {icon}
      {label}
    </button>
  );
}

export function MeetingControls() {
  const router = useRouter();
  const room = useRoomContext();
  const {
    localParticipant,
    isMicrophoneEnabled,
    isCameraEnabled,
    isScreenShareEnabled,
  } = useLocalParticipant();
  const [isLeaving, setIsLeaving] = useState(false);
  const [isTogglingScreenShare, setIsTogglingScreenShare] = useState(false);
  const [screenShareError, setScreenShareError] = useState<string | null>(null);

  const toggleMicrophone = async () => {
    await localParticipant.setMicrophoneEnabled(!isMicrophoneEnabled);
  };

  const toggleCamera = async () => {
    await localParticipant.setCameraEnabled(!isCameraEnabled);
  };

  const toggleScreenShare = async () => {
    setScreenShareError(null);
    setIsTogglingScreenShare(true);

    try {
      await localParticipant.setScreenShareEnabled(!isScreenShareEnabled);
    } catch (error) {
      if (
        error instanceof DOMException &&
        (error.name === "NotAllowedError" || error.name === "AbortError")
      ) {
        setScreenShareError("Screen share was cancelled or blocked by the browser.");
        return;
      }

      setScreenShareError(
        error instanceof Error
          ? error.message
          : "Unable to start screen sharing on this device.",
      );
    } finally {
      setIsTogglingScreenShare(false);
    }
  };

  const leaveMeeting = async () => {
    try {
      setIsLeaving(true);
      await room.disconnect();
      router.push("/");
    } finally {
      setIsLeaving(false);
    }
  };

  return (
    <div className="border-t border-white/10 bg-slate-950/80 px-4 py-4 backdrop-blur lg:px-6">
      <div className="flex flex-wrap items-center justify-center gap-3">
        <ControlButton
          icon={
            isMicrophoneEnabled ? (
              <Mic className="h-4 w-4" />
            ) : (
              <MicOff className="h-4 w-4" />
            )
          }
          label={isMicrophoneEnabled ? "Mute Audio" : "Unmute Audio"}
          onClick={toggleMicrophone}
          active={isMicrophoneEnabled}
        />
        <ControlButton
          icon={
            isCameraEnabled ? (
              <Video className="h-4 w-4" />
            ) : (
              <VideoOff className="h-4 w-4" />
            )
          }
          label={isCameraEnabled ? "Stop Video" : "Start Video"}
          onClick={toggleCamera}
          active={isCameraEnabled}
        />
        <ControlButton
          icon={<MonitorUp className="h-4 w-4" />}
          label={
            isTogglingScreenShare
              ? "Starting Share..."
              : isScreenShareEnabled
                ? "Stop Sharing"
                : "Share Screen"
          }
          onClick={toggleScreenShare}
          active={isScreenShareEnabled}
          disabled={isTogglingScreenShare}
        />
        <ControlButton
          icon={<PhoneOff className="h-4 w-4" />}
          label={isLeaving ? "Leaving..." : "Leave Meeting"}
          onClick={leaveMeeting}
          variant="danger"
          disabled={isLeaving}
        />
      </div>

      {screenShareError ? (
        <div className="mx-auto mt-3 max-w-xl rounded-2xl border border-amber-400/20 bg-amber-400/10 px-4 py-3 text-center text-sm text-amber-100">
          {screenShareError}
        </div>
      ) : null}
    </div>
  );
}
