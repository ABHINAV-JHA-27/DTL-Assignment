import {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  type DocumentData,
} from "firebase/firestore";
import { getFirebaseDb } from "@/lib/firebase/client";

type MeetingRecord = {
  code: string;
  createdAt: ReturnType<typeof serverTimestamp>;
  createdBy: string;
  status: "active";
};

export async function createMeeting(code: string, createdBy: string) {
  const meetingRef = doc(getFirebaseDb(), "meetings", code);
  const payload: MeetingRecord = {
    code,
    createdAt: serverTimestamp(),
    createdBy,
    status: "active",
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
