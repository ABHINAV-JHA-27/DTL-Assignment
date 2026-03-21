"use client";

import { useEffect, useState } from "react";
import {
  getMeeting,
  subscribeToMeeting,
  type MeetingRecord,
} from "@/lib/firebase/meetings";

type UseMeetingMetadataResult = {
  meeting: MeetingRecord | null;
  isLoading: boolean;
  error: string | null;
};

export function useMeetingMetadata(roomCode: string): UseMeetingMetadataResult {
  const [meeting, setMeeting] = useState<MeetingRecord | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    async function loadInitialMeeting() {
      try {
        const initialMeeting = await getMeeting(roomCode);

        if (!isMounted) {
          return;
        }

        setMeeting(initialMeeting as MeetingRecord | null);
      } catch (requestError) {
        if (!isMounted) {
          return;
        }

        setError(
          requestError instanceof Error
            ? requestError.message
            : "Unable to load meeting metadata.",
        );
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    }

    void loadInitialMeeting();

    const unsubscribe = subscribeToMeeting(
      roomCode,
      (nextMeeting) => {
        if (!isMounted) {
          return;
        }

        setMeeting(nextMeeting);
        setIsLoading(false);
      },
      (subscriptionError) => {
        if (!isMounted) {
          return;
        }

        setError(subscriptionError.message);
        setIsLoading(false);
      },
    );

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, [roomCode]);

  return { meeting, isLoading, error };
}
