"use client";

import {
  ParticipantTile,
  VideoTrack,
  isTrackReference,
  useTracks,
} from "@livekit/components-react";
import { LayoutGrid } from "lucide-react";
import { Track } from "livekit-client";

function SingleStageTile({
  track,
  highlighted = false,
}: {
  track: ReturnType<typeof useTracks>[number];
  highlighted?: boolean;
}) {
  if (!isTrackReference(track)) {
    return null;
  }

  const participantLabel =
    track.participant.name || track.participant.identity || "Participant";
  const isScreenShare = track.publication?.source === Track.Source.ScreenShare;

  return (
    <div
      className={`stage-single-tile relative h-full overflow-hidden rounded-[1.4rem] border bg-slate-950 ${
        highlighted ? "border-sky-400/20" : "border-white/10"
      }`}
    >
      <VideoTrack
        trackRef={track}
        className="h-full w-full bg-slate-950 object-contain"
      />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950 via-slate-950/70 to-transparent px-4 pb-4 pt-10">
        <div className="flex items-center justify-between gap-3 text-sm text-slate-100">
          <span className="truncate font-medium">{participantLabel}</span>
          {isScreenShare ? (
            <span className="rounded-full border border-sky-400/20 bg-sky-400/10 px-2.5 py-1 text-xs font-semibold text-sky-100">
              Presenting
            </span>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export function ParticipantGrid() {
  const tracks = useTracks(
    [Track.Source.Camera, Track.Source.ScreenShare],
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

  const screenShareTracks = tracks.filter(
    (track) => track.publication?.source === Track.Source.ScreenShare,
  );
  const hasActiveScreenShare = screenShareTracks.length > 0;
  const primaryTrack = hasActiveScreenShare ? screenShareTracks[0] : null;
  const secondaryTracks = primaryTrack
    ? tracks.filter(
        (track) => track.publication?.trackSid !== primaryTrack.publication.trackSid,
      )
    : tracks;

  if (!primaryTrack && secondaryTracks.length === 1) {
    const onlyTrack = secondaryTracks[0];

    return (
      <div className="h-full min-h-[18rem] overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
        <SingleStageTile track={onlyTrack} />
      </div>
    );
  }

  if (primaryTrack) {
    if (secondaryTracks.length === 0) {
      return (
        <div className="h-full min-h-[18rem] overflow-hidden rounded-[2rem] border border-sky-400/20 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
          <SingleStageTile track={primaryTrack} highlighted />
        </div>
      );
    }

    return (
      <div className="grid h-full min-h-[18rem] gap-3 sm:min-h-[24rem] lg:min-h-[28rem] lg:grid-cols-[minmax(0,1.6fr)_minmax(18rem,0.8fr)]">
        <div className="min-h-[18rem] overflow-hidden rounded-[2rem] border border-sky-400/20 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
          <ParticipantTile
            trackRef={primaryTrack}
            className="h-full overflow-hidden rounded-[1.4rem] border border-sky-400/20 bg-slate-900"
          />
        </div>

        <div className="grid min-h-[14rem] auto-rows-fr gap-3">
          {secondaryTracks.map((track) => (
            <ParticipantTile
              key={track.publication?.trackSid ?? `${track.participant.sid}-${track.source}`}
              trackRef={track}
              className="min-h-[10rem] overflow-hidden rounded-[1.4rem] border border-white/10 bg-slate-900"
            />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="h-full min-h-[18rem] overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/70 p-2 shadow-2xl shadow-slate-950/50 sm:min-h-[24rem] sm:p-3 lg:min-h-[28rem]">
      <div className="grid h-full auto-rows-fr gap-3 md:grid-cols-2 xl:grid-cols-3">
        {secondaryTracks.map((track) => (
          <ParticipantTile
            key={track.publication?.trackSid ?? `${track.participant.sid}-${track.source}`}
            trackRef={track}
            className="overflow-hidden rounded-[1.4rem] border border-white/10 bg-slate-900"
          />
        ))}
      </div>
    </div>
  );
}
