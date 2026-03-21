"use client";

import { useState } from "react";
import { Check, Copy, MessageSquareText, Settings2, Users, X } from "lucide-react";
import { Chat, useParticipants } from "@livekit/components-react";
import { AudioSettingsPanel } from "@/components/meeting/AudioSettingsPanel";
import type { MeetingSidebarPanel } from "@/components/meeting/MeetingControls";
import type { MeetingRecord } from "@/lib/firebase/meetings";

type SidebarProps = {
  roomCode: string;
  panel: MeetingSidebarPanel;
  isOpen: boolean;
  onClose: () => void;
  onSelectPanel: (panel: Exclude<MeetingSidebarPanel, null>) => void;
  meeting: MeetingRecord | null;
};

function PanelTab({
  isActive,
  icon,
  label,
  onClick,
}: {
  isActive: boolean;
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center gap-2 rounded-full px-3 py-2 text-sm font-semibold transition ${
        isActive
          ? "bg-sky-500 text-slate-950"
          : "border border-white/10 bg-white/5 text-slate-200"
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

export function Sidebar({
  roomCode,
  panel,
  isOpen,
  onClose,
  onSelectPanel,
  meeting,
}: SidebarProps) {
  const participants = useParticipants();
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(roomCode);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1500);
  };

  if (!panel) {
    return null;
  }

  return (
    <div
      className={`fixed inset-0 z-40 bg-slate-950/45 backdrop-blur-sm transition ${
        isOpen ? "pointer-events-auto opacity-100" : "pointer-events-none opacity-0"
      }`}
      onClick={onClose}
    >
      <aside
        className={`absolute inset-y-0 right-0 flex w-[min(92vw,24rem)] flex-col border-l border-white/10 bg-slate-950/95 shadow-2xl shadow-slate-950/80 transition duration-200 ${
          isOpen ? "translate-x-0" : "translate-x-full"
        }`}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="border-b border-white/10 px-5 py-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm uppercase tracking-[0.24em] text-slate-500">
                Collaboration panel
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                <PanelTab
                  isActive={panel === "people"}
                  icon={<Users className="h-4 w-4" />}
                  label="People"
                  onClick={() => onSelectPanel("people")}
                />
                <PanelTab
                  isActive={panel === "chat"}
                  icon={<MessageSquareText className="h-4 w-4" />}
                  label="Chat"
                  onClick={() => onSelectPanel("chat")}
                />
                <PanelTab
                  isActive={panel === "settings"}
                  icon={<Settings2 className="h-4 w-4" />}
                  label="Settings"
                  onClick={() => onSelectPanel("settings")}
                />
              </div>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="flex h-10 w-10 items-center justify-center rounded-full border border-white/10 bg-white/5 text-slate-200 transition hover:bg-white/10"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>

        <div className="border-b border-white/10 px-5 py-5">
        <p className="text-sm uppercase tracking-[0.24em] text-slate-500">
          Meeting details
        </p>
        <div className="mt-4 rounded-3xl border border-white/10 bg-white/5 p-4">
          <p className="text-sm text-slate-400">Meeting code</p>
          <div className="mt-2 flex flex-col items-start gap-3 sm:flex-row sm:items-center sm:justify-between">
            <p className="max-w-full break-all font-mono text-lg tracking-[0.22em] text-white sm:text-xl sm:tracking-[0.3em]">
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
          {meeting?.recording?.isRecording ? (
            <div className="mt-4 flex items-center gap-2 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
              <span className="h-2.5 w-2.5 rounded-full bg-rose-400" />
              Recording in progress
            </div>
          ) : null}
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-5">
          {panel === "people" ? (
            <>
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4 text-sky-200" />
                <h2 className="text-base font-semibold text-white">
                  Participants ({participants.length})
                </h2>
              </div>

              <div className="mt-4 space-y-3 pr-1">
                {participants.map((participant) => (
                  <div
                    key={participant.sid}
                    className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3"
                  >
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                      <div className="min-w-0">
                        <p className="truncate font-medium text-white">
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
            </>
          ) : null}

          {panel === "chat" ? (
            <div className="h-full min-h-[20rem]">
              <Chat />
            </div>
          ) : null}

          {panel === "settings" ? (
            <div>
              <div className="mb-4">
                <h2 className="text-base font-semibold text-white">Audio settings</h2>
                <p className="text-sm text-slate-400">
                  Device health and enhancement controls for your local input.
                </p>
                  </div>
              <AudioSettingsPanel />
            </div>
          ) : null}
        </div>
      </aside>
    </div>
  );
}
