"use client";

import { useState } from "react";

type UseRecordingOptions = {
  roomCode: string;
  username: string;
  isRecording: boolean;
  egressId: string | null;
};

type RecordingResponse = {
  egressId?: string;
  status?: string;
  error?: string;
};

export function useRecording({
  roomCode,
  username,
  isRecording,
  egressId,
}: UseRecordingOptions) {
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const toggleRecording = async () => {
    setIsPending(true);
    setError(null);

    try {
      const endpoint = isRecording
        ? "/api/recording/stop"
        : "/api/recording/start";
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          room: roomCode,
          requestedBy: username,
          egressId,
        }),
      });
      const data = (await response.json()) as RecordingResponse;

      if (!response.ok) {
        throw new Error(data.error ?? "Unable to update recording state.");
      }
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Unable to update recording state.",
      );
    } finally {
      setIsPending(false);
    }
  };

  return {
    isPending,
    error,
    toggleRecording,
  };
}
