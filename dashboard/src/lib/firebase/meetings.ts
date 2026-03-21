import {
  doc,
  getDoc,
  onSnapshot,
  serverTimestamp,
  setDoc,
  updateDoc,
  type DocumentData,
  type Unsubscribe,
} from "firebase/firestore";
import { getFirebaseDb } from "@/lib/firebase/client";

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

export async function createMeeting(code: string, createdBy: string) {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);
  const payload: MeetingRecord = {
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

  await setDoc(meetingRef, payload);
  return payload;
}

export async function getMeeting(code: string) {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);
  const snapshot = await getDoc(meetingRef);

  if (!snapshot.exists()) {
    return null;
  }

  return snapshot.data() as DocumentData;
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
