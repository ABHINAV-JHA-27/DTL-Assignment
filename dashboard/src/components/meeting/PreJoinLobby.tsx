"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import type { LocalUserChoices } from "@livekit/components-react";
import {
  useMediaDevices,
  useMultibandTrackVolume,
  usePreviewTracks,
} from "@livekit/components-react";
import { Mic, MicOff, Video, VideoOff } from "lucide-react";
import { Track, type LocalAudioTrack, type LocalVideoTrack } from "livekit-client";
import { getDefaultUsername } from "@/lib/meeting-code";

const SAVED_NAME_KEY = "meetspace-display-name";

type PreJoinLobbyProps = {
  roomCode: string;
  initialUsername?: string;
  onSubmit: (choices: LocalUserChoices) => void;
};

function DeviceSelect({
  label,
  devices,
  value,
  disabled = false,
  onChange,
}: {
  label: string;
  devices: MediaDeviceInfo[];
  value: string;
  disabled?: boolean;
  onChange: (value: string) => void;
}) {
  return (
    <label className="block space-y-2">
      <span className="text-sm font-medium text-slate-300">{label}</span>
      <select
        value={value}
        disabled={disabled}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white outline-none transition focus:border-sky-400/60 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {devices.map((device) => (
          <option
            key={device.deviceId}
            value={device.deviceId}
            className="bg-slate-950 text-white"
          >
            {device.label || `${label} ${device.deviceId.slice(0, 4)}`}
          </option>
        ))}
      </select>
    </label>
  );
}

function MeterBar({ value }: { value: number }) {
  return (
    <div className="h-10 flex-1 overflow-hidden rounded-full bg-white/5">
      <div
        className="h-full rounded-full bg-gradient-to-r from-emerald-400 via-sky-400 to-cyan-300 transition-[width]"
        style={{ width: `${Math.max(6, Math.min(value * 100, 100))}%` }}
      />
    </div>
  );
}

export function PreJoinLobby({
  roomCode,
  initialUsername = "",
  onSubmit,
}: PreJoinLobbyProps) {
  const [username, setUsername] = useState(() => {
    if (initialUsername.trim()) {
      return initialUsername.trim();
    }

    if (typeof window === "undefined") {
      return "";
    }

    return window.localStorage.getItem(SAVED_NAME_KEY) ?? getDefaultUsername();
  });
  const [audioEnabled, setAudioEnabled] = useState(true);
  const [videoEnabled, setVideoEnabled] = useState(true);
  const [audioDeviceId, setAudioDeviceId] = useState("default");
  const [videoDeviceId, setVideoDeviceId] = useState("default");
  const [error, setError] = useState<string | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const audioDevices = useMediaDevices({ kind: "audioinput" });
  const videoDevices = useMediaDevices({ kind: "videoinput" });
  const resolvedAudioDeviceId =
    audioDevices.some((device) => device.deviceId === audioDeviceId)
      ? audioDeviceId
      : (audioDevices[0]?.deviceId ?? "default");
  const resolvedVideoDeviceId =
    videoDevices.some((device) => device.deviceId === videoDeviceId)
      ? videoDeviceId
      : (videoDevices[0]?.deviceId ?? "default");
  const previewTracks = usePreviewTracks(
    {
      audio: audioEnabled ? { deviceId: resolvedAudioDeviceId } : false,
      video: videoEnabled ? { deviceId: resolvedVideoDeviceId } : false,
    },
    (previewError) => setError(previewError.message),
  );

  const audioTrack = useMemo(
    () =>
      previewTracks?.find(
        (track) => track.kind === Track.Kind.Audio,
      ) as LocalAudioTrack | undefined,
    [previewTracks],
  );
  const videoTrack = useMemo(
    () =>
      previewTracks?.find(
        (track) => track.kind === Track.Kind.Video,
      ) as LocalVideoTrack | undefined,
    [previewTracks],
  );
  const audioLevels = useMultibandTrackVolume(audioTrack, {
    bands: 12,
    updateInterval: 80,
  });

  useEffect(() => {
    if (!videoRef.current || !videoTrack) {
      return;
    }

    const element = videoRef.current;
    videoTrack.attach(element);

    return () => {
      videoTrack.detach(element);
    };
  }, [videoTrack]);

  const handleJoin = () => {
    const nextUsername = username.trim() || getDefaultUsername();
    window.localStorage.setItem(SAVED_NAME_KEY, nextUsername);
    onSubmit({
      username: nextUsername,
      audioEnabled,
      videoEnabled,
      audioDeviceId: resolvedAudioDeviceId,
      videoDeviceId: resolvedVideoDeviceId,
    });
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-6 sm:px-6">
      <div className="grid w-full max-w-6xl gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <section className="overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/75 p-4 shadow-2xl shadow-slate-950/50 backdrop-blur sm:p-6">
          <div className="overflow-hidden rounded-[1.7rem] border border-white/10 bg-slate-900">
            {videoEnabled && videoTrack ? (
              <video
                ref={videoRef}
                autoPlay
                playsInline
                muted
                className="aspect-video w-full bg-slate-950 object-cover"
              />
            ) : (
              <div className="flex aspect-video items-center justify-center bg-[radial-gradient(circle_at_top,rgba(56,189,248,0.18),transparent_55%)]">
                <div className="text-center">
                  <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-3xl border border-white/10 bg-white/5 text-sky-200">
                    <VideoOff className="h-8 w-8" />
                  </div>
                  <p className="mt-4 text-lg font-semibold text-white">
                    Camera preview is off
                  </p>
                  <p className="mt-2 text-sm text-slate-400">
                    Turn your camera on to verify framing before entering the room.
                  </p>
                </div>
              </div>
            )}
          </div>

          <div className="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={() => setAudioEnabled((current) => !current)}
              className={`flex min-h-12 items-center gap-2 rounded-2xl border px-4 py-3 text-sm font-semibold transition ${
                audioEnabled
                  ? "border-sky-400/40 bg-sky-500 text-slate-950"
                  : "border-white/10 bg-white/5 text-white"
              }`}
            >
              {audioEnabled ? (
                <Mic className="h-4 w-4" />
              ) : (
                <MicOff className="h-4 w-4" />
              )}
              {audioEnabled ? "Mic On" : "Mic Off"}
            </button>
            <button
              type="button"
              onClick={() => setVideoEnabled((current) => !current)}
              className={`flex min-h-12 items-center gap-2 rounded-2xl border px-4 py-3 text-sm font-semibold transition ${
                videoEnabled
                  ? "border-sky-400/40 bg-sky-500 text-slate-950"
                  : "border-white/10 bg-white/5 text-white"
              }`}
            >
              {videoEnabled ? (
                <Video className="h-4 w-4" />
              ) : (
                <VideoOff className="h-4 w-4" />
              )}
              {videoEnabled ? "Camera On" : "Camera Off"}
            </button>
          </div>
        </section>

        <section className="rounded-[2rem] border border-white/10 bg-slate-950/75 p-5 shadow-2xl shadow-slate-950/50 backdrop-blur sm:p-6">
          <p className="text-sm uppercase tracking-[0.24em] text-slate-500">
            Pre-join lobby
          </p>
          <h1 className="mt-3 text-3xl font-semibold text-white">{roomCode}</h1>
          <p className="mt-3 text-sm leading-7 text-slate-300 sm:text-base">
            Pick your devices, verify your camera framing, and confirm your microphone
            is active before connecting to the room.
          </p>

          <div className="mt-6 space-y-4">
            <label className="block space-y-2">
              <span className="text-sm font-medium text-slate-300">Display name</span>
              <input
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                placeholder="Enter your display name"
                className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none transition focus:border-sky-400/60"
              />
            </label>

            <DeviceSelect
              label="Microphone"
              devices={audioDevices}
              value={resolvedAudioDeviceId}
              disabled={!audioEnabled || audioDevices.length === 0}
              onChange={setAudioDeviceId}
            />
            <DeviceSelect
              label="Camera"
              devices={videoDevices}
              value={resolvedVideoDeviceId}
              disabled={!videoEnabled || videoDevices.length === 0}
              onChange={setVideoDeviceId}
            />

            <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <p className="text-sm font-medium text-white">Microphone test</p>
                  <p className="text-xs text-slate-400">
                    Speak normally and verify the level bars respond.
                  </p>
                </div>
                <span className="rounded-full border border-emerald-400/20 bg-emerald-400/10 px-3 py-1 text-xs font-semibold text-emerald-200">
                  {audioEnabled ? "Listening" : "Muted"}
                </span>
              </div>
              <div className="mt-4 flex gap-1.5">
                {audioLevels.length > 0
                  ? audioLevels.map((level, index) => (
                      <MeterBar key={`${index}-${level}`} value={level} />
                    ))
                  : Array.from({ length: 12 }).map((_, index) => (
                      <MeterBar key={`empty-${index}`} value={0.04} />
                    ))}
              </div>
            </div>

            {error ? (
              <div className="rounded-2xl border border-amber-400/20 bg-amber-400/10 px-4 py-3 text-sm text-amber-100">
                {error}
              </div>
            ) : null}

            <button
              type="button"
              onClick={handleJoin}
              className="w-full rounded-2xl bg-sky-500 px-4 py-3 font-semibold text-slate-950 transition hover:bg-sky-400"
            >
              Join Meeting
            </button>
          </div>
        </section>
      </div>
    </div>
  );
}
