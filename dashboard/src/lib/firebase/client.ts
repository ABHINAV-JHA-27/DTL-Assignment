import {
  FirebaseError,
  getApp,
  getApps,
  initializeApp,
} from "firebase/app";
import {
  getFirestore,
  initializeFirestore,
  type Firestore,
} from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

let db: Firestore | null = null;

export function getFirebaseDb() {
  const missingFirebaseEnvVars = Object.entries(firebaseConfig)
    .filter(([, value]) => !value)
    .map(([key]) => key);

  if (missingFirebaseEnvVars.length > 0) {
    throw new Error(
      `Missing Firebase environment variables: ${missingFirebaseEnvVars.join(", ")}`,
    );
  }

  if (db) {
    return db;
  }

  const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);

  if (typeof window === "undefined") {
    db = getFirestore(app);
    return db;
  }

  try {
    db = initializeFirestore(app, {
      experimentalAutoDetectLongPolling: true,
    });
  } catch (error) {
    if (
      error instanceof FirebaseError &&
      error.code === "failed-precondition"
    ) {
      db = getFirestore(app);
      return db;
    }

    throw error;
  }

  return db;
}
