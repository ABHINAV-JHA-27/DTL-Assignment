"use client";

import { useState } from "react";
import { Check, Copy, Users } from "lucide-react";
import { useParticipants } from "@livekit/components-react";

type SidebarProps = {
  roomCode: string;
};

export function Sidebar({ roomCode }: SidebarProps) {
  const participants = useParticipants();
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(roomCode);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1500);
  };

  return (
    <aside className="flex w-full shrink-0 flex-col border-t border-white/10 bg-slate-950/85 lg:w-[22rem] lg:border-t-0 lg:border-l">
      <div className="border-b border-white/10 px-5 py-5">
        <p className="text-sm uppercase tracking-[0.24em] text-slate-500">
          Meeting details
        </p>
        <div className="mt-4 rounded-3xl border border-white/10 bg-white/5 p-4">
          <p className="text-sm text-slate-400">Meeting code</p>
          <div className="mt-2 flex items-center justify-between gap-3">
            <p className="font-mono text-xl tracking-[0.3em] text-white">
              {roomCode}
            </p>
            <button
              type="button"
              onClick={() => void handleCopy()}
              className="flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-2 text-sm text-slate-200 transition hover:border-sky-400/30 hover:bg-white/10"
            >
              {copied ? (
                <Check className="h-4 w-4 text-emerald-300" />
              ) : (
                <Copy className="h-4 w-4" />
              )}
              {copied ? "Copied" : "Copy"}
            </button>
          </div>
        </div>
      </div>

      <div className="flex min-h-0 flex-1 flex-col px-5 py-5">
        <div className="flex items-center gap-2">
          <Users className="h-4 w-4 text-sky-200" />
          <h2 className="text-base font-semibold text-white">
            Participants ({participants.length})
          </h2>
        </div>

        <div className="mt-4 flex-1 space-y-3 overflow-y-auto pr-1">
          {participants.map((participant) => (
            <div
              key={participant.sid}
              className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3"
            >
              <div className="flex items-center justify-between gap-3">
                <div>
                  <p className="font-medium text-white">
                    {participant.name || participant.identity}
                  </p>
                  <p className="text-sm text-slate-400">
                    {participant.isLocal ? "You" : "Connected"}
                  </p>
                </div>
                <span className="rounded-full border border-emerald-400/20 bg-emerald-400/10 px-2.5 py-1 text-xs font-semibold text-emerald-200">
                  Active
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </aside>
  );
}
