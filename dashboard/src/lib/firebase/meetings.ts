import {
  doc,
  getDoc,
  onSnapshot,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  type Unsubscribe,
} from "firebase/firestore";
import { getFirebaseDb } from "@/lib/firebase/client";
import { generateMeetingCode } from "@/lib/meeting-code";

export type MeetingRecordingState = {
  isRecording: boolean;
  egressId: string | null;
  startedAt: unknown;
  startedBy: string | null;
};

export type MeetingRecord = {
  code: string;
  createdAt: unknown;
  createdBy: string;
  status: "active";
  recording: MeetingRecordingState;
};

function buildMeetingRecord(code: string, createdBy: string): MeetingRecord {
  return {
    code,
    createdAt: serverTimestamp(),
    createdBy,
    status: "active",
    recording: {
      isRecording: false,
      egressId: null,
      startedAt: null,
      startedBy: null,
    },
  };
}

export async function createMeeting(code: string, createdBy: string) {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);
  const payload = buildMeetingRecord(code, createdBy);

  await setDoc(meetingRef, payload);
  return payload;
}

export async function createMeetingWithGeneratedCode(createdBy: string) {
  const db = getFirebaseDb();

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const code = generateMeetingCode();
    const meetingRef = doc(db, "meetings", code);
    const payload = buildMeetingRecord(code, createdBy);

    const created = await runTransaction(db, async (transaction) => {
      const snapshot = await transaction.get(meetingRef);

      if (snapshot.exists()) {
        return null;
      }

      transaction.set(meetingRef, payload);
      return payload;
    });

    if (created) {
      return created;
    }
  }

  throw new Error("Unable to reserve a meeting code. Please try again.");
}

export async function getMeeting(code: string): Promise<MeetingRecord | null> {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);
  const snapshot = await getDoc(meetingRef);

  if (!snapshot.exists()) {
    return null;
  }

  return snapshot.data() as MeetingRecord;
}

export async function meetingExists(code: string) {
  const meeting = await getMeeting(code);
  return Boolean(meeting);
}

export function subscribeToMeeting(
  code: string,
  onData: (meeting: MeetingRecord | null) => void,
  onError?: (error: Error) => void,
): Unsubscribe {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);

  return onSnapshot(
    meetingRef,
    (snapshot) => {
      if (!snapshot.exists()) {
        onData(null);
        return;
      }

      onData(snapshot.data() as MeetingRecord);
    },
    (error) => {
      onError?.(error);
    },
  );
}

export async function updateMeetingRecordingState(
  code: string,
  recording: {
    isRecording: boolean;
    egressId?: string | null;
    startedBy?: string | null;
  },
) {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);

  await updateDoc(meetingRef, {
    recording: {
      isRecording: recording.isRecording,
      egressId: recording.egressId ?? null,
      startedAt: recording.isRecording ? serverTimestamp() : null,
      startedBy: recording.isRecording ? recording.startedBy ?? null : null,
    },
  });
}
