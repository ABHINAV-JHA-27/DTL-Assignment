"use client";

import {
  VideoTrack,
  isTrackReference,
  useTracks,
} from "@livekit/components-react";
import { LayoutGrid, UserRound, VideoOff } from "lucide-react";
import { Track } from "livekit-client";

function TrackTile({
  track,
  highlighted = false,
  fit = "cover",
  className = "",
}: {
  track: ReturnType<typeof useTracks>[number];
  highlighted?: boolean;
  fit?: "contain" | "cover";
  className?: string;
}) {
  const participantLabel =
    track.participant.name || track.participant.identity || "Participant";
  const initials = participantLabel
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("") || "P";
  const isPlaceholder = !isTrackReference(track);
  const isScreenShare = track.source === Track.Source.ScreenShare;

  return (
    <div
      className={`relative overflow-hidden rounded-[1.4rem] border bg-slate-950 ${
        highlighted ? "border-sky-400/20" : "border-white/10"
      } ${className}`}
    >
      {isPlaceholder ? (
        <div className="flex h-full w-full flex-col items-center justify-center bg-[radial-gradient(circle_at_top,_rgba(56,189,248,0.16),_transparent_35%),linear-gradient(180deg,_rgba(15,23,42,0.98),_rgba(2,6,23,1))] px-6 text-center">
          <div className="flex h-20 w-20 items-center justify-center rounded-full border border-white/10 bg-white/5 text-white shadow-lg shadow-slate-950/40">
            {initials.length <= 2 ? (
              <span className="text-2xl font-semibold tracking-[0.14em]">
                {initials}
              </span>
            ) : (
              <UserRound className="h-9 w-9" />
            )}
          </div>
          <div className="mt-5 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-sm text-slate-200">
            <VideoOff className="h-4 w-4 text-slate-400" />
            Camera off
          </div>
        </div>
      ) : (
        <VideoTrack
          trackRef={track}
          className={`h-full w-full bg-slate-950 ${
            fit === "contain" ? "object-contain" : "object-cover"
          }`}
        />
      )}
      <div className="pointer-events-none absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950 via-slate-950/70 to-transparent px-4 pb-4 pt-10">
        <div className="flex items-center justify-between gap-3 text-sm text-slate-100">
          <span className="truncate font-medium">{participantLabel}</span>
          {isScreenShare ? (
            <span className="rounded-full border border-sky-400/20 bg-sky-400/10 px-2.5 py-1 text-xs font-semibold text-sky-100">
              Presenting
            </span>
          ) : isPlaceholder ? (
            <span className="rounded-full border border-white/10 bg-white/5 px-2.5 py-1 text-xs font-semibold text-slate-200">
              Placeholder
            </span>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export function ParticipantGrid() {
  const tracks = useTracks(
    [
      { source: Track.Source.Camera, withPlaceholder: true },
      { source: Track.Source.ScreenShare, withPlaceholder: false },
    ],
    { onlySubscribed: false },
  );

  if (tracks.length === 0) {
    return (
      <div className="flex h-full min-h-[18rem] items-center justify-center rounded-[2rem] border border-white/10 bg-slate-950/70 sm:min-h-[24rem] lg:min-h-[28rem]">
        <div className="px-4 text-center">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-white/5 text-sky-200">
            <LayoutGrid className="h-6 w-6" />
          </div>
          <p className="mt-4 text-lg font-semibold text-white">
            Waiting for video streams
          </p>
          <p className="mt-2 max-w-sm text-sm text-slate-400">
            Participant tiles appear here as cameras or screen shares become
            available.
          </p>
        </div>
      </div>
    );
  }

  const primaryTrack = tracks.find(
    (track) => isTrackReference(track) && track.source === Track.Source.ScreenShare,
  );
  const primaryTrackSid = isTrackReference(primaryTrack)
    ? primaryTrack.publication.trackSid
    : null;
  const secondaryTracks = primaryTrackSid
    ? tracks.filter(
        (track) =>
          !isTrackReference(track) ||
          track.publication.trackSid !== primaryTrackSid,
      )
    : tracks;

  if (!primaryTrack && secondaryTracks.length === 1) {
    const onlyTrack = secondaryTracks[0];

    return (
      <div className="h-full min-h-[18rem] overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
        <TrackTile track={onlyTrack} fit="contain" className="h-full" />
      </div>
    );
  }

  if (primaryTrack) {
    if (secondaryTracks.length === 0) {
      return (
        <div className="h-full min-h-[18rem] overflow-hidden rounded-[2rem] border border-sky-400/20 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
          <TrackTile
            track={primaryTrack}
            highlighted
            fit="contain"
            className="h-full"
          />
        </div>
      );
    }

    return (
      <div className="grid h-full min-h-[18rem] gap-3 sm:min-h-[24rem] lg:min-h-[28rem] lg:grid-cols-[minmax(0,1.6fr)_minmax(18rem,0.8fr)]">
        <div className="min-h-[18rem] overflow-hidden rounded-[2rem] border border-sky-400/20 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
          <TrackTile
            track={primaryTrack}
            highlighted
            fit="contain"
            className="h-full"
          />
        </div>

        <div className="grid content-start gap-3">
          {secondaryTracks.map((track) => (
            <TrackTile
              key={track.publication?.trackSid ?? `${track.participant.sid}-${track.source}`}
              track={track}
              className="aspect-video min-h-[12rem]"
            />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="h-full min-h-[18rem] overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
      <div className="grid content-start gap-3 md:grid-cols-2 xl:grid-cols-3">
        {secondaryTracks.map((track) => (
          <TrackTile
            key={track.publication?.trackSid ?? `${track.participant.sid}-${track.source}`}
            track={track}
            className="aspect-video min-h-[12rem]"
          />
        ))}
      </div>
    </div>
  );
}
