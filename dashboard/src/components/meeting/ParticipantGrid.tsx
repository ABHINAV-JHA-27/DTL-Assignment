"use client";

import {
  GridLayout,
  ParticipantTile,
  useTracks,
} from "@livekit/components-react";
import { LayoutGrid } from "lucide-react";
import { Track } from "livekit-client";

export function ParticipantGrid() {
  const tracks = useTracks(
    [Track.Source.Camera, Track.Source.ScreenShare],
    { onlySubscribed: false },
  );

  if (tracks.length === 0) {
    return (
      <div className="flex h-full min-h-[28rem] items-center justify-center rounded-[2rem] border border-white/10 bg-slate-950/70">
        <div className="text-center">
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

  return (
    <div className="h-full min-h-[28rem] overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/70 p-3 shadow-2xl shadow-slate-950/50">
      <GridLayout tracks={tracks} className="h-full gap-3">
        <ParticipantTile className="overflow-hidden rounded-[1.4rem] border border-white/10 bg-slate-900" />
      </GridLayout>
    </div>
  );
}
