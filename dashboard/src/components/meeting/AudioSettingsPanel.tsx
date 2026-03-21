"use client";

import { AudioLines, LoaderCircle, Mic } from "lucide-react";
import { useLocalParticipant } from "@livekit/components-react";
import { useKrispNoiseFilter } from "@livekit/components-react/krisp";

export function AudioSettingsPanel() {
  const { isMicrophoneEnabled } = useLocalParticipant();
  const {
    isNoiseFilterEnabled,
    isNoiseFilterPending,
    setNoiseFilterEnabled,
  } = useKrispNoiseFilter();

  return (
    <div className="space-y-4">
      <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/5 text-sky-200">
              <AudioLines className="h-5 w-5" />
            </div>
            <div>
              <p className="font-medium text-white">Noise cancellation</p>
              <p className="text-sm text-slate-400">
                Krisp-enhanced suppression for local microphone noise.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => void setNoiseFilterEnabled(!isNoiseFilterEnabled)}
            disabled={isNoiseFilterPending || !isMicrophoneEnabled}
            className={`rounded-full px-4 py-2 text-sm font-semibold transition ${
              isNoiseFilterEnabled
                ? "bg-emerald-400 text-slate-950"
                : "border border-white/10 bg-white/5 text-white"
            } disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {isNoiseFilterEnabled ? "Enabled" : "Enable"}
          </button>
        </div>
        <div className="mt-4 flex items-center gap-2 text-sm text-slate-300">
          {isNoiseFilterPending ? (
            <>
              <LoaderCircle className="h-4 w-4 animate-spin text-sky-300" />
              Processing filter state...
            </>
          ) : (
            <>
              <Mic className="h-4 w-4 text-sky-300" />
              {isNoiseFilterEnabled
                ? "Krisp is active on your microphone input."
                : "Krisp is off. This feature requires LiveKit Cloud support."}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
