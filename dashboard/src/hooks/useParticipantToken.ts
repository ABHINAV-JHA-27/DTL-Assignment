"use client";

import { useEffect, useState } from "react";

type ParticipantTokenResponse = {
  token?: string;
  serverUrl?: string;
  error?: string;
};

type UseParticipantTokenOptions = {
  roomCode: string;
  username: string;
  enabled: boolean;
};

type UseParticipantTokenResult = {
  token: string | null;
  serverUrl: string;
  isLoading: boolean;
  error: string | null;
};

export function useParticipantToken({
  roomCode,
  username,
  enabled,
}: UseParticipantTokenOptions): UseParticipantTokenResult {
  const [token, setToken] = useState<string | null>(null);
  const [serverUrl, setServerUrl] = useState(
    process.env.NEXT_PUBLIC_LIVEKIT_URL ?? "",
  );
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!enabled || !username) {
      setToken(null);
      setError(null);
      return;
    }

    let isCancelled = false;
    const controller = new AbortController();

    async function loadToken() {
      setIsLoading(true);
      setError(null);

      try {
        const params = new URLSearchParams({
          room: roomCode,
          username,
        });
        const response = await fetch(
          `/api/get-participant-token?${params.toString()}`,
          {
            cache: "no-store",
            signal: controller.signal,
          },
        );
        const data = (await response.json()) as ParticipantTokenResponse;

        if (!response.ok) {
          throw new Error(data.error ?? "Unable to create a participant token.");
        }

        if (!data.token || !data.serverUrl) {
          throw new Error("LiveKit token response was incomplete.");
        }

        if (!isCancelled) {
          setToken(data.token);
          setServerUrl(data.serverUrl);
        }
      } catch (requestError) {
        if (controller.signal.aborted || isCancelled) {
          return;
        }

        setError(
          requestError instanceof Error
            ? requestError.message
            : "Unable to connect to the room.",
        );
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    }

    void loadToken();

    return () => {
      isCancelled = true;
      controller.abort();
    };
  }, [enabled, roomCode, username]);

  return {
    token,
    serverUrl,
    isLoading,
    error,
  };
}
