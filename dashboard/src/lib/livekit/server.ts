import {
  EncodedFileOutput,
  EgressClient,
  S3Upload,
} from "livekit-server-sdk";

function normalizeServerUrl(url: string) {
  if (url.startsWith("wss://")) {
    return url.replace("wss://", "https://");
  }

  if (url.startsWith("ws://")) {
    return url.replace("ws://", "http://");
  }

  return url;
}

function getRequiredEnv(name: string) {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

export function getLiveKitApiUrl() {
  const explicitUrl = process.env.LIVEKIT_SERVER_URL;

  if (explicitUrl) {
    return explicitUrl;
  }

  const publicUrl = process.env.NEXT_PUBLIC_LIVEKIT_URL;

  if (!publicUrl) {
    throw new Error(
      "Missing LiveKit server URL. Set LIVEKIT_SERVER_URL or NEXT_PUBLIC_LIVEKIT_URL.",
    );
  }

  return normalizeServerUrl(publicUrl);
}

export function createEgressClient() {
  return new EgressClient(
    getLiveKitApiUrl(),
    getRequiredEnv("LIVEKIT_API_KEY"),
    getRequiredEnv("LIVEKIT_API_SECRET"),
  );
}

export function createRecordingOutput(roomCode: string) {
  const accessKey = getRequiredEnv("RECORDING_S3_ACCESS_KEY");
  const secret = getRequiredEnv("RECORDING_S3_SECRET_KEY");
  const region = process.env.RECORDING_S3_REGION ?? "us-east-1";
  const endpoint = process.env.RECORDING_S3_ENDPOINT ?? "";
  const bucket = getRequiredEnv("RECORDING_S3_BUCKET");
  const forcePathStyle = process.env.RECORDING_S3_FORCE_PATH_STYLE === "true";

  return new EncodedFileOutput({
    filepath: `recordings/${roomCode}/${Date.now()}.mp4`,
    output: {
      case: "s3",
      value: new S3Upload({
        accessKey,
        secret,
        region,
        endpoint,
        bucket,
        forcePathStyle,
      }),
    },
  });
}
