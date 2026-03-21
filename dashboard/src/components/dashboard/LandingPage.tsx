"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { FirebaseError } from "firebase/app";
import {
  ArrowRight,
  CalendarClock,
  LoaderCircle,
  Plus,
  ShieldCheck,
  Video,
} from "lucide-react";
import { createMeeting, meetingExists } from "@/lib/firebase/meetings";
import {
  generateMeetingCode,
  getDefaultUsername,
  isMeetingCodeFormatValid,
  normalizeMeetingCode,
} from "@/lib/meeting-code";

const SAVED_NAME_KEY = "meetspace-display-name";

function getMeetingActionError(error: unknown, fallbackMessage: string) {
  if (error instanceof FirebaseError) {
    if (error.code === "permission-denied") {
      return "Firestore denied the request. Update your Firestore rules to allow meeting reads and writes for this app.";
    }

    if (error.code === "unavailable") {
      return "Firestore is unreachable from the browser. Check that Firestore is enabled for this Firebase project and try again with ad blockers or privacy shields disabled.";
    }
  }

  if (error instanceof Error) {
    if (error.message.includes("client is offline")) {
      return "Firestore could not be reached. Verify that Firestore is enabled for this project, then retry after disabling browser privacy blockers if needed.";
    }

    return error.message;
  }

  return fallbackMessage;
}

async function generateUniqueMeetingCode() {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const code = generateMeetingCode();

    if (!(await meetingExists(code))) {
      return code;
    }
  }

  throw new Error("Unable to reserve a meeting code. Please try again.");
}

export function LandingPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [meetingCode, setMeetingCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<"create" | "join" | null>(
    null,
  );

  useEffect(() => {
    const savedName = window.localStorage.getItem(SAVED_NAME_KEY);
    setUsername(savedName ?? getDefaultUsername());
  }, []);

  const persistName = (value: string) => {
    window.localStorage.setItem(SAVED_NAME_KEY, value);
  };

  const getUsername = () => {
    const value = username.trim() || getDefaultUsername();
    setUsername(value);
    persistName(value);
    return value;
  };

  const navigateToMeeting = (code: string) => {
    router.push(`/meet/${code}`);
  };

  const handleCreateMeeting = async () => {
    setPendingAction("create");
    setError(null);

    try {
      const name = getUsername();
      const code = await generateUniqueMeetingCode();
      await createMeeting(code, name);
      navigateToMeeting(code);
    } catch (requestError) {
      setError(
        getMeetingActionError(
          requestError,
          "Unable to create a meeting right now.",
        ),
      );
    } finally {
      setPendingAction(null);
    }
  };

  const handleJoinMeeting = async () => {
    setPendingAction("join");
    setError(null);

    try {
      const code = normalizeMeetingCode(meetingCode);

      if (!isMeetingCodeFormatValid(code)) {
        throw new Error("Enter a valid 9-character meeting code.");
      }

      const exists = await meetingExists(code);

      if (!exists) {
        throw new Error(
          "Meeting code not found. Check the code and try again.",
        );
      }

      getUsername();
      navigateToMeeting(code);
    } catch (requestError) {
      setError(
        getMeetingActionError(requestError, "Unable to join the meeting."),
      );
    } finally {
      setPendingAction(null);
    }
  };

  return (
    <main className="relative min-h-screen overflow-hidden text-slate-50">
      <div className="absolute inset-x-0 top-0 h-80 bg-[radial-gradient(circle_at_top,rgba(56,189,248,0.18),transparent_55%)]" />

      <div className="relative mx-auto flex min-h-screen w-full max-w-7xl flex-col px-6 py-10 lg:px-10">
        <header className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl border border-sky-400/30 bg-sky-400/10 text-sky-200">
              <Video className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm uppercase tracking-[0.24em] text-sky-200/70">
                MeetSpace
              </p>
              <h1 className="text-xl font-semibold text-white">
                Live collaboration dashboard
              </h1>
            </div>
          </div>

          <div className="hidden items-center gap-3 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-slate-300 md:flex">
            <ShieldCheck className="h-4 w-4 text-emerald-300" />
            Powered by Firebase + LiveKit
          </div>
        </header>

        <section className="grid flex-1 items-center gap-10 py-12 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="space-y-8">
            <div className="space-y-5">
              <p className="inline-flex items-center gap-2 rounded-full border border-sky-400/20 bg-sky-400/10 px-4 py-2 text-sm text-sky-100">
                <CalendarClock className="h-4 w-4" />
                Spin up a room in seconds and share the code instantly.
              </p>
              <div className="space-y-4">
                <h2 className="max-w-2xl text-4xl font-semibold tracking-tight text-white md:text-6xl">
                  Run secure video meetings with a clean control-room workflow.
                </h2>
                <p className="max-w-2xl text-lg leading-8 text-slate-300">
                  Create a room, validate join codes against Firebase, and drop
                  participants straight into a LiveKit-powered meeting shell.
                </p>
              </div>
            </div>
          </div>

          <div className="rounded-[2rem] border border-white/10 bg-slate-950/70 p-6 shadow-2xl shadow-sky-950/40 backdrop-blur xl:p-8">
            <div className="space-y-6">
              <div className="space-y-2">
                <p className="text-sm uppercase tracking-[0.24em] text-slate-400">
                  Launchpad
                </p>
                <h3 className="text-2xl font-semibold text-white">
                  Start or join a meeting
                </h3>
              </div>

              <label className="block space-y-2">
                <span className="text-sm font-medium text-slate-300">
                  Your name
                </span>
                <input
                  value={username}
                  onChange={(event) => setUsername(event.target.value)}
                  placeholder="Add your display name"
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none transition focus:border-sky-400/60 focus:bg-white/8"
                />
              </label>

              <button
                type="button"
                onClick={handleCreateMeeting}
                disabled={pendingAction !== null}
                className="flex w-full items-center justify-center gap-2 rounded-2xl bg-sky-500 px-4 py-3 font-semibold text-slate-950 transition hover:bg-sky-400 disabled:cursor-not-allowed disabled:bg-sky-500/60"
              >
                {pendingAction === "create" ? (
                  <LoaderCircle className="h-5 w-5 animate-spin" />
                ) : (
                  <Plus className="h-5 w-5" />
                )}
                Create Meeting
              </button>

              <div className="relative py-2 text-center text-sm text-slate-500">
                <span className="relative z-10 bg-slate-950 px-3">or</span>
                <div className="absolute inset-x-0 top-1/2 h-px -translate-y-1/2 bg-white/10" />
              </div>

              <label className="block space-y-2">
                <span className="text-sm font-medium text-slate-300">
                  Meeting code
                </span>
                <input
                  value={meetingCode}
                  onChange={(event) => setMeetingCode(event.target.value)}
                  placeholder="Enter 9-character code"
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 uppercase tracking-[0.3em] text-white outline-none transition focus:border-sky-400/60 focus:bg-white/8"
                />
              </label>

              <button
                type="button"
                onClick={handleJoinMeeting}
                disabled={pendingAction !== null}
                className="flex w-full items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 font-semibold text-white transition hover:border-sky-300/30 hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-70"
              >
                {pendingAction === "join" ? (
                  <LoaderCircle className="h-5 w-5 animate-spin" />
                ) : (
                  <ArrowRight className="h-5 w-5" />
                )}
                Join Meeting
              </button>

              {error ? (
                <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                  {error}
                </div>
              ) : null}
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
